import Foundation
import BridgetCore
import SwiftData

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

@MainActor
class OpenSeattleAPIService: ObservableObject {
    @Published var isLoading = false
    @Published var lastFetchDate: Date?
    
    private let baseURL = "https://data.seattle.gov/resource/gm8h-9449.json"
    private let batchSize = 1000
    private let maxRetries = 3
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    
    // MARK: - Event & Bridge Data Fetching (Batch)
    func fetchAndStoreAllData(modelContext: ModelContext) async throws {
        isLoading = true
        defer { isLoading = false }
        var allResponses: [DrawbridgeEventResponse] = []
        var offset = 0
        var retryCount = 0
        
        // Batch fetch all event rows
        while true {
            do {
                let batch = try await fetchBatch(offset: offset, limit: batchSize)
                if batch.isEmpty { break }
                allResponses.append(contentsOf: batch)
                if batch.count < batchSize { break }
                offset += batchSize
                retryCount = 0
            } catch {
                retryCount += 1
                if retryCount >= maxRetries { throw error }
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount))) * 1_000_000_000)
            }
        }
        lastFetchDate = Date()
        
        // Deduplicate bridges by entityID
        var bridgeMap: [String: DrawbridgeInfo] = [:]
        for response in allResponses {
            guard let entityID = response.entityid,
                  let entityName = response.entityname,
                  let entityType = response.entitytype,
                  let latitudeString = response.latitude,
                  let latitude = Double(latitudeString),
                  let longitudeString = response.longitude,
                  let longitude = Double(longitudeString) else { continue }
            if bridgeMap[entityID] == nil {
                // Try to fetch existing bridge from context
                let fetchDescriptor = FetchDescriptor<DrawbridgeInfo>(predicate: #Predicate { $0.entityID == entityID })
                let existing = try? modelContext.fetch(fetchDescriptor).first
                let bridge = existing ?? DrawbridgeInfo(
                    entityID: entityID,
                    entityName: entityName,
                    entityType: entityType,
                    latitude: latitude,
                    longitude: longitude
                )
                // Update name/type/coords in case they changed
                bridge.entityName = entityName
                bridge.entityType = entityType
                bridge.latitude = latitude
                bridge.longitude = longitude
                bridge.updatedAt = Date()
                if existing == nil { modelContext.insert(bridge) }
                bridgeMap[entityID] = bridge
            }
        }
        // Remove all existing events
        let existingEvents = try modelContext.fetch(FetchDescriptor<DrawbridgeEvent>())
        for event in existingEvents { modelContext.delete(event) }
        // Insert new events, linking to bridges
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
        try modelContext.save()
    }
    
    private func fetchBatch(offset: Int, limit: Int) async throws -> [DrawbridgeEventResponse] {
        guard let url = URL(string: "\(baseURL)?$limit=\(limit)&$offset=\(offset)") else {
            throw BridgetDataError.invalidData("Invalid URL for event data")
        }
        let (data, response) = try await URLSession.shared.data(from: url)
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