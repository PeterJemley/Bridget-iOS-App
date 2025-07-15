import Foundation
import SwiftData

@Observable
public final class DrawbridgeInfoService {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Fetch Operations
    
    /// Fetch all bridge information
    /// - Returns: Array of bridge information sorted by name
    public func fetchAllBridges() async throws -> [DrawbridgeInfo] {
        do {
            let descriptor = FetchDescriptor<DrawbridgeInfo>(
                sortBy: [SortDescriptor(\.entityName, order: .forward)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    /// Fetch a specific bridge by ID
    /// - Parameter entityID: The bridge ID to fetch
    /// - Returns: The bridge information if found, nil otherwise
    public func fetchBridge(entityID: String) async throws -> DrawbridgeInfo? {
        do {
            var descriptor = FetchDescriptor<DrawbridgeInfo>(
                predicate: #Predicate<DrawbridgeInfo> { bridge in
                    bridge.entityID == entityID
                }
            )
            descriptor.fetchLimit = 1
            
            let bridges = try modelContext.fetch(descriptor)
            return bridges.first
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    /// Fetch bridges by type
    /// - Parameter entityType: The bridge type to filter by
    /// - Returns: Array of bridges of the specified type
    public func fetchBridges(type entityType: String) async throws -> [DrawbridgeInfo] {
        do {
            let descriptor = FetchDescriptor<DrawbridgeInfo>(
                predicate: #Predicate<DrawbridgeInfo> { bridge in
                    bridge.entityType == entityType
                },
                sortBy: [SortDescriptor(\.entityName, order: .forward)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    /// Search bridges by name (case-insensitive)
    /// - Parameter searchTerm: The search term to match against bridge names
    /// - Returns: Array of bridges matching the search term
    public func searchBridges(name searchTerm: String) async throws -> [DrawbridgeInfo] {
        do {
            let descriptor = FetchDescriptor<DrawbridgeInfo>(
                predicate: #Predicate<DrawbridgeInfo> { bridge in
                    bridge.entityName.localizedStandardContains(searchTerm)
                },
                sortBy: [SortDescriptor(\.entityName, order: .forward)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    /// Fetch bridges within a geographic area
    /// - Parameters:
    ///   - centerLatitude: Center latitude of the search area
    ///   - centerLongitude: Center longitude of the search area
    ///   - radiusKm: Search radius in kilometers
    /// - Returns: Array of bridges within the specified radius
    public func fetchBridgesNearby(latitude centerLatitude: Double, longitude centerLongitude: Double, radiusKm: Double) async throws -> [DrawbridgeInfo] {
        do {
            // Convert radius from km to degrees (approximate)
            let radiusDegrees = radiusKm / 111.0
            
            let minLat = centerLatitude - radiusDegrees
            let maxLat = centerLatitude + radiusDegrees
            let minLon = centerLongitude - radiusDegrees
            let maxLon = centerLongitude + radiusDegrees
            
            let descriptor = FetchDescriptor<DrawbridgeInfo>(
                predicate: #Predicate<DrawbridgeInfo> { bridge in
                    bridge.latitude >= minLat && bridge.latitude <= maxLat &&
                    bridge.longitude >= minLon && bridge.longitude <= maxLon
                },
                sortBy: [SortDescriptor(\.entityName, order: .forward)]
            )
            
            let nearbyBridges = try modelContext.fetch(descriptor)
            
            // Filter by actual distance (more precise than bounding box)
            return nearbyBridges.filter { bridge in
                let distance = calculateDistance(
                    lat1: centerLatitude, lon1: centerLongitude,
                    lat2: bridge.latitude, lon2: bridge.longitude
                )
                return distance <= radiusKm
            }
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    // MARK: - Save Operations
    
    /// Save a new bridge information record
    /// - Parameter bridgeInfo: The bridge information to save
    public func saveBridge(_ bridgeInfo: DrawbridgeInfo) async throws {
        do {
            modelContext.insert(bridgeInfo)
            try modelContext.save()
        } catch {
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    /// Save multiple bridge information records in a batch
    /// - Parameter bridges: Array of bridge information to save
    public func saveBridges(_ bridges: [DrawbridgeInfo]) async throws {
        // Transactional block is preferred for atomicity, but if unavailable, fallback to single save after all inserts.
        // If any error occurs, no partial save is committed (SwiftData will throw before committing changes).
        // If transactional APIs become available, replace this with a transactional closure for true rollback.
        do {
            for bridge in bridges {
                modelContext.insert(bridge)
            }
            try modelContext.save()
        } catch {
            // At this point, if save fails, none of the bridges are persisted.
            // Recovery: The caller should retry or report the error to the user.
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    // MARK: - Update Operations
    
    /// Update an existing bridge information record
    /// - Parameter bridgeInfo: The bridge information to update
    public func updateBridge(_ bridgeInfo: DrawbridgeInfo) async throws {
        do {
            bridgeInfo.updatedAt = Date()
            try modelContext.save()
        } catch {
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    /// Update bridge location
    /// - Parameters:
    ///   - bridgeInfo: The bridge information to update
    ///   - latitude: New latitude
    ///   - longitude: New longitude
    public func updateBridgeLocation(_ bridgeInfo: DrawbridgeInfo, latitude: Double, longitude: Double) async throws {
        do {
            bridgeInfo.latitude = latitude
            bridgeInfo.longitude = longitude
            bridgeInfo.updatedAt = Date()
            try modelContext.save()
        } catch {
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete a bridge information record
    /// - Parameter bridgeInfo: The bridge information to delete
    public func deleteBridge(_ bridgeInfo: DrawbridgeInfo) async throws {
        do {
            modelContext.delete(bridgeInfo)
            try modelContext.save()
        } catch {
            throw BridgetDataError.deleteFailed(error)
        }
    }
    
    /// Delete a bridge by ID
    /// - Parameter entityID: The bridge ID to delete
    public func deleteBridge(entityID: String) async throws {
        do {
            if let bridge = try await fetchBridge(entityID: entityID) {
                modelContext.delete(bridge)
                try modelContext.save()
            }
        } catch {
            throw BridgetDataError.deleteFailed(error)
        }
    }
    
    /// Delete all bridge information
    public func deleteAllBridges() async throws {
        // Use SwiftData batch delete for efficiency (see documentation)
        try modelContext.delete(model: DrawbridgeInfo.self)
        try modelContext.save()
    }
    
    // MARK: - Analytics Operations
    
    /// Get bridge statistics
    /// - Returns: Dictionary with bridge statistics
    public func getBridgeStatistics() async throws -> [String: Any] {
        do {
            let allBridges = try await fetchAllBridges()
            
            let totalBridges = allBridges.count
            let bridgeTypes = Set(allBridges.map { $0.entityType })
            let uniqueTypes = bridgeTypes.count
            
            // Calculate geographic bounds
            let latitudes = allBridges.map { $0.latitude }
            let longitudes = allBridges.map { $0.longitude }
            
            let minLat = latitudes.min() ?? 0.0
            let maxLat = latitudes.max() ?? 0.0
            let minLon = longitudes.min() ?? 0.0
            let maxLon = longitudes.max() ?? 0.0
            
            return [
                "totalBridges": totalBridges,
                "uniqueTypes": uniqueTypes,
                "bridgeTypes": Array(bridgeTypes),
                "geographicBounds": [
                    "minLatitude": minLat,
                    "maxLatitude": maxLat,
                    "minLongitude": minLon,
                    "maxLongitude": maxLon
                ],
                "lastUpdated": allBridges.first?.updatedAt as Any
            ]
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    /// Get bridges by type statistics
    /// - Returns: Dictionary with bridge counts by type
    public func getBridgesByType() async throws -> [String: Int] {
        do {
            let allBridges = try await fetchAllBridges()
            var typeCounts: [String: Int] = [:]
            
            for bridge in allBridges {
                typeCounts[bridge.entityType, default: 0] += 1
            }
            
            return typeCounts
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    // MARK: - Utility Methods
    
    /// Calculate distance between two coordinates using Haversine formula
    /// - Parameters:
    ///   - lat1: Latitude of first point
    ///   - lon1: Longitude of first point
    ///   - lat2: Latitude of second point
    ///   - lon2: Longitude of second point
    /// - Returns: Distance in kilometers
    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius = 6371.0 // Earth's radius in kilometers
        
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0
        
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
                sin(dLon / 2) * sin(dLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
} 