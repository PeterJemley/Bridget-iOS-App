import Foundation
import BridgetCore
import SwiftData
import SwiftUI

private struct DrawbridgeEventResponse: Codable {
    let entityid: String?
    let entityname: String?
    let entitytype: String?
    let opendatetime: String?
    let closedatetime: String?
    let latitude: String?
    let longitude: String?
    let minutesopen: String?
}

// Protocol abstraction for dependency injection
protocol NetworkSession {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSession {
    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await self.data(from: url, delegate: nil)
    }
}

@MainActor
class OpenSeattleAPIService: ObservableObject {
    @Published var isLoading = false
    @Published var lastFetchDate: Date?
    @Published var error: Error?
    @Published var fetchProgress: (current: Int, total: Int) = (0, 0)
    
    private let baseURL = "https://data.seattle.gov/resource/gm8h-9449.json"
    private let batchSize = 2000 // Increased for fewer network requests
    private let maxRetries = 3
    private let cacheDuration: TimeInterval = 1800 // 30 minutes cache - bridge status doesn't change frequently
    private let maxItemsToProcess = 3000 // Limit total items to reduce memory usage
    private let networkSession: NetworkSession
    private let decoder: JSONDecoder

    init(networkSession: NetworkSession = URLSession.shared, decoder: JSONDecoder? = nil) {
        self.networkSession = networkSession
        if let decoder = decoder {
            self.decoder = decoder
        } else {
            let d = JSONDecoder()
            d.dateDecodingStrategy = .iso8601
            self.decoder = d
        }
    }
    
    // MARK: - Cache Management
    private func shouldFetchFreshData() -> Bool {
        guard let lastFetch = lastFetchDate else { return true }
        return Date().timeIntervalSince(lastFetch) > cacheDuration
    }
    
    private func performBackgroundRefresh(modelContext: ModelContext, progressCallback: ((Int, Int) -> Void)? = nil) async {
        print("🔵 performBackgroundRefresh: Starting background refresh")
        isLoading = true
        defer { 
            isLoading = false
            print("🔵 performBackgroundRefresh: Fetch completed, isLoading set to false")
        }
        
        var retryCount = 0
        while retryCount < maxRetries {
            do {
                // Only clear data on the first attempt, not on retries
                if retryCount == 0 {
                    print("🔵 performBackgroundRefresh: Clearing existing data")
                    try modelContext.transaction {
                        try? modelContext.delete(model: DrawbridgeInfo.self)
                    }
                } else {
                    print("🔵 performBackgroundRefresh: Retry \(retryCount) - preserving existing data")
                }
                var offset = 0
                var allResponses: [DrawbridgeEventResponse] = []
                // 1. Fetch all batches from the network (async)
                print("🔵 performBackgroundRefresh: Starting batch fetches")
                while true {
                    print("🔵 performBackgroundRefresh: Fetching batch at offset \(offset)")
                    let batch = try await fetchBatch(offset: offset, limit: batchSize)
                    print("🔵 performBackgroundRefresh: Received batch with \(batch.count) items")
                    if batch.isEmpty { 
                        print("🔵 performBackgroundRefresh: Empty batch received, stopping")
                        break 
                    }
                    allResponses.append(contentsOf: batch)
                    
                    // Report progress after each batch
                    progressCallback?(allResponses.count, 0) // 0 indicates unknown total
                    fetchProgress = (allResponses.count, 0)
                    
                    // Limit total items to reduce memory usage
                    if allResponses.count >= maxItemsToProcess {
                        print("🔵 performBackgroundRefresh: Reached item limit (\(maxItemsToProcess)), stopping")
                        break
                    }
                    
                    if batch.count < batchSize { 
                        print("🔵 performBackgroundRefresh: Final batch received, stopping")
                        break 
                    }
                    offset += batchSize
                }
                print("🔵 performBackgroundRefresh: Total responses collected: \(allResponses.count)")
                
                // Report progress for UI updates
                progressCallback?(allResponses.count, allResponses.count)
                fetchProgress = (allResponses.count, allResponses.count)
                
                // 2. Perform all SwiftData mutations in a single transaction (sync)
                print("🔵 performBackgroundRefresh: Starting data processing")
                
                // Process in chunks to reduce memory pressure
                let chunkSize = 1000
                for chunkStart in stride(from: 0, to: allResponses.count, by: chunkSize) {
                    let chunkEnd = min(chunkStart + chunkSize, allResponses.count)
                    let chunk = Array(allResponses[chunkStart..<chunkEnd])
                    
                    try modelContext.transaction {
                    var bridgeMap: [String: DrawbridgeInfo] = [:]
                    // Deduplicate and insert/update bridges for this chunk
                    for response in chunk {
                        guard let entityID = response.entityid,
                              let entityName = response.entityname,
                              let entityType = response.entitytype,
                              let latitudeString = response.latitude,
                              let latitude = Double(latitudeString),
                              let longitudeString = response.longitude,
                              let longitude = Double(longitudeString) else { continue }
                        if bridgeMap[entityID] == nil {
                            let bridge = DrawbridgeInfo(
                                entityID: entityID,
                                entityName: entityName,
                                entityType: entityType,
                                latitude: latitude,
                                longitude: longitude
                            )
                            modelContext.insert(bridge)
                            bridgeMap[entityID] = bridge
                        }
                    }
                    // Insert new events for this chunk
                    for response in chunk {
                        guard let entityID = response.entityid,
                              let entityName = response.entityname,
                              let entityType = response.entitytype,
                              let bridge = bridgeMap[entityID],
                              let openDateTimeString = response.opendatetime,
                              let openDateTime = parseDate(openDateTimeString),
                              let latitudeString = response.latitude,
                              let latitude = Double(latitudeString),
                              let longitudeString = response.longitude,
                              let longitude = Double(longitudeString) else { continue }
                        let closeDateTime = response.closedatetime.flatMap { parseDate($0) }
                        let minutesOpen: Double = {
                            if let m = response.minutesopen, let val = Double(m) { return val }
                            if let close = closeDateTime { return close.timeIntervalSince(openDateTime) / 60.0 }
                            return 0.0
                        }()
                        let event = DrawbridgeEvent(
                            entityID: entityID,
                            entityName: entityName,
                            entityType: entityType,
                            bridge: bridge,
                            openDateTime: openDateTime,
                            closeDateTime: closeDateTime,
                            minutesOpen: minutesOpen,
                            latitude: latitude,
                            longitude: longitude
                        )
                        modelContext.insert(event)
                    }
                }
                }
                lastFetchDate = Date()
                error = nil // clear error on success
                fetchProgress = (0, 0) // Reset progress
                print("🔵 performBackgroundRefresh: Successfully completed")
                return // Success - exit retry loop
            } catch {
                print("🔴 performBackgroundRefresh: Error occurred - \(error)")
                if let urlError = error as? URLError {
                    print("🔴 performBackgroundRefresh: URLError code: \(urlError.code.rawValue), description: \(urlError.localizedDescription)")
                    
                    // Handle cancellation errors gracefully - retry instead of showing error
                    if urlError.code == .cancelled {
                        retryCount += 1
                        print("🔴 performBackgroundRefresh: Network request was cancelled - retry \(retryCount)/\(maxRetries)")
                        if retryCount < maxRetries {
                            // Wait a bit before retrying
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                            continue
                        } else {
                            print("🔴 performBackgroundRefresh: Max retries reached for cancelled request")
                            // Set a user-friendly error for repeated cancellations
                            self.error = BridgetDataError.networkError(NSError(
                                domain: "API", 
                                code: 0, 
                                userInfo: [NSLocalizedDescriptionKey: "Unable to refresh data. Please try again."]
                            ))
                            return
                        }
                    }
                }
                self.error = error
                return // Non-cancellation error - don't retry
            }
        }
    }
    
