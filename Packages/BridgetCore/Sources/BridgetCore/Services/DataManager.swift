import Foundation
import SwiftData

@Observable
public final class DataManager {
    private let modelContext: ModelContext
    
    // MARK: - Services
    public let eventService: DrawbridgeEventService
    public let infoService: DrawbridgeInfoService
    public let routeService: RouteService
    public let trafficService: TrafficFlowService
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Initialize all services
        self.eventService = DrawbridgeEventService(modelContext: modelContext)
        self.infoService = DrawbridgeInfoService(modelContext: modelContext)
        self.routeService = RouteService(modelContext: modelContext)
        self.trafficService = TrafficFlowService(modelContext: modelContext)
    }
    
    // MARK: - Data Synchronization
    
    /// Synchronize all data from external sources
    /// - Parameter forceRefresh: If true, force refresh even if data is recent
    public func synchronizeData(forceRefresh: Bool = false) async throws {
        do {
            // This would typically involve calling external APIs
            // For now, we'll implement a placeholder that can be extended
            try await refreshBridgeEvents(forceRefresh: forceRefresh)
            try await refreshBridgeInfo(forceRefresh: forceRefresh)
            try await refreshTrafficData(forceRefresh: forceRefresh)
        } catch {
            throw BridgetDataError.networkError(error)
        }
    }
    
    /// Refresh bridge events from external API
    /// - Parameter forceRefresh: If true, force refresh even if data is recent
    private func refreshBridgeEvents(forceRefresh: Bool) async throws {
        // TODO: Implement API call to Open Seattle API
        // This would fetch new bridge events and save them to SwiftData
        // For now, this is a placeholder
    }
    
    /// Refresh bridge information from external API
    /// - Parameter forceRefresh: If true, force refresh even if data is recent
    private func refreshBridgeInfo(forceRefresh: Bool) async throws {
        // TODO: Implement API call to get bridge information
        // This would fetch bridge details and save them to SwiftData
        // For now, this is a placeholder
    }
    
    /// Refresh traffic data from external API
    /// - Parameter forceRefresh: If true, force refresh even if data is recent
    private func refreshTrafficData(forceRefresh: Bool) async throws {
        // TODO: Implement API call to get traffic data
        // This would fetch traffic information and save it to SwiftData
        // For now, this is a placeholder
    }
    
    // MARK: - Data Cleanup
    
    /// Clean up old data to maintain performance
    /// - Parameter olderThan: Delete data older than this date
    public func cleanupOldData(olderThan date: Date) async throws {
        do {
            try await eventService.deleteEventsOlderThan(date)
            try await trafficService.deleteTrafficFlowOlderThan(date)
        } catch {
            throw BridgetDataError.deleteFailed(error)
        }
    }
    
    /// Clean up all data (use with caution)
    public func cleanupAllData() async throws {
        do {
            try await eventService.deleteEvents(for: "") // This would need to be modified to delete all
            try await infoService.deleteAllBridges()
            try await routeService.deleteAllRoutes()
            try await trafficService.deleteTrafficFlow(for: "") // This would need to be modified to delete all
        } catch {
            throw BridgetDataError.deleteFailed(error)
        }
    }
    
    // MARK: - Analytics & Reporting
    
    /// Get comprehensive app statistics
    /// - Returns: Dictionary with all app statistics
    public func getAppStatistics() async throws -> [String: Any] {
        do {
            let eventStats = try await eventService.getBridgeStatistics(for: "all")
            let routeStats = try await routeService.getRouteStatistics()
            let trafficStats = try await trafficService.getOverallTrafficStatistics()
            let bridgeStats = try await infoService.getBridgeStatistics()
            
            return [
                "events": eventStats,
                "routes": routeStats,
                "traffic": trafficStats,
                "bridges": bridgeStats,
                "lastUpdated": Date()
            ]
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    /// Get bridge-specific comprehensive data
    /// - Parameter bridgeID: The bridge ID to get data for
    /// - Returns: Dictionary with all data for the specified bridge
    public func getBridgeComprehensiveData(bridgeID: String) async throws -> [String: Any] {
        do {
            let bridgeInfo = try await infoService.fetchBridge(entityID: bridgeID)
            let events = try await eventService.fetchEvents(for: bridgeID)
            let trafficStats = try await trafficService.getTrafficStatistics(for: bridgeID)
            let predictedCongestion = try await trafficService.predictCongestion(for: bridgeID)
            let affectedRoutes = try await routeService.getRoutesAffectedByBridgeOpening(bridgeID)
            
            return [
                "bridgeInfo": bridgeInfo as Any,
                "events": events,
                "trafficStats": trafficStats,
                "predictedCongestion": predictedCongestion,
                "affectedRoutes": affectedRoutes.count,
                "lastUpdated": Date()
            ]
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    // MARK: - Data Validation
    
    /// Validate data integrity
    /// - Returns: Array of validation issues found
    public func validateDataIntegrity() async throws -> [String] {
        var issues: [String] = []
        
        do {
            // Check for orphaned events (events without corresponding bridge info)
            let events = try await eventService.fetchEvents()
            let bridgeIDs = Set(try await infoService.fetchAllBridges().map { $0.entityID })
            
            for event in events {
                if !bridgeIDs.contains(event.entityID) {
                    issues.append("Orphaned event found for bridge ID: \(event.entityID)")
                }
            }
            
            // Check for orphaned traffic data
            let trafficFlows = try await trafficService.fetchTrafficFlow()
            for flow in trafficFlows {
                if !bridgeIDs.contains(flow.bridgeID) {
                    issues.append("Orphaned traffic data found for bridge ID: \(flow.bridgeID)")
                }
            }
            
            // Check for orphaned routes (routes referencing non-existent bridges)
            let routes = try await routeService.fetchRoutes()
            for route in routes {
                for bridgeID in route.bridges {
                    if !bridgeIDs.contains(bridgeID) {
                        issues.append("Route '\(route.name)' references non-existent bridge: \(bridgeID)")
                    }
                }
            }
            
        } catch {
            issues.append("Error during validation: \(error.localizedDescription)")
        }
        
        return issues
    }
    
    // MARK: - Data Export
    
    /// Export data for backup or analysis
    /// - Returns: Dictionary with all data for export
    public func exportData() async throws -> [String: Any] {
        do {
            let events = try await eventService.fetchEvents()
            let bridges = try await infoService.fetchAllBridges()
            let routes = try await routeService.fetchRoutes()
            let trafficFlows = try await trafficService.fetchTrafficFlow()
            
            return [
                "exportDate": Date(),
                "version": "1.0",
                "events": events.map { event in
                    [
                        "id": event.id.uuidString,
                        "entityID": event.entityID,
                        "entityName": event.entityName,
                        "openDateTime": event.openDateTime as Any,
                        "closeDateTime": event.closeDateTime as Any,
                        "minutesOpen": event.minutesOpen,
                        "latitude": event.latitude,
                        "longitude": event.longitude
                    ]
                },
                "bridges": bridges.map { bridge in
                    [
                        "id": bridge.id.uuidString,
                        "entityID": bridge.entityID,
                        "entityName": bridge.entityName,
                        "entityType": bridge.entityType,
                        "latitude": bridge.latitude,
                        "longitude": bridge.longitude
                    ]
                },
                "routes": routes.map { route in
                    [
                        "id": route.id.uuidString,
                        "name": route.name,
                        "startLocation": route.startLocation,
                        "endLocation": route.endLocation,
                        "bridges": route.bridges,
                        "isFavorite": route.isFavorite
                    ]
                },
                "trafficFlows": trafficFlows.map { flow in
                    [
                        "id": flow.id.uuidString,
                        "bridgeID": flow.bridgeID,
                        "timestamp": flow.timestamp,
                        "congestionLevel": flow.congestionLevel,
                        "trafficVolume": flow.trafficVolume,
                        "correlationScore": flow.correlationScore
                    ]
                }
            ]
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
} 