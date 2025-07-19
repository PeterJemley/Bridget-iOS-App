import Foundation
import SwiftData

/// Sendable Data Transfer Object for Route
/// Used for safe actor boundary crossing in concurrent operations
public struct RouteDTO: Sendable, Codable, Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let startLocation: String
    public let endLocation: String
    public let bridges: [String] // Bridge IDs along route
    public let isFavorite: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    /// Initialize from a Route model
    /// - Parameter route: The Route model to convert
    public init(from route: Route) {
        self.id = route.id
        self.name = route.name
        self.startLocation = route.startLocation
        self.endLocation = route.endLocation
        self.bridges = route.bridges
        self.isFavorite = route.isFavorite
        self.createdAt = route.createdAt
        self.updatedAt = route.updatedAt
    }
    
    /// Initialize with individual properties
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - name: Route name
    ///   - startLocation: Starting location
    ///   - endLocation: Ending location
    ///   - bridges: Array of bridge IDs
    ///   - isFavorite: Whether route is favorited
    ///   - createdAt: Creation timestamp
    ///   - updatedAt: Last update timestamp
    public init(
        id: UUID = UUID(),
        name: String,
        startLocation: String,
        endLocation: String,
        bridges: [String] = [],
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.bridges = bridges
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Convenience Extensions

public extension RouteDTO {
    /// Get route description
    var description: String {
        "\(startLocation) → \(endLocation)"
    }
    
    /// Get route display name
    var displayName: String {
        if name.isEmpty {
            return description
        }
        return name
    }
    
    /// Check if route has bridges
    var hasBridges: Bool {
        !bridges.isEmpty
    }
    
    /// Get number of bridges in route
    var bridgeCount: Int {
        bridges.count
    }
    
    /// Get bridge count as display string
    var bridgeCountDisplay: String {
        switch bridgeCount {
        case 0:
            return "No bridges"
        case 1:
            return "1 bridge"
        default:
            return "\(bridgeCount) bridges"
        }
    }
    
    /// Check if route is recently created (within last 7 days)
    var isRecentlyCreated: Bool {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return createdAt > sevenDaysAgo
    }
    
    /// Get route age in days
    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
    
    /// Get route age as display string
    var ageDisplay: String {
        let days = ageInDays
        switch days {
        case 0:
            return "Today"
        case 1:
            return "Yesterday"
        case 2...6:
            return "\(days) days ago"
        case 7...13:
            return "1 week ago"
        case 14...20:
            return "2 weeks ago"
        case 21...27:
            return "3 weeks ago"
        default:
            let weeks = days / 7
            return "\(weeks) weeks ago"
        }
    }
    
    /// Toggle favorite status
    /// - Returns: New RouteDTO with toggled favorite status
    func toggleFavorite() -> RouteDTO {
        RouteDTO(
            id: id,
            name: name,
            startLocation: startLocation,
            endLocation: endLocation,
            bridges: bridges,
            isFavorite: !isFavorite,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
    
    /// Add bridge to route
    /// - Parameter bridgeID: Bridge ID to add
    /// - Returns: New RouteDTO with added bridge
    func addingBridge(_ bridgeID: String) -> RouteDTO {
        var newBridges = bridges
        if !newBridges.contains(bridgeID) {
            newBridges.append(bridgeID)
        }
        
        return RouteDTO(
            id: id,
            name: name,
            startLocation: startLocation,
            endLocation: endLocation,
            bridges: newBridges,
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
    
    /// Remove bridge from route
    /// - Parameter bridgeID: Bridge ID to remove
    /// - Returns: New RouteDTO with removed bridge
    func removingBridge(_ bridgeID: String) -> RouteDTO {
        let newBridges = bridges.filter { $0 != bridgeID }
        
        return RouteDTO(
            id: id,
            name: name,
            startLocation: startLocation,
            endLocation: endLocation,
            bridges: newBridges,
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
    
    /// Check if route contains specific bridge
    /// - Parameter bridgeID: Bridge ID to check
    /// - Returns: True if route contains bridge
    func containsBridge(_ bridgeID: String) -> Bool {
        bridges.contains(bridgeID)
    }
}

// MARK: - Equatable Implementation

public extension RouteDTO {
    static func == (lhs: RouteDTO, rhs: RouteDTO) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Comparable Implementation

extension RouteDTO: Comparable {
    public static func < (lhs: RouteDTO, rhs: RouteDTO) -> Bool {
        // Sort favorites first, then by name
        if lhs.isFavorite != rhs.isFavorite {
            return lhs.isFavorite
        }
        return lhs.displayName < rhs.displayName
    }
} 