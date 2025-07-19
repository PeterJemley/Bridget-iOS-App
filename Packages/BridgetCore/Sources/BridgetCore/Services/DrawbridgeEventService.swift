import Foundation
import SwiftData

@Observable
public final class DrawbridgeEventService {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Fetch Operations
    
    /// Fetch all drawbridge events, optionally filtered by bridge ID
    /// - Parameter entityID: Optional bridge ID to filter events
    /// - Returns: Array of drawbridge events sorted by open date (newest first)
    public func fetchEvents(for entityID: String? = nil) async throws -> [DrawbridgeEvent] {
        do {
            var descriptor = FetchDescriptor<DrawbridgeEvent>(
                predicate: entityID != nil ? #Predicate { event in
                    event.entityID == entityID!
                } : nil,
                sortBy: [SortDescriptor(\.openDateTime, order: .reverse)]
            )
            descriptor.fetchLimit = 100
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    /// Fetch recent events within a time range
    /// - Parameters:
    ///   - since: Start date for filtering
    ///   - entityID: Optional bridge ID to filter events
    /// - Returns: Array of drawbridge events within the time range
    public func fetchRecentEvents(since: Date, entityID: String? = nil) async throws -> [DrawbridgeEvent] {
        do {
            let predicate: Predicate<DrawbridgeEvent>
            
            if let entityID = entityID {
                predicate = #Predicate { event in
                    event.entityID == entityID && event.openDateTime >= since
                }
            } else {
                predicate = #Predicate { event in
                    event.openDateTime >= since
                }
            }
            
            let descriptor = FetchDescriptor<DrawbridgeEvent>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.openDateTime, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    /// Fetch currently open bridges (events without close date)
    /// - Returns: Array of currently open drawbridge events
    public func fetchOpenBridges() async throws -> [DrawbridgeEvent] {
        do {
            let descriptor = FetchDescriptor<DrawbridgeEvent>(
                predicate: #Predicate { event in
                    event.closeDateTime == nil
                },
                sortBy: [SortDescriptor(\.openDateTime, order: .reverse)]
            )
            
            return try modelContext.fetch(descriptor)
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    // MARK: - Save Operations
    
    /// Save a new drawbridge event
    /// - Parameter event: The drawbridge event to save
    public func saveEvent(_ event: DrawbridgeEvent) async throws {
        do {
            modelContext.insert(event)
            try modelContext.save()
        } catch {
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    /// Save multiple drawbridge events in a batch
    /// - Parameter events: Array of drawbridge events to save
    public func saveEvents(_ events: [DrawbridgeEvent]) async throws {
        // Transactional block is preferred for atomicity, but if unavailable, fallback to single save after all inserts.
        // If any error occurs, no partial save is committed (SwiftData will throw before committing changes).
        // If transactional APIs become available, replace this with a transactional closure for true rollback.
        do {
            for event in events {
                modelContext.insert(event)
            }
            try modelContext.save()
        } catch {
            // At this point, if save fails, none of the events are persisted.
            // Recovery: The caller should retry or report the error to the user.
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    // MARK: - Update Operations
    
    /// Update an existing drawbridge event
    /// - Parameter event: The drawbridge event to update
    public func updateEvent(_ event: DrawbridgeEvent) async throws {
        do {
            try modelContext.save()
        } catch {
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    /// Close a bridge event by setting the close date
    /// - Parameters:
    ///   - event: The drawbridge event to close
    ///   - closeDate: The date when the bridge closed
    public func closeBridgeEvent(_ event: DrawbridgeEvent, closeDate: Date) async throws {
        do {
            event.closeDateTime = closeDate
            event.minutesOpen = closeDate.timeIntervalSince(event.openDateTime) / 60.0
            try modelContext.save()
        } catch {
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete a drawbridge event
    /// - Parameter event: The drawbridge event to delete
    public func deleteEvent(_ event: DrawbridgeEvent) async throws {
        do {
            modelContext.delete(event)
            try modelContext.save()
        } catch {
            throw BridgetDataError.deleteFailed(error)
        }
    }
    
    /// Delete all events for a specific bridge
    /// - Parameter entityID: The bridge ID to delete events for
    public func deleteEvents(for entityID: String) async throws {
        // Use SwiftData batch delete for efficiency (see documentation)
        try modelContext.delete(model: DrawbridgeEvent.self, where: #Predicate { event in
            event.entityID == entityID
        })
        try modelContext.save()
    }
    
    /// Delete events older than a specified date
    /// - Parameter date: Events older than this date will be deleted
    public func deleteEventsOlderThan(_ date: Date) async throws {
        // Use SwiftData batch delete for efficiency (see documentation)
        try modelContext.delete(model: DrawbridgeEvent.self, where: #Predicate { event in
            event.openDateTime < date
        })
        try modelContext.save()
    }
    
    // MARK: - Analytics Operations
    
    /// Get bridge opening statistics for a specific bridge
    /// - Parameter entityID: The bridge ID to get statistics for
    /// - Returns: Dictionary with statistics (total openings, average duration, etc.)
    public func getBridgeStatistics(for entityID: String) async throws -> [String: Any] {
        do {
            let events = try await fetchEvents(for: entityID)
            
            let totalOpenings = events.count
            let completedEvents = events.filter { $0.closeDateTime != nil }
            let averageDuration = completedEvents.isEmpty ? 0.0 : 
                completedEvents.reduce(0.0) { $0 + $1.minutesOpen } / Double(completedEvents.count)
            
            return [
                "totalOpenings": totalOpenings,
                "completedOpenings": completedEvents.count,
                "averageDuration": averageDuration,
                "lastOpening": events.first?.openDateTime as Any
            ]
        } catch {
            throw BridgetDataError.fetchFailed(error)
        }
    }
    
    // MARK: - Dashboard Insight Data Queries

    /// Returns a dictionary of event counts by hour for a given date window and optional bridge.
    /// - Parameters:
    ///   - from: Start date (inclusive)
    ///   - to: End date (inclusive)
    ///   - entityID: Optional bridge ID to filter events
    /// - Returns: [hour: count] for the specified window
    /// - Note: Always specify the time window in the UI (e.g., "last 30 days").
    public func eventCountsByHour(from: Date, to: Date, entityID: String? = nil) async throws -> [Int: Int] {
        // Fetch events in the date window, optionally filtered by bridge
        let events = try await fetchEvents(for: entityID)
        let filtered = events.filter { $0.openDateTime >= from && $0.openDateTime <= to }
        
        // Group by hour (0-23)
        var counts: [Int: Int] = [:]
        let calendar = Calendar.current
        for event in filtered {
            let hour = calendar.component(.hour, from: event.openDateTime)
            counts[hour, default: 0] += 1
        }
        // Ensure all 24 hours are present for UI consistency
        for hour in 0..<24 {
            counts[hour] = counts[hour, default: 0]
        }
        return counts
    }

    /// Returns a dictionary of event counts by day for a given date window and optional bridge.
    /// - Parameters:
    ///   - from: Start date (inclusive)
    ///   - to: End date (inclusive)
    ///   - entityID: Optional bridge ID to filter events
    /// - Returns: [Date: count] for the specified window
    public func eventCountsByDay(from: Date, to: Date, entityID: String? = nil) async throws -> [Date: Int] {
        // TODO: Implement grouping by day, counting events, and returning a dictionary
        // Use Calendar to extract day from openDateTime
        return [:]
    }

    /// Returns average, median, and percentile range of event durations by day for a given window and optional bridge.
    /// - Parameters:
    ///   - from: Start date (inclusive)
    ///   - to: End date (inclusive)
    ///   - entityID: Optional bridge ID to filter events
    /// - Returns: [Date: (average, median, p25, p75, tailRisk)]
    /// - Note: Use ranges and percentiles for user-facing stats.
    public func averageDurationByDay(from: Date, to: Date, entityID: String? = nil) async throws -> [Date: (average: Double, median: Double, p25: Double, p75: Double, tailRisk: Double)] {
        // TODO: Implement grouping by day, compute stats for completed events
        return [:]
    }

    /// Returns average, median, and percentile range of event durations by week for a given window and optional bridge.
    /// - Parameters:
    ///   - from: Start date (inclusive)
    ///   - to: End date (inclusive)
    ///   - entityID: Optional bridge ID to filter events
    /// - Returns: [weekStartDate: (average, median, p25, p75, tailRisk)]
    public func averageDurationByWeek(from: Date, to: Date, entityID: String? = nil) async throws -> [Date: (average: Double, median: Double, p25: Double, p75: Double, tailRisk: Double)] {
        // TODO: Implement grouping by week, compute stats for completed events
        return [:]
    }

    /// Returns a dictionary of event counts by month for a given window and optional bridge, with annotation for low-N months.
    /// - Parameters:
    ///   - from: Start date (inclusive)
    ///   - to: End date (inclusive)
    ///   - entityID: Optional bridge ID to filter events
    /// - Returns: [monthStartDate: (count, isLowN: Bool)]
    public func monthlyEventCounts(from: Date, to: Date, entityID: String? = nil) async throws -> [Date: (count: Int, isLowN: Bool)] {
        // TODO: Implement grouping by month, count events, flag low-N months
        return [:]
    }

    /// Returns per-bridge stats (frequency, average/median duration, impact label) for a given window.
    /// - Parameters:
    ///   - from: Start date (inclusive)
    ///   - to: End date (inclusive)
    /// - Returns: [bridgeID: (frequency: Double, average: Double, median: Double, impactLabel: String, eventCount: Int)]
    /// - Note: Suppress or annotate stats for bridges with very few events.
    public func perBridgeStats(from: Date, to: Date) async throws -> [String: (frequency: Double, average: Double, median: Double, impactLabel: String, eventCount: Int)] {
        // TODO: Implement per-bridge aggregation, label impact, handle small-N
        return [:]
    }
} 