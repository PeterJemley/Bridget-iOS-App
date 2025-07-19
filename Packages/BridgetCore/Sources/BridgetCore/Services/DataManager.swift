import Foundation
import SwiftData
import BridgetCore

@MainActor
public class DataManager {
    private let modelContext: ModelContext
    
    // MARK: - Services
    public let eventService: DrawbridgeEventService
    public let infoService: DrawbridgeInfoService
    public let routeService: RouteService
    public let trafficService: TrafficFlowService
    
    public init(
        modelContext: ModelContext,
        eventService: DrawbridgeEventService? = nil,
        infoService: DrawbridgeInfoService? = nil,
        routeService: RouteService? = nil,
        trafficService: TrafficFlowService? = nil
    ) {
        self.modelContext = modelContext
        self.eventService = eventService ?? DrawbridgeEventService(modelContext: modelContext)
        self.infoService = infoService ?? DrawbridgeInfoService(modelContext: modelContext)
        self.routeService = routeService ?? RouteService(modelContext: modelContext)
        self.trafficService = trafficService ?? TrafficFlowService(modelContext: modelContext)
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
    
    private func refreshBridgeEvents(forceRefresh: Bool) async throws {
        do {
            // TODO: Replace with actual API call to Open Seattle API
            // Example implementation structure:
            /*
            let apiClient = OpenSeattleAPIClient()
            let newEvents = try await apiClient.fetchBridgeEvents(
                since: getLastEventDate(),
                limit: 1000
            )
            let events = newEvents.map { apiEvent in
                DrawbridgeEvent(
                    entityID: apiEvent.entityID,
                    entityName: apiEvent.entityName,
                    entityType: apiEvent.entityType,
                    openDateTime: apiEvent.openDateTime,
                    closeDateTime: apiEvent.closeDateTime,
                    duration: apiEvent.duration,
                    reason: apiEvent.reason
                )
            }
            
            // Save to SwiftData
            for event in events {
                modelContext.insert(event)
            }
            try modelContext.save()
            */
            
            // Placeholder implementation
            print("📊 DATA MANAGER: Bridge events refresh completed (placeholder)")
        } catch {
            print("📊 DATA MANAGER: Failed to refresh bridge events: \(error)")
            throw error
        }
    }
    
    private func refreshBridgeInfo(forceRefresh: Bool) async throws {
        do {
            // TODO: Replace with actual API call to Open Seattle API
            // Example implementation structure:
            /*
            let apiClient = OpenSeattleAPIClient()
            let bridgeInfo = try await apiClient.fetchBridgeInfo()
            
            // Save to SwiftData
            for info in bridgeInfo {
                modelContext.insert(info)
            }
            try modelContext.save()
            */
            
            // Placeholder implementation
            print("📊 DATA MANAGER: Bridge info refresh completed (placeholder)")
        } catch {
            print("📊 DATA MANAGER: Failed to refresh bridge info: \(error)")
            throw error
        }
    }
    
    private func refreshTrafficData(forceRefresh: Bool) async throws {
        do {
            // TODO: Replace with actual API call to Open Seattle API
            // Example implementation structure:
            /*
            let apiClient = OpenSeattleAPIClient()
            let trafficData = try await apiClient.fetchTrafficData()
            
            // Save to SwiftData
            for traffic in trafficData {
                modelContext.insert(traffic)
            }
            try modelContext.save()
            */
            
            // Placeholder implementation
            print("📊 DATA MANAGER: Traffic data refresh completed (placeholder)")
        } catch {
            print("📊 DATA MANAGER: Failed to refresh traffic data: \(error)")
            throw error
        }
    }
    
    // MARK: - Helper Methods for API Integration
    
    /// Get the most recent event date from SwiftData
    /// - Returns: The date of the most recent event, or nil if no events exist
    private func getLastEventDate() -> Date? {
        do {
            let descriptor = FetchDescriptor<DrawbridgeEvent>(
                sortBy: [SortDescriptor(\.openDateTime, order: .reverse)]
            )
            let events = try modelContext.fetch(descriptor)
            return events.first?.openDateTime
        } catch {
            print("📊 DATA MANAGER: Failed to get last event date: \(error)")
            return nil
        }
    }
    
    /// Get active bridge IDs from SwiftData
    /// - Returns: Array of bridge IDs that have recent events
    private func getActiveBridgeIDs() -> [String] {
        do {
            let descriptor = FetchDescriptor<DrawbridgeInfo>()
            let bridges = try modelContext.fetch(descriptor)
            return bridges.map { $0.entityID }
        } catch {
            print("📊 DATA MANAGER: Failed to get active bridge IDs: \(error)")
            return []
        }
    }
    
    /// Refresh all data from external APIs
    /// - Parameter forceRefresh: If true, force refresh even if data is recent
    public func refreshAllData(forceRefresh: Bool = false) async throws {
        // Runtime assertion to catch thread violations
        precondition(Thread.isMainThread, "refreshAllData must be called on main thread")
        
        print("📊 DATA MANAGER: Starting comprehensive data refresh")
        
        do {
            // Refresh bridge events
            try await refreshBridgeEvents(forceRefresh: forceRefresh)
            
            // Refresh bridge information
            try await refreshBridgeInfo(forceRefresh: forceRefresh)
            
            // Refresh traffic data
            try await refreshTrafficData(forceRefresh: forceRefresh)
            
            print("📊 DATA MANAGER: Comprehensive data refresh completed successfully")
        } catch {
            print("📊 DATA MANAGER: Failed to refresh all data: \(error)")
            throw error
        }
    }
    
    /// Get appropriate time window for traffic data requests
    /// - Returns: Time interval for traffic data requests
    private func getTrafficTimeWindow() -> TimeInterval {
        // Return 24 hours in seconds for traffic data requests
        return 24 * 60 * 60
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
    
    /// Get comprehensive statistics for all bridges
    public func getAllStatistics() async throws -> [String: Any] {
        print("📊 DATA MANAGER: Getting comprehensive statistics")
        
        do {
            let eventStats = try await eventService.getBridgeStatistics(for: "all")
            let routeStats = try await routeService.getRouteStatistics()
            let trafficStats = try await trafficService.getOverallTrafficStatistics()
            let bridgeStats = try await infoService.getBridgeStatistics()
            
            return [
                "events": eventStats,
                "routes": routeStats,
                "traffic": trafficStats,
                "bridges": bridgeStats
            ]
        } catch {
            print("📊 DATA MANAGER: Failed to get statistics: \(error)")
            throw error
        }
    }
    
    /// Get detailed information for a specific bridge
    public func getBridgeDetails(bridgeID: String) async throws -> [String: Any] {
        print("📊 DATA MANAGER: Getting details for bridge: \(bridgeID)")
        
        do {
            let bridgeInfo = try await infoService.fetchBridge(entityID: bridgeID)
            let events = try await eventService.fetchEvents(for: bridgeID)
            let trafficStats = try await trafficService.getTrafficStatistics(for: bridgeID)
            
            let affectedRoutes = try await routeService.getRoutesAffectedByBridgeOpening(bridgeID)
            
            return [
                "bridge": bridgeInfo,
                "events": events,
                "traffic": trafficStats,
                "affectedRoutes": affectedRoutes
            ]
        } catch {
            print("📊 DATA MANAGER: Failed to get bridge details: \(error)")
            throw error
        }
    }
    
    /// Get all data for export or backup
    public func getAllData() async throws -> [String: Any] {
        print("📊 DATA MANAGER: Getting all data for export")
        
        do {
            let events = try await eventService.fetchEvents()
            let bridgeIDs = Set(try await infoService.fetchAllBridges().map { $0.entityID })
            let trafficFlows = try await trafficService.fetchTrafficFlow()
            let routes = try await routeService.fetchRoutes()
            
            return [
                "events": events,
                "bridgeIDs": Array(bridgeIDs),
                "trafficFlows": trafficFlows,
                "routes": routes
            ]
        } catch {
            print("📊 DATA MANAGER: Failed to get all data: \(error)")
            throw error
        }
    }
    
    /// Get data summary for dashboard
    public func getDashboardData() async throws -> [String: Any] {
        print("📊 DATA MANAGER: Getting dashboard data")
        
        do {
            let events = try await eventService.fetchEvents()
            let bridges = try await infoService.fetchAllBridges()
            let routes = try await routeService.fetchRoutes()
            let trafficFlows = try await trafficService.fetchTrafficFlow()
            
            return [
                "events": events,
                "bridges": bridges,
                "routes": routes,
                "trafficFlows": trafficFlows
            ]
        } catch {
            print("📊 DATA MANAGER: Failed to get dashboard data: \(error)")
            throw error
        }
    }
} 