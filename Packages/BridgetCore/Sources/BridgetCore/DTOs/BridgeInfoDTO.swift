import Foundation
import SwiftData

/// Sendable Data Transfer Object for DrawbridgeInfo
/// Used for safe actor boundary crossing in concurrent operations
public struct BridgeInfoDTO: Sendable, Codable, Identifiable, Hashable {
    public let id: UUID
    public let entityID: String
    public let entityName: String
    public let entityType: String
    public let latitude: Double
    public let longitude: Double
    
    /// Initialize from a DrawbridgeInfo model
    /// - Parameter bridge: The DrawbridgeInfo model to convert
    public init(from bridge: DrawbridgeInfo) {
        self.id = bridge.id
        self.entityID = bridge.entityID
        self.entityName = bridge.entityName
        self.entityType = bridge.entityType
        self.latitude = bridge.latitude
        self.longitude = bridge.longitude
    }
    
    /// Initialize with all required parameters
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - entityID: Bridge entity identifier
    ///   - entityName: Bridge name
    ///   - entityType: Bridge type
    ///   - latitude: Bridge latitude
    ///   - longitude: Bridge longitude
    public init(
        id: UUID = UUID(),
        entityID: String,
        entityName: String,
        entityType: String,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.entityID = entityID
        self.entityName = entityName
        self.entityType = entityType
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Convenience Extensions

public extension BridgeInfoDTO {
    /// Create a coordinate from latitude and longitude
    var coordinate: (latitude: Double, longitude: Double) {
        (latitude: latitude, longitude: longitude)
    }
    
    /// Check if bridge is a drawbridge
    var isDrawbridge: Bool {
        entityType.lowercased().contains("drawbridge")
    }
    
    /// Check if bridge is a swing bridge
    var isSwingBridge: Bool {
        entityType.lowercased().contains("swing")
    }
    
    /// Check if bridge is a lift bridge
    var isLiftBridge: Bool {
        entityType.lowercased().contains("lift")
    }
    
    /// Get bridge type as display string
    var displayType: String {
        switch entityType.lowercased() {
        case let type where type.contains("drawbridge"):
            return "Drawbridge"
        case let type where type.contains("swing"):
            return "Swing Bridge"
        case let type where type.contains("lift"):
            return "Lift Bridge"
        default:
            return entityType.capitalized
        }
    }
    
    /// Calculate distance to another bridge
    /// - Parameter other: Another bridge to calculate distance to
    /// - Returns: Distance in meters
    func distance(to other: BridgeInfoDTO) -> Double {
        let earthRadius = 6371000.0 // Earth's radius in meters
        
        let lat1Rad = latitude * .pi / 180
        let lat2Rad = other.latitude * .pi / 180
        let deltaLatRad = (other.latitude - latitude) * .pi / 180
        let deltaLonRad = (other.longitude - longitude) * .pi / 180
        
        let a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLonRad / 2) * sin(deltaLonRad / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    /// Format distance as human-readable string
    /// - Parameter distance: Distance in meters
    /// - Returns: Formatted distance string
    func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            let kilometers = distance / 1000
            return String(format: "%.1fkm", kilometers)
        }
    }
}

// MARK: - Equatable Implementation

public extension BridgeInfoDTO {
    static func == (lhs: BridgeInfoDTO, rhs: BridgeInfoDTO) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Comparable Implementation

extension BridgeInfoDTO: Comparable {
    public static func < (lhs: BridgeInfoDTO, rhs: BridgeInfoDTO) -> Bool {
        lhs.entityName < rhs.entityName
    }
} 