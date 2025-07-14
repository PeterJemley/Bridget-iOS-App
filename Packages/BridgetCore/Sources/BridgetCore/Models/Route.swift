import Foundation
import SwiftData

@Model
public final class Route {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var startLocation: String
    public var endLocation: String
    public var bridges: [String] // Bridge IDs along route
    public var isFavorite: Bool
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        startLocation: String,
        endLocation: String,
        bridges: [String] = [],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.bridges = bridges
        self.isFavorite = isFavorite
        self.createdAt = Date()
        self.updatedAt = Date()
    }
} 