    // MARK: - Event & Bridge Data Fetching (Batch)
    /// Refactored: All async network fetches are performed before entering the transaction block.
    /// Accumulate all DrawbridgeEventResponse objects first, then perform a single transaction for all SwiftData mutations (deletes/inserts/updates).
    /// Rationale: SwiftData's transaction block is synchronous and must not contain any await calls. See technical documentation for details.
    func fetchAndStoreAllData(modelContext: ModelContext, progressCallback: ((Int, Int) -> Void)? = nil) async {
        // Always return immediately if we have cached data
        if !shouldFetchFreshData() {
            print("🔵 fetchAndStoreAllData: Using cached data (last fetch: \(lastFetchDate?.timeIntervalSinceNow ?? 0)s ago)")
            return
        }
        
        // Start background refresh without blocking UI
        print("🔵 fetchAndStoreAllData: Starting background refresh")
        Task {
            await performBackgroundRefresh(modelContext: modelContext, progressCallback: progressCallback)
        }
    }
    
    private func fetchBatch(offset: Int, limit: Int) async throws -> [DrawbridgeEventResponse] {
        guard let url = URL(string: "\(baseURL)?$limit=\(limit)&$offset=\(offset)") else {
            throw BridgetDataError.invalidData("Invalid URL for event data")
        }
        let (data, response) = try await networkSession.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw BridgetDataError.networkError(NSError(domain: "API", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch event data"]))
        }
        return try decoder.decode([DrawbridgeEventResponse].self, from: data)
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatters: [Any] = [
            createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss.SSS"),
            createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss"),
            createISOFormatter(withFractionalSeconds: true),
            createISOFormatter(withFractionalSeconds: false)
        ]
        for formatter in formatters {
            if let df = formatter as? DateFormatter, let date = df.date(from: dateString) { return date }
            if let iso = formatter as? ISO8601DateFormatter, let date = iso.date(from: dateString) { return date }
        }
        return nil
    }
    private func createDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = TimeZone.current
        return formatter
    }
    private func createISOFormatter(withFractionalSeconds: Bool) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        if withFractionalSeconds {
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        } else {
            formatter.formatOptions = [.withInternetDateTime]
        }
        return formatter
    }
} 
