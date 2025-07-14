import Foundation
import SwiftData

@Observable
public final class RouteService {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Fetch Operations
    
    /// Fetch all routes, optionally filtered by favorite status
    /// - Parameter favoritesOnly: If true, only return favorite routes
    /// - Returns: Array of routes sorted by creation date (newest first)
    public func fetchRoutes(favoritesOnly: Bool = false) async throws -> [Route] {
        do {
            let descriptor = FetchDescriptor<Route>(
                predicate: favoritesOnly ? #Predicate<Route> { route in
                    route.isFavorite == true
                } : nil,
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    /// Fetch a specific route by ID
    /// - Parameter id: The route ID to fetch
    /// - Returns: The route if found, nil otherwise
    public func fetchRoute(id: UUID) async throws -> Route? {
        do {
            let descriptor = FetchDescriptor<Route>(
                predicate: #Predicate<Route> { route in
                    route.id == id
                }
            )
            descriptor.fetchLimit = 1
            
            let routes = try modelContext.fetch(descriptor)
            return routes.first
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    /// Fetch routes that contain a specific bridge
    /// - Parameter bridgeID: The bridge ID to search for in routes
    /// - Returns: Array of routes containing the specified bridge
    public func fetchRoutesContaining(bridgeID: String) async throws -> [Route] {
        do {
            let descriptor = FetchDescriptor<Route>(
                predicate: #Predicate<Route> { route in
                    route.bridges.contains(bridgeID)
                },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    // MARK: - Save Operations
    
    /// Save a new route
    /// - Parameter route: The route to save
    public func saveRoute(_ route: Route) async throws {
        do {
            modelContext.insert(route)
            try modelContext.save()
        } catch {
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    /// Save multiple routes in a batch
    /// - Parameter routes: Array of routes to save
    public func saveRoutes(_ routes: [Route]) async throws {
        do {
            for route in routes {
                modelContext.insert(route)
            }
            try modelContext.save()
        } catch {
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    // MARK: - Update Operations
    
    /// Update an existing route
    /// - Parameter route: The route to update
    public func updateRoute(_ route: Route) async throws {
        do {
            route.updatedAt = Date()
            try modelContext.save()
        } catch {
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    /// Toggle favorite status for a route
    /// - Parameter route: The route to toggle favorite status
    public func toggleFavorite(_ route: Route) async throws {
        do {
            route.isFavorite.toggle()
            route.updatedAt = Date()
            try modelContext.save()
        } catch {
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    /// Add a bridge to a route
    /// - Parameters:
    ///   - route: The route to add the bridge to
    ///   - bridgeID: The bridge ID to add
    public func addBridgeToRoute(_ route: Route, bridgeID: String) async throws {
        do {
            if !route.bridges.contains(bridgeID) {
                route.bridges.append(bridgeID)
                route.updatedAt = Date()
                try modelContext.save()
            }
        } catch {
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    /// Remove a bridge from a route
    /// - Parameters:
    ///   - route: The route to remove the bridge from
    ///   - bridgeID: The bridge ID to remove
    public func removeBridgeFromRoute(_ route: Route, bridgeID: String) async throws {
        do {
            route.bridges.removeAll { $0 == bridgeID }
            route.updatedAt = Date()
            try modelContext.save()
        } catch {
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete a route
    /// - Parameter route: The route to delete
    public func deleteRoute(_ route: Route) async throws {
        do {
            modelContext.delete(route)
            try modelContext.save()
        } catch {
            throw BridgetDataError.deleteFailed(error)
        }
    }
    
    /// Delete a route by ID
    /// - Parameter id: The route ID to delete
    public func deleteRoute(id: UUID) async throws {
        do {
            if let route = try await fetchRoute(id: id) {
                modelContext.delete(route)
                try modelContext.save()
            }
        } catch {
            throw BridgetDataError.deleteFailed(error)
        }
    }
    
    /// Delete all routes
    public func deleteAllRoutes() async throws {
        do {
            let routes = try await fetchRoutes()
            for route in routes {
                modelContext.delete(route)
            }
            try modelContext.save()
        } catch {
            throw BridgetDataError.deleteFailed(error)
        }
    }
    
    // MARK: - Analytics Operations
    
    /// Get route statistics
    /// - Returns: Dictionary with route statistics
    public func getRouteStatistics() async throws -> [String: Any] {
        do {
            let allRoutes = try await fetchRoutes()
            let favoriteRoutes = try await fetchRoutes(favoritesOnly: true)
            
            let totalBridges = allRoutes.reduce(0) { $0 + $1.bridges.count }
            let averageBridgesPerRoute = allRoutes.isEmpty ? 0.0 : Double(totalBridges) / Double(allRoutes.count)
            
            return [
                "totalRoutes": allRoutes.count,
                "favoriteRoutes": favoriteRoutes.count,
                "totalBridges": totalBridges,
                "averageBridgesPerRoute": averageBridgesPerRoute,
                "mostRecentRoute": allRoutes.first?.createdAt
            ]
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    /// Get routes that might be affected by a bridge opening
    /// - Parameter bridgeID: The bridge ID that is opening
    /// - Returns: Array of routes that contain the specified bridge
    public func getRoutesAffectedByBridgeOpening(_ bridgeID: String) async throws -> [Route] {
        return try await fetchRoutesContaining(bridgeID: bridgeID)
    }
} 