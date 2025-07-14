import Foundation
import SwiftData

@Model
public final class DrawbridgeEvent {
    @Attribute(.unique) public var id: UUID
    public var entityID: String
    public var entityName: String
    public var entityType: String
    @Relationship public var bridge: DrawbridgeInfo
    public var openDateTime: Date
    public var closeDateTime: Date?
    public var minutesOpen: Double
    public var latitude: Double
    public var longitude: Double
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        entityID: String,
        entityName: String,
        entityType: String,
        bridge: DrawbridgeInfo,
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
        self.bridge = bridge
        self.openDateTime = openDateTime
        self.closeDateTime = closeDateTime
        self.minutesOpen = minutesOpen
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = Date()
        self.updatedAt = Date()
    }
} 