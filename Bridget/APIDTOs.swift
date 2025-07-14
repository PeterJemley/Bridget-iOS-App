import Foundation
import BridgetCore

// MARK: - API Data Transfer Objects

struct APIBridgeInfo: Codable {
    let entityID: String
    let entityName: String
    let entityType: String
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case entityID = "entity_id"
        case entityName = "entity_name"
        case entityType = "entity_type"
        case latitude
        case longitude
    }
    
    func toDrawbridgeInfo() -> DrawbridgeInfo {
        return DrawbridgeInfo(
            entityID: entityID,
            entityName: entityName,
            entityType: entityType,
            latitude: latitude,
            longitude: longitude
        )
    }
}

struct APIBridgeEvent: Codable {
    let entityID: String
    let entityName: String
    let entityType: String
    let openDateTime: String
    let closeDateTime: String?
    let minutesOpen: Double
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case entityID = "entity_id"
        case entityName = "entity_name"
        case entityType = "entity_type"
        case openDateTime = "open_date_time"
        case closeDateTime = "close_date_time"
        case minutesOpen = "minutes_open"
        case latitude
        case longitude
    }
    
    // func toDrawbridgeEvent() -> DrawbridgeEvent? {
    //     let dateFormatter = ISO8601DateFormatter()
    //     guard let openDate = dateFormatter.date(from: openDateTime) else {
    //         return nil
    //     }
    //     let closeDate = closeDateTime.flatMap { dateFormatter.date(from: $0) }
    //     return DrawbridgeEvent(
    //         entityID: entityID,
    //         entityName: entityName,
    //         entityType: entityType,
    //         openDateTime: openDate,
    //         closeDateTime: closeDate,
    //         minutesOpen: minutesOpen,
    //         latitude: latitude,
    //         longitude: longitude
    //     )
    // }
} 