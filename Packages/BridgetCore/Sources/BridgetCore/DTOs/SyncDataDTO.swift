import Foundation

/// Sendable Data Transfer Object for bulk data synchronization
/// Used for safe actor boundary crossing in concurrent operations
public struct SyncDataDTO: Sendable, Codable, Hashable {
    public let bridges: [BridgeInfoDTO]
    public let events: [BridgeEventDTO]
    public let routes: [RouteDTO]
    public let trafficFlows: [TrafficFlowDTO]
    public let syncTimestamp: Date
    public let source: String
    
    /// Initialize with all data types
    /// - Parameters:
    ///   - bridges: Array of bridge information DTOs
    ///   - events: Array of bridge event DTOs
    ///   - routes: Array of route DTOs
    ///   - trafficFlows: Array of traffic flow DTOs
    ///   - syncTimestamp: When the sync occurred
    ///   - source: Source of the data (e.g., "api", "cache", "manual")
    public init(
        bridges: [BridgeInfoDTO] = [],
        events: [BridgeEventDTO] = [],
        routes: [RouteDTO] = [],
        trafficFlows: [TrafficFlowDTO] = [],
        syncTimestamp: Date = Date(),
        source: String = "api"
    ) {
        self.bridges = bridges
        self.events = events
        self.routes = routes
        self.trafficFlows = trafficFlows
        self.syncTimestamp = syncTimestamp
        self.source = source
    }
    
    /// Create empty sync data
    /// - Parameters:
    ///   - syncTimestamp: When the sync occurred
    ///   - source: Source of the data
    /// - Returns: Empty SyncDataDTO
    public static func empty(
        syncTimestamp: Date = Date(),
        source: String = "empty"
    ) -> SyncDataDTO {
        SyncDataDTO(
            bridges: [],
            events: [],
            routes: [],
            trafficFlows: [],
            syncTimestamp: syncTimestamp,
            source: source
        )
    }
    
    /// Create sync data with only bridges
    /// - Parameters:
    ///   - bridges: Array of bridge information DTOs
    ///   - syncTimestamp: When the sync occurred
    ///   - source: Source of the data
    /// - Returns: SyncDataDTO with only bridges
    public static func bridgesOnly(
        _ bridges: [BridgeInfoDTO],
        syncTimestamp: Date = Date(),
        source: String = "api"
    ) -> SyncDataDTO {
        SyncDataDTO(
            bridges: bridges,
            events: [],
            routes: [],
            trafficFlows: [],
            syncTimestamp: syncTimestamp,
            source: source
        )
    }
    
    /// Create sync data with only events
    /// - Parameters:
    ///   - events: Array of bridge event DTOs
    ///   - syncTimestamp: When the sync occurred
    ///   - source: Source of the data
    /// - Returns: SyncDataDTO with only events
    public static func eventsOnly(
        _ events: [BridgeEventDTO],
        syncTimestamp: Date = Date(),
        source: String = "api"
    ) -> SyncDataDTO {
        SyncDataDTO(
            bridges: [],
            events: events,
            routes: [],
            trafficFlows: [],
            syncTimestamp: syncTimestamp,
            source: source
        )
    }
    
    /// Create sync data with only traffic flows
    /// - Parameters:
    ///   - trafficFlows: Array of traffic flow DTOs
    ///   - syncTimestamp: When the sync occurred
    ///   - source: Source of the data
    /// - Returns: SyncDataDTO with only traffic flows
    public static func trafficOnly(
        _ trafficFlows: [TrafficFlowDTO],
        syncTimestamp: Date = Date(),
        source: String = "api"
    ) -> SyncDataDTO {
        SyncDataDTO(
            bridges: [],
            events: [],
            routes: [],
            trafficFlows: trafficFlows,
            syncTimestamp: syncTimestamp,
            source: source
        )
    }
}

// MARK: - Convenience Extensions

public extension SyncDataDTO {
    /// Check if sync data is empty
    var isEmpty: Bool {
        bridges.isEmpty && events.isEmpty && routes.isEmpty && trafficFlows.isEmpty
    }
    
    /// Check if sync data has any content
    var hasContent: Bool {
        !isEmpty
    }
    
    /// Get total number of items
    var totalItems: Int {
        bridges.count + events.count + routes.count + trafficFlows.count
    }
    
    /// Get sync data summary
    var summary: String {
        var parts: [String] = []
        
        if !bridges.isEmpty {
            parts.append("\(bridges.count) bridges")
        }
        if !events.isEmpty {
            parts.append("\(events.count) events")
        }
        if !routes.isEmpty {
            parts.append("\(routes.count) routes")
        }
        if !trafficFlows.isEmpty {
            parts.append("\(trafficFlows.count) traffic flows")
        }
        
        if parts.isEmpty {
            return "No data"
        }
        
        return parts.joined(separator: ", ")
    }
    
    /// Get sync age in seconds
    var syncAgeInSeconds: TimeInterval {
        Date().timeIntervalSince(syncTimestamp)
    }
    
    /// Check if sync is recent (within last 5 minutes)
    var isRecent: Bool {
        syncAgeInSeconds < 300 // 5 minutes
    }
    
    /// Check if sync is stale (older than 1 hour)
    var isStale: Bool {
        syncAgeInSeconds > 3600 // 1 hour
    }
    
    /// Get sync age as display string
    var syncAgeDisplay: String {
        let seconds = Int(syncAgeInSeconds)
        switch seconds {
        case 0...59:
            return "\(seconds)s ago"
        case 60...3599:
            let minutes = seconds / 60
            return "\(minutes)m ago"
        case 3600...86399:
            let hours = seconds / 3600
            return "\(hours)h ago"
        default:
            let days = seconds / 86400
            return "\(days)d ago"
        }
    }
    
    /// Get currently open bridges
    var currentlyOpenBridges: [BridgeInfoDTO] {
        let openEventBridgeIDs = Set(events.filter { $0.isCurrentlyOpen }.map { $0.bridgeID })
        return bridges.filter { openEventBridgeIDs.contains($0.id) }
    }
    
    /// Get number of currently open bridges
    var openBridgeCount: Int {
        currentlyOpenBridges.count
    }
    
    /// Get recent events (within last 24 hours)
    var recentEvents: [BridgeEventDTO] {
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return events.filter { $0.openDateTime > oneDayAgo }
    }
    
    /// Get number of recent events
    var recentEventCount: Int {
        recentEvents.count
    }
    
    /// Get favorite routes
    var favoriteRoutes: [RouteDTO] {
        routes.filter { $0.isFavorite }
    }
    
    /// Get number of favorite routes
    var favoriteRouteCount: Int {
        favoriteRoutes.count
    }
    
    /// Get recent traffic flows (within last hour)
    var recentTrafficFlows: [TrafficFlowDTO] {
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
        return trafficFlows.filter { $0.timestamp > oneHourAgo }
    }
    
    /// Get number of recent traffic flows
    var recentTrafficFlowCount: Int {
        recentTrafficFlows.count
    }
    
    /// Merge with another sync data
    /// - Parameter other: Other sync data to merge with
    /// - Returns: Merged sync data
    func merging(_ other: SyncDataDTO) -> SyncDataDTO {
        SyncDataDTO(
            bridges: bridges + other.bridges,
            events: events + other.events,
            routes: routes + other.routes,
            trafficFlows: trafficFlows + other.trafficFlows,
            syncTimestamp: max(syncTimestamp, other.syncTimestamp),
            source: "merged"
        )
    }
    
    /// Filter events by bridge ID
    /// - Parameter bridgeID: Bridge ID to filter by
    /// - Returns: Filtered sync data
    func filteringEvents(by bridgeID: UUID) -> SyncDataDTO {
        SyncDataDTO(
            bridges: bridges,
            events: events.filter { $0.bridgeID == bridgeID },
            routes: routes,
            trafficFlows: trafficFlows,
            syncTimestamp: syncTimestamp,
            source: source
        )
    }
    
    /// Filter traffic flows by bridge ID
    /// - Parameter bridgeID: Bridge ID to filter by
    /// - Returns: Filtered sync data
    func filteringTrafficFlows(by bridgeID: String) -> SyncDataDTO {
        SyncDataDTO(
            bridges: bridges,
            events: events,
            routes: routes,
            trafficFlows: trafficFlows.filter { $0.bridgeID == bridgeID },
            syncTimestamp: syncTimestamp,
            source: source
        )
    }
    
    /// Remove duplicate items based on ID
    /// - Returns: Sync data with duplicates removed
    func removingDuplicates() -> SyncDataDTO {
        let uniqueBridges = Array(Set(bridges))
        let uniqueEvents = Array(Set(events))
        let uniqueRoutes = Array(Set(routes))
        let uniqueTrafficFlows = Array(Set(trafficFlows))
        
        return SyncDataDTO(
            bridges: uniqueBridges,
            events: uniqueEvents,
            routes: uniqueRoutes,
            trafficFlows: uniqueTrafficFlows,
            syncTimestamp: syncTimestamp,
            source: source
        )
    }
}

// MARK: - Equatable Implementation

public extension SyncDataDTO {
    static func == (lhs: SyncDataDTO, rhs: SyncDataDTO) -> Bool {
        lhs.syncTimestamp == rhs.syncTimestamp &&
        lhs.source == rhs.source &&
        lhs.bridges == rhs.bridges &&
        lhs.events == rhs.events &&
        lhs.routes == rhs.routes &&
        lhs.trafficFlows == rhs.trafficFlows
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(syncTimestamp)
        hasher.combine(source)
        hasher.combine(bridges)
        hasher.combine(events)
        hasher.combine(routes)
        hasher.combine(trafficFlows)
    }
} 