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
    
    private let baseURL = "https://data.seattle.gov/resource/gm8h-9449.json"
    private let batchSize = 1000
    private let maxRetries = 3
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
    
    // MARK: - Event & Bridge Data Fetching (Batch)
    /// Refactored: All async network fetches are performed before entering the transaction block.
    /// Accumulate all DrawbridgeEventResponse objects first, then perform a single transaction for all SwiftData mutations (deletes/inserts/updates).
    /// Rationale: SwiftData's transaction block is synchronous and must not contain any await calls. See technical documentation for details.
    func fetchAndStoreAllData(modelContext: ModelContext) async throws {
        isLoading = true
        defer { isLoading = false }
        // Erase all local bridge and event data before fetching new data
        try modelContext.transaction {
            try modelContext.delete(model: DrawbridgeEvent.self)
            try modelContext.delete(model: DrawbridgeInfo.self)
        }
        var offset = 0
        var allResponses: [DrawbridgeEventResponse] = []
        // 1. Fetch all batches from the network (async)
        while true {
            let batch = try await fetchBatch(offset: offset, limit: batchSize)
            if batch.isEmpty { break }
            allResponses.append(contentsOf: batch)
            if batch.count < batchSize { break }
            offset += batchSize
        }
        // 2. Perform all SwiftData mutations in a single transaction (sync)
        try modelContext.transaction {
            var bridgeMap: [String: DrawbridgeInfo] = [:]
            // Deduplicate and insert/update bridges for all responses
            for response in allResponses {
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
            // Insert new events for all responses
            for response in allResponses {
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
        lastFetchDate = Date()
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
