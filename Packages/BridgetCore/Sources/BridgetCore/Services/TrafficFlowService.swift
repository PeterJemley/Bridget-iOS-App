import Foundation
import SwiftData

@Observable
public final class TrafficFlowService {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Fetch Operations
    
    /// Fetch all traffic flow data, optionally filtered by bridge ID
    /// - Parameter bridgeID: Optional bridge ID to filter traffic data
    /// - Returns: Array of traffic flow data sorted by timestamp (newest first)
    public func fetchTrafficFlow(bridgeID: String? = nil) async throws -> [TrafficFlow] {
        do {
            var descriptor = FetchDescriptor<TrafficFlow>(
                predicate: bridgeID != nil ? #Predicate<TrafficFlow> { flow in
                    flow.bridgeID == bridgeID!
                } : nil,
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            descriptor.fetchLimit = 1000
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    /// Fetch traffic flow data within a time range
    /// - Parameters:
    ///   - since: Start date for filtering
    ///   - bridgeID: Optional bridge ID to filter traffic data
    /// - Returns: Array of traffic flow data within the time range
    public func fetchTrafficFlow(since: Date, bridgeID: String? = nil) async throws -> [TrafficFlow] {
        do {
            let predicate: Predicate<TrafficFlow>
            
            if let bridgeID = bridgeID {
                predicate = #Predicate<TrafficFlow> { flow in
                    flow.bridgeID == bridgeID && flow.timestamp >= since
                }
            } else {
                predicate = #Predicate<TrafficFlow> { flow in
                    flow.timestamp >= since
                }
            }
            
            let descriptor = FetchDescriptor<TrafficFlow>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    /// Fetch the most recent traffic flow data for a specific bridge
    /// - Parameter bridgeID: The bridge ID to get recent traffic data for
    /// - Returns: The most recent traffic flow data for the bridge
    public func fetchLatestTrafficFlow(for bridgeID: String) async throws -> TrafficFlow? {
        do {
            var descriptor = FetchDescriptor<TrafficFlow>(
                predicate: #Predicate<TrafficFlow> { flow in
                    flow.bridgeID == bridgeID
                },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            descriptor.fetchLimit = 1
            
            let flows = try modelContext.fetch(descriptor)
            return flows.first
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    /// Fetch traffic flow data with high congestion levels
    /// - Parameter threshold: Minimum congestion level to filter by
    /// - Returns: Array of traffic flow data with congestion above the threshold
    public func fetchHighCongestionTraffic(threshold: Double = 0.7) async throws -> [TrafficFlow] {
        do {
            let descriptor = FetchDescriptor<TrafficFlow>(
                predicate: #Predicate<TrafficFlow> { flow in
                    flow.congestionLevel >= threshold
                },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    // MARK: - Save Operations
    
    /// Save a new traffic flow record
    /// - Parameter trafficFlow: The traffic flow data to save
    public func saveTrafficFlow(_ trafficFlow: TrafficFlow) async throws {
        do {
            modelContext.insert(trafficFlow)
            try modelContext.save()
        } catch {
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    /// Save multiple traffic flow records in a batch
    /// - Parameter trafficFlows: Array of traffic flow data to save
    public func saveTrafficFlows(_ trafficFlows: [TrafficFlow]) async throws {
        // Transactional block is preferred for atomicity, but if unavailable, fallback to single save after all inserts.
        // If any error occurs, no partial save is committed (SwiftData will throw before committing changes).
        // If transactional APIs become available, replace this with a transactional closure for true rollback.
        do {
            for flow in trafficFlows {
                modelContext.insert(flow)
            }
            try modelContext.save()
        } catch {
            // At this point, if save fails, none of the flows are persisted.
            // Recovery: The caller should retry or report the error to the user.
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    // MARK: - Update Operations
    
    /// Update an existing traffic flow record
    /// - Parameter trafficFlow: The traffic flow data to update
    public func updateTrafficFlow(_ trafficFlow: TrafficFlow) async throws {
        do {
            try modelContext.save()
        } catch {
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    /// Update correlation score for a traffic flow record
    /// - Parameters:
    ///   - trafficFlow: The traffic flow record to update
    ///   - correlationScore: The new correlation score
    public func updateCorrelationScore(_ trafficFlow: TrafficFlow, correlationScore: Double) async throws {
        do {
            trafficFlow.correlationScore = correlationScore
            try modelContext.save()
        } catch {
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete a traffic flow record
    /// - Parameter trafficFlow: The traffic flow record to delete
    public func deleteTrafficFlow(_ trafficFlow: TrafficFlow) async throws {
        do {
            modelContext.delete(trafficFlow)
            try modelContext.save()
        } catch {
            throw BridgetDataError.deleteFailed(error)
        }
    }
    
    /// Delete all traffic flow data for a specific bridge
    /// - Parameter bridgeID: The bridge ID to delete traffic data for
    public func deleteTrafficFlow(for bridgeID: String) async throws {
        // Use SwiftData batch delete for efficiency (see documentation)
        try modelContext.delete(model: TrafficFlow.self, where: #Predicate { $0.bridgeID == bridgeID })
        try modelContext.save()
    }
    
    /// Delete traffic flow data older than a specified date
    /// - Parameter date: Traffic data older than this date will be deleted
    public func deleteTrafficFlowOlderThan(_ date: Date) async throws {
        // Use SwiftData batch delete for efficiency (see documentation)
        try modelContext.delete(model: TrafficFlow.self, where: #Predicate { $0.timestamp < date })
        try modelContext.save()
    }
    
    // MARK: - Analytics Operations
    
    /// Get traffic statistics for a specific bridge
    /// - Parameter bridgeID: The bridge ID to get statistics for
    /// - Returns: Dictionary with traffic statistics
    public func getTrafficStatistics(for bridgeID: String) async throws -> [String: Any] {
        do {
            let flows = try await fetchTrafficFlow(bridgeID: bridgeID)
            
            let totalRecords = flows.count
            let averageCongestion = flows.isEmpty ? 0.0 : 
                flows.reduce(0.0) { $0 + $1.congestionLevel } / Double(flows.count)
            let averageVolume = flows.isEmpty ? 0.0 : 
                flows.reduce(0.0) { $0 + $1.trafficVolume } / Double(flows.count)
            let averageCorrelation = flows.isEmpty ? 0.0 : 
                flows.reduce(0.0) { $0 + $1.correlationScore } / Double(flows.count)
            
            let highCongestionCount = flows.filter { $0.congestionLevel >= 0.7 }.count
            
            return [
                "totalRecords": totalRecords,
                "averageCongestion": averageCongestion,
                "averageVolume": averageVolume,
                "averageCorrelation": averageCorrelation,
                "highCongestionCount": highCongestionCount,
                "lastRecord": flows.first?.timestamp as Any
            ]
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    /// Get overall traffic statistics
    /// - Returns: Dictionary with overall traffic statistics
    public func getOverallTrafficStatistics() async throws -> [String: Any] {
        do {
            let allFlows = try await fetchTrafficFlow()
            
            let totalRecords = allFlows.count
            let uniqueBridges = Set(allFlows.map { $0.bridgeID }).count
            let averageCongestion = allFlows.isEmpty ? 0.0 : 
                allFlows.reduce(0.0) { $0 + $1.congestionLevel } / Double(allFlows.count)
            let averageVolume = allFlows.isEmpty ? 0.0 : 
                allFlows.reduce(0.0) { $0 + $1.trafficVolume } / Double(allFlows.count)
            
            return [
                "totalRecords": totalRecords,
                "uniqueBridges": uniqueBridges,
                "averageCongestion": averageCongestion,
                "averageVolume": averageVolume,
                "lastRecord": allFlows.first?.timestamp as Any
            ]
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    /// Predict traffic congestion for a bridge based on historical data
    /// - Parameter bridgeID: The bridge ID to predict traffic for
    /// - Returns: Predicted congestion level (0.0 to 1.0)
    public func predictCongestion(for bridgeID: String) async throws -> Double {
        do {
            let recentFlows = try await fetchTrafficFlow(since: Calendar.current.date(byAdding: .hour, value: -24, to: Date()) ?? Date(), bridgeID: bridgeID)
            
            if recentFlows.isEmpty {
                return 0.5 // Default prediction if no data
            }
            
            // Simple prediction based on recent average and trend
            let recentAverage = recentFlows.reduce(0.0) { $0 + $1.congestionLevel } / Double(recentFlows.count)
            
            // Calculate trend (simple linear regression)
            let sortedFlows = recentFlows.sorted { $0.timestamp < $1.timestamp }
            if sortedFlows.count >= 2 {
                let firstHalf = Array(sortedFlows.prefix(sortedFlows.count / 2))
                let secondHalf = Array(sortedFlows.suffix(sortedFlows.count / 2))
                
                let firstHalfAvg = firstHalf.reduce(0.0) { $0 + $1.congestionLevel } / Double(firstHalf.count)
                let secondHalfAvg = secondHalf.reduce(0.0) { $0 + $1.congestionLevel } / Double(secondHalf.count)
                
                let trend = secondHalfAvg - firstHalfAvg
                let prediction = recentAverage + (trend * 0.5) // Extrapolate trend
                
                return max(0.0, min(1.0, prediction)) // Clamp between 0 and 1
            }
            
            return recentAverage
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
} 