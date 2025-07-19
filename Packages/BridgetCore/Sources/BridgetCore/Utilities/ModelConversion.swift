import Foundation
import SwiftData

// MARK: - Model to DTO Conversions

public extension DrawbridgeEvent {
    /// Convert DrawbridgeEvent to BridgeEventDTO
    /// - Returns: BridgeEventDTO representation
    
    func toDTO() -> BridgeEventDTO {
        BridgeEventDTO(from: self)
    }
}

public extension DrawbridgeInfo {
    /// Convert DrawbridgeInfo to BridgeInfoDTO
    /// - Returns: BridgeInfoDTO representation
    
    func toDTO() -> BridgeInfoDTO {
        BridgeInfoDTO(from: self)
    }
}

public extension Route {
    /// Convert Route to RouteDTO
    /// - Returns: RouteDTO representation
    
    func toDTO() -> RouteDTO {
        RouteDTO(from: self)
    }
}

public extension TrafficFlow {
    /// Convert TrafficFlow to TrafficFlowDTO
    /// - Returns: TrafficFlowDTO representation
    
    func toDTO() -> TrafficFlowDTO {
        TrafficFlowDTO(from: self)
    }
}

// MARK: - DTO to Model Conversions

public extension BridgeEventDTO {
    /// Convert BridgeEventDTO to DrawbridgeEvent model
    /// - Parameters:
    ///   - context: SwiftData ModelContext
    ///   - bridge: Associated DrawbridgeInfo model
    /// - Returns: DrawbridgeEvent model
    func toModel(in context: ModelContext, bridge: DrawbridgeInfo) -> DrawbridgeEvent {
        DrawbridgeEvent(
            id: id,
            entityID: entityID,
            entityName: entityName,
            entityType: entityType,
            bridge: bridge,
            openDateTime: openDateTime,
            closeDateTime: closeDateTime,
            minutesOpen: minutesOpen,
            latitude: latitude,
            longitude: longitude
        )
    }
    
    /// Convert BridgeEventDTO to DrawbridgeEvent model with bridge lookup
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: DrawbridgeEvent model or nil if bridge not found
    func toModel(in context: ModelContext) -> DrawbridgeEvent? {
        let bridgeDescriptor = FetchDescriptor<DrawbridgeInfo>(
            predicate: #Predicate { bridge in
                bridge.id == bridgeID
            }
        )
        
        guard let bridge = try? context.fetch(bridgeDescriptor).first else {
            return nil
        }
        
        return toModel(in: context, bridge: bridge)
    }
}

public extension BridgeInfoDTO {
    /// Convert BridgeInfoDTO to DrawbridgeInfo model
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: DrawbridgeInfo model
    func toModel(in context: ModelContext) -> DrawbridgeInfo {
        DrawbridgeInfo(
            id: id,
            entityID: entityID,
            entityName: entityName,
            entityType: entityType,
            latitude: latitude,
            longitude: longitude
        )
    }
}

public extension RouteDTO {
    /// Convert RouteDTO to Route model
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: Route model
    func toModel(in context: ModelContext) -> Route {
        Route(
            id: id,
            name: name,
            startLocation: startLocation,
            endLocation: endLocation,
            bridges: bridges,
            isFavorite: isFavorite
        )
    }
}

public extension TrafficFlowDTO {
    /// Convert TrafficFlowDTO to TrafficFlow model
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: TrafficFlow model
    func toModel(in context: ModelContext) -> TrafficFlow {
        TrafficFlow(
            id: id,
            bridgeID: bridgeID,
            timestamp: timestamp,
            congestionLevel: congestionLevel,
            trafficVolume: trafficVolume,
            correlationScore: correlationScore
        )
    }
}

// MARK: - Bulk Conversions

public extension Array where Element == DrawbridgeEvent {
    /// Convert array of DrawbridgeEvent to array of BridgeEventDTO
    /// - Returns: Array of BridgeEventDTO
    
    func toDTOs() -> [BridgeEventDTO] {
        map { $0.toDTO() }
    }
}

public extension Array where Element == DrawbridgeInfo {
    /// Convert array of DrawbridgeInfo to array of BridgeInfoDTO
    /// - Returns: Array of BridgeInfoDTO
    
    func toDTOs() -> [BridgeInfoDTO] {
        map { $0.toDTO() }
    }
}

public extension Array where Element == Route {
    /// Convert array of Route to array of RouteDTO
    /// - Returns: Array of RouteDTO
    
    func toDTOs() -> [RouteDTO] {
        map { $0.toDTO() }
    }
}

public extension Array where Element == TrafficFlow {
    /// Convert array of TrafficFlow to array of TrafficFlowDTO
    /// - Returns: Array of TrafficFlowDTO
    
    func toDTOs() -> [TrafficFlowDTO] {
        map { $0.toDTO() }
    }
}

public extension Array where Element == BridgeEventDTO {
    /// Convert array of BridgeEventDTO to array of DrawbridgeEvent models
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: Array of DrawbridgeEvent models (filtered to successful conversions)
    
    func toModels(in context: ModelContext) -> [DrawbridgeEvent] {
        compactMap { $0.toModel(in: context) }
    }
}

public extension Array where Element == BridgeInfoDTO {
    /// Convert array of BridgeInfoDTO to array of DrawbridgeInfo models
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: Array of DrawbridgeInfo models
    
    func toModels(in context: ModelContext) -> [DrawbridgeInfo] {
        map { $0.toModel(in: context) }
    }
}

public extension Array where Element == RouteDTO {
    /// Convert array of RouteDTO to array of Route models
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: Array of Route models
    
    func toModels(in context: ModelContext) -> [Route] {
        map { $0.toModel(in: context) }
    }
}

public extension Array where Element == TrafficFlowDTO {
    /// Convert array of TrafficFlowDTO to array of TrafficFlow models
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: Array of TrafficFlow models
    
    func toModels(in context: ModelContext) -> [TrafficFlow] {
        map { $0.toModel(in: context) }
    }
}

// MARK: - SyncData Conversions

public extension SyncDataDTO {
    /// Convert SyncDataDTO to individual model arrays
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: Tuple of model arrays
    
    func toModels(in context: ModelContext) -> (
        bridges: [DrawbridgeInfo],
        events: [DrawbridgeEvent],
        routes: [Route],
        trafficFlows: [TrafficFlow]
    ) {
        let bridgeModels = bridges.toModels(in: context)
        let routeModels = routes.toModels(in: context)
        let trafficFlowModels = trafficFlows.toModels(in: context)
        
        // For events, we need to ensure bridges exist first
        let eventModels = events.compactMap { eventDTO in
            eventDTO.toModel(in: context)
        }
        
        return (
            bridges: bridgeModels,
            events: eventModels,
            routes: routeModels,
            trafficFlows: trafficFlowModels
        )
    }
    
    /// Apply SyncDataDTO to ModelContext (insert all models)
    /// - Parameter context: SwiftData ModelContext
    /// - Returns: Number of models inserted
    
    func applyToContext(_ context: ModelContext) -> Int {
        let models = toModels(in: context)
        
        // Insert bridges first (events depend on them)
        models.bridges.forEach { context.insert($0) }
        
        // Insert events
        models.events.forEach { context.insert($0) }
        
        // Insert routes
        models.routes.forEach { context.insert($0) }
        
        // Insert traffic flows
        models.trafficFlows.forEach { context.insert($0) }
        
        return models.bridges.count + models.events.count + models.routes.count + models.trafficFlows.count
    }
}

// MARK: - ModelContext Extensions

public extension ModelContext {
    /// Convert all models in context to SyncDataDTO
    /// - Returns: SyncDataDTO with all models
    func toSyncDataDTO() throws -> SyncDataDTO {
        let bridgeDescriptor = FetchDescriptor<DrawbridgeInfo>()
        let eventDescriptor = FetchDescriptor<DrawbridgeEvent>()
        let routeDescriptor = FetchDescriptor<Route>()
        let trafficFlowDescriptor = FetchDescriptor<TrafficFlow>()
        
        let bridges = try fetch(bridgeDescriptor).toDTOs()
        let events = try fetch(eventDescriptor).toDTOs()
        let routes = try fetch(routeDescriptor).toDTOs()
        let trafficFlows = try fetch(trafficFlowDescriptor).toDTOs()
        
        return SyncDataDTO(
            bridges: bridges,
            events: events,
            routes: routes,
            trafficFlows: trafficFlows,
            syncTimestamp: Date(),
            source: "context"
        )
    }
    
    /// Clear all models from context
    /// - Returns: Number of models deleted
    func clearAllData() throws -> Int {
        let bridgeDescriptor = FetchDescriptor<DrawbridgeInfo>()
        let eventDescriptor = FetchDescriptor<DrawbridgeEvent>()
        let routeDescriptor = FetchDescriptor<Route>()
        let trafficFlowDescriptor = FetchDescriptor<TrafficFlow>()
        
        let bridges = try fetch(bridgeDescriptor)
        let events = try fetch(eventDescriptor)
        let routes = try fetch(routeDescriptor)
        let trafficFlows = try fetch(trafficFlowDescriptor)
        
        bridges.forEach { delete($0) }
        events.forEach { delete($0) }
        routes.forEach { delete($0) }
        trafficFlows.forEach { delete($0) }
        
        return bridges.count + events.count + routes.count + trafficFlows.count
    }
    
    /// Get model counts
    /// - Returns: Dictionary with model counts
    func getModelCounts() throws -> [String: Int] {
        let bridgeDescriptor = FetchDescriptor<DrawbridgeInfo>()
        let eventDescriptor = FetchDescriptor<DrawbridgeEvent>()
        let routeDescriptor = FetchDescriptor<Route>()
        let trafficFlowDescriptor = FetchDescriptor<TrafficFlow>()
        
        let bridgeCount = try fetch(bridgeDescriptor).count
        let eventCount = try fetch(eventDescriptor).count
        let routeCount = try fetch(routeDescriptor).count
        let trafficFlowCount = try fetch(trafficFlowDescriptor).count
        
        return [
            "bridges": bridgeCount,
            "events": eventCount,
            "routes": routeCount,
            "trafficFlows": trafficFlowCount
        ]
    }
}

// MARK: - Validation Utilities

public extension SyncDataDTO {
    /// Validate SyncDataDTO for consistency
    /// - Returns: Validation result
    func validate() -> DataValidationDTO {
        var errors: [String] = []
        var warnings: [String] = []
        var qualityScore = 1.0
        
        // Check for duplicate IDs
        let bridgeIDs = Set(bridges.map { $0.id })
        let eventIDs = Set(events.map { $0.id })
        let routeIDs = Set(routes.map { $0.id })
        let trafficFlowIDs = Set(trafficFlows.map { $0.id })
        
        if bridgeIDs.count != bridges.count {
            errors.append("Duplicate bridge IDs found")
            qualityScore -= 0.2
        }
        
        if eventIDs.count != events.count {
            errors.append("Duplicate event IDs found")
            qualityScore -= 0.2
        }
        
        if routeIDs.count != routes.count {
            errors.append("Duplicate route IDs found")
            qualityScore -= 0.2
        }
        
        if trafficFlowIDs.count != trafficFlows.count {
            errors.append("Duplicate traffic flow IDs found")
            qualityScore -= 0.2
        }
        
        // Check for orphaned events (events without corresponding bridges)
        let eventBridgeIDs = Set(events.map { $0.bridgeID })
        let missingBridges = eventBridgeIDs.subtracting(bridgeIDs)
        
        if !missingBridges.isEmpty {
            errors.append("Events reference non-existent bridges: \(missingBridges.count)")
            qualityScore -= 0.3
        }
        
        // Check for data freshness
        if isStale {
            warnings.append("Data is stale (older than 1 hour)")
            qualityScore -= 0.1
        }
        
        // Check for empty data
        if isEmpty {
            warnings.append("No data provided")
            qualityScore -= 0.1
        }
        
        // Ensure quality score is not negative
        qualityScore = max(0.0, qualityScore)
        
        return DataValidationDTO(
            isValid: errors.isEmpty,
            validationErrors: errors,
            warnings: warnings,
            dataQualityScore: qualityScore
        )
    }
}

// MARK: - Performance Utilities

public extension SyncDataDTO {
    /// Get estimated memory usage in bytes
    var estimatedMemoryUsage: Int {
        var total = 0
        
        // Rough estimates for each DTO type
        total += bridges.count * 256 // BridgeInfoDTO ~256 bytes
        total += events.count * 512  // BridgeEventDTO ~512 bytes
        total += routes.count * 128  // RouteDTO ~128 bytes
        total += trafficFlows.count * 192 // TrafficFlowDTO ~192 bytes
        
        return total
    }
    
    /// Get memory usage as display string
    var memoryUsageDisplay: String {
        let bytes = estimatedMemoryUsage
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }
    
    /// Check if data size is reasonable for processing
    var isReasonableSize: Bool {
        estimatedMemoryUsage < 10 * 1024 * 1024 // 10MB limit
    }
} 