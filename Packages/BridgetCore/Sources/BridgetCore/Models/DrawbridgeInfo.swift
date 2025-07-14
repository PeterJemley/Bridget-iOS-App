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
    public var createdAt: Date
    public var updatedAt: Date
    
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
        self.createdAt = Date()
        self.updatedAt = Date()
    }
} 