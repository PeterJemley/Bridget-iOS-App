import Foundation
import SwiftData

/// Sendable Data Transfer Object for DrawbridgeEvent
/// Used for safe actor boundary crossing in concurrent operations
public struct BridgeEventDTO: Sendable, Codable, Identifiable, Hashable {
    public let id: UUID
    public let entityID: String
    public let entityName: String
    public let entityType: String
    public let bridgeID: UUID // Reference to bridge
    public let openDateTime: Date
    public let closeDateTime: Date?
    public let minutesOpen: Double
    public let latitude: Double
    public let longitude: Double
    
    /// Initialize from a DrawbridgeEvent model
    /// - Parameter event: The DrawbridgeEvent model to convert
    public init(from event: DrawbridgeEvent) {
        self.id = event.id
        self.entityID = event.entityID
        self.entityName = event.entityName
        self.entityType = event.entityType
        self.bridgeID = event.bridge.id
        self.openDateTime = event.openDateTime
        self.closeDateTime = event.closeDateTime
        self.minutesOpen = event.minutesOpen
        self.latitude = event.latitude
        self.longitude = event.longitude
    }
    
    /// Initialize with all required parameters
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - entityID: Bridge entity identifier
    ///   - entityName: Bridge name
    ///   - entityType: Bridge type
    ///   - bridgeID: Reference to bridge
    ///   - openDateTime: When bridge opened
    ///   - closeDateTime: When bridge closed (optional)
    ///   - minutesOpen: Duration bridge was open
    ///   - latitude: Bridge latitude
    ///   - longitude: Bridge longitude
    public init(
        id: UUID = UUID(),
        entityID: String,
        entityName: String,
        entityType: String,
        bridgeID: UUID,
        openDateTime: Date,
        closeDateTime: Date? = nil,
        minutesOpen: Double = 0.0,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.entityID = entityID
        self.entityName = entityName
        self.entityType = entityType
        self.bridgeID = bridgeID
        self.openDateTime = openDateTime
        self.closeDateTime = closeDateTime
        self.minutesOpen = minutesOpen
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Convenience Extensions

public extension BridgeEventDTO {
    /// Check if bridge is currently open
    var isCurrentlyOpen: Bool {
        closeDateTime == nil
    }
    
    /// Calculate duration bridge was open
    var duration: TimeInterval {
        if let closeDateTime = closeDateTime {
            return closeDateTime.timeIntervalSince(openDateTime)
        }
        return Date().timeIntervalSince(openDateTime)
    }
    
    /// Format duration as human-readable string
    var formattedDuration: String {
        let duration = self.duration
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Equatable Implementation

public extension BridgeEventDTO {
    static func == (lhs: BridgeEventDTO, rhs: BridgeEventDTO) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
} 