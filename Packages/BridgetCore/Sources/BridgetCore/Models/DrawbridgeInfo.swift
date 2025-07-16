import Foundation
import SwiftData

@Model
public final class DrawbridgeInfo {
    @Attribute(.unique) public var id: UUID
    public var entityID: String
    public var entityName: String
    public var entityType: String
    public var latitude: Double
    public var longitude: Double
    
    /// Events associated with this bridge.
    /// Uses cascade delete rule: when this bridge is deleted, all its events are automatically deleted.
    /// This enforces the domain rule that events are meaningless without a bridge.
    @Relationship(deleteRule: .cascade, inverse: \DrawbridgeEvent.bridge) public var events: [DrawbridgeEvent] = []
    
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