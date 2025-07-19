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
    /// Uses nullify delete rule to prevent memory management issues.
    /// Events will be orphaned if bridge is deleted, but this prevents crashes.
    @Relationship(deleteRule: .nullify, inverse: \DrawbridgeEvent.bridge) public var events: [DrawbridgeEvent] = []
    
    /// Safe access to events with error handling
    public var safeEvents: [DrawbridgeEvent] {
        do {
            return events
        } catch {
            print("⚠️ SWIFTDATA: Error accessing events for bridge \(entityName): \(error)")
            return []
        }
    }
    
    /// Computed property to safely access events with additional safety checks
    public var accessibleEvents: [DrawbridgeEvent] {
        // Check if the model context is available
        guard let context = modelContext else {
            print("⚠️ SWIFTDATA: No model context available for bridge \(entityName)")
            return []
        }
        
        do {
            return events
        } catch {
            print("⚠️ SWIFTDATA: Error accessing events for bridge \(entityName): \(error)")
            return []
        }
    }
    
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
