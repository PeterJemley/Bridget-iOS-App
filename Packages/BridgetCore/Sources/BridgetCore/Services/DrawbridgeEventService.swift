import Foundation
import SwiftData

@MainActor
public class DrawbridgeEventService {
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
        let events = try await fetchEvents(for: entityID)
        let filtered = events.filter { $0.openDateTime >= from && $0.openDateTime <= to }
        
        // Group by day using Calendar
        var counts: [Date: Int] = [:]
        let calendar = Calendar.current
        
        for event in filtered {
            // Get start of day for the event
            let dayStart = calendar.startOfDay(for: event.openDateTime)
            counts[dayStart, default: 0] += 1
        }
        
        return counts
    }

    /// Returns average, median, and percentile range of event durations by day for a given window and optional bridge.
    /// - Parameters:
    ///   - from: Start date (inclusive)
    ///   - to: End date (inclusive)
    ///   - entityID: Optional bridge ID to filter events
    /// - Returns: [Date: (average, median, p25, p75, tailRisk)]
    /// - Note: Use ranges and percentiles for user-facing stats.
    public func averageDurationByDay(from: Date, to: Date, entityID: String? = nil) async throws -> [Date: (average: Double, median: Double, p25: Double, p75: Double, tailRisk: Double)] {
        let events = try await fetchEvents(for: entityID)
        let filtered = events.filter { 
            $0.openDateTime >= from && 
            $0.openDateTime <= to && 
            $0.closeDateTime != nil 
        }
        
        // Group by day
        var dayGroups: [Date: [Double]] = [:]
        let calendar = Calendar.current
        
        for event in filtered {
            let dayStart = calendar.startOfDay(for: event.openDateTime)
            dayGroups[dayStart, default: []].append(event.minutesOpen)
        }
        
        // Calculate statistics for each day
        var results: [Date: (average: Double, median: Double, p25: Double, p75: Double, tailRisk: Double)] = [:]
        
        for (day, durations) in dayGroups {
            let sortedDurations = durations.sorted()
            let count = sortedDurations.count
            
            guard count > 0 else { continue }
            
            let average = sortedDurations.reduce(0, +) / Double(count)
            let median = calculatePercentile(sortedDurations, percentile: 0.5)
            let p25 = calculatePercentile(sortedDurations, percentile: 0.25)
            let p75 = calculatePercentile(sortedDurations, percentile: 0.75)
            let tailRisk = calculatePercentile(sortedDurations, percentile: 0.95)
            
            results[day] = (average: average, median: median, p25: p25, p75: p75, tailRisk: tailRisk)
        }
        
        return results
    }

    /// Returns average, median, and percentile range of event durations by week for a given window and optional bridge.
    /// - Parameters:
    ///   - from: Start date (inclusive)
    ///   - to: End date (inclusive)
    ///   - entityID: Optional bridge ID to filter events
    /// - Returns: [weekStartDate: (average, median, p25, p75, tailRisk)]
    public func averageDurationByWeek(from: Date, to: Date, entityID: String? = nil) async throws -> [Date: (average: Double, median: Double, p25: Double, p75: Double, tailRisk: Double)] {
        let events = try await fetchEvents(for: entityID)
        let filtered = events.filter { 
            $0.openDateTime >= from && 
            $0.openDateTime <= to && 
            $0.closeDateTime != nil 
        }
        
        // Group by week
        var weekGroups: [Date: [Double]] = [:]
        let calendar = Calendar.current
        
        for event in filtered {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: event.openDateTime)?.start ?? event.openDateTime
            weekGroups[weekStart, default: []].append(event.minutesOpen)
        }
        
        // Calculate statistics for each week
        var results: [Date: (average: Double, median: Double, p25: Double, p75: Double, tailRisk: Double)] = [:]
        
        for (weekStart, durations) in weekGroups {
            let sortedDurations = durations.sorted()
            let count = sortedDurations.count
            
            guard count > 0 else { continue }
            
            let average = sortedDurations.reduce(0, +) / Double(count)
            let median = calculatePercentile(sortedDurations, percentile: 0.5)
            let p25 = calculatePercentile(sortedDurations, percentile: 0.25)
            let p75 = calculatePercentile(sortedDurations, percentile: 0.75)
            let tailRisk = calculatePercentile(sortedDurations, percentile: 0.95)
            
            results[weekStart] = (average: average, median: median, p25: p25, p75: p75, tailRisk: tailRisk)
        }
        
        return results
    }

    /// Returns a dictionary of event counts by month for a given window and optional bridge, with annotation for low-N months.
    /// - Parameters:
    ///   - from: Start date (inclusive)
    ///   - to: End date (inclusive)
    ///   - entityID: Optional bridge ID to filter events
    /// - Returns: [monthStartDate: (count, isLowN: Bool)]
    public func monthlyEventCounts(from: Date, to: Date, entityID: String? = nil) async throws -> [Date: (count: Int, isLowN: Bool)] {
        let events = try await fetchEvents(for: entityID)
        let filtered = events.filter { $0.openDateTime >= from && $0.openDateTime <= to }
        
        // Group by month
        var monthGroups: [Date: Int] = [:]
        let calendar = Calendar.current
        
        for event in filtered {
            let monthStart = calendar.dateInterval(of: .month, for: event.openDateTime)?.start ?? event.openDateTime
            monthGroups[monthStart, default: 0] += 1
        }
        
        // Determine low-N threshold (less than 5 events per month)
        let lowNThreshold = 5
        
        var results: [Date: (count: Int, isLowN: Bool)] = [:]
        for (monthStart, count) in monthGroups {
            results[monthStart] = (count: count, isLowN: count < lowNThreshold)
        }
        
        return results
    }

    /// Returns per-bridge stats (frequency, average/median duration, impact label) for a given window.
    /// - Parameters:
    ///   - from: Start date (inclusive)
    ///   - to: End date (inclusive)
    /// - Returns: [bridgeID: (frequency: Double, average: Double, median: Double, impactLabel: String, eventCount: Int)]
    /// - Note: Suppress or annotate stats for bridges with very few events.
    public func perBridgeStats(from: Date, to: Date) async throws -> [String: (frequency: Double, average: Double, median: Double, impactLabel: String, eventCount: Int)] {
        let events = try await fetchEvents(for: nil) // Get all events
        let filtered = events.filter { 
            $0.openDateTime >= from && 
            $0.openDateTime <= to && 
            $0.closeDateTime != nil 
        }
        
        // Group by bridge
        var bridgeGroups: [String: [Double]] = [:]
        for event in filtered {
            bridgeGroups[event.entityID, default: []].append(event.minutesOpen)
        }
        
        // Calculate statistics for each bridge
        var results: [String: (frequency: Double, average: Double, median: Double, impactLabel: String, eventCount: Int)] = [:]
        let totalDays = Calendar.current.dateComponents([.day], from: from, to: to).day ?? 1
        
        for (bridgeID, durations) in bridgeGroups {
            let eventCount = durations.count
            
            // Skip bridges with very few events (less than 3)
            guard eventCount >= 3 else { continue }
            
            let sortedDurations = durations.sorted()
            let frequency = Double(eventCount) / Double(totalDays)
            let average = sortedDurations.reduce(0, +) / Double(eventCount)
            let median = calculatePercentile(sortedDurations, percentile: 0.5)
            
            // Determine impact label based on frequency and duration
            let impactLabel = determineImpactLabel(frequency: frequency, averageDuration: average, eventCount: eventCount)
            
            results[bridgeID] = (
                frequency: frequency,
                average: average,
                median: median,
                impactLabel: impactLabel,
                eventCount: eventCount
            )
        }
        
        return results
    }
    
    // MARK: - Helper Methods
    
    /// Calculate percentile from sorted array
    /// - Parameters:
    ///   - sortedArray: Sorted array of values
    ///   - percentile: Percentile to calculate (0.0 to 1.0)
    /// - Returns: Percentile value
    private func calculatePercentile(_ sortedArray: [Double], percentile: Double) -> Double {
        guard !sortedArray.isEmpty else { return 0.0 }
        
        let index = percentile * Double(sortedArray.count - 1)
        let lowerIndex = Int(floor(index))
        let upperIndex = min(lowerIndex + 1, sortedArray.count - 1)
        
        if lowerIndex == upperIndex {
            return sortedArray[lowerIndex]
        }
        
        let weight = index - Double(lowerIndex)
        return sortedArray[lowerIndex] * (1 - weight) + sortedArray[upperIndex] * weight
    }
    
    /// Determine impact label based on frequency and duration
    /// - Parameters:
    ///   - frequency: Events per day
    ///   - averageDuration: Average duration in minutes
    ///   - eventCount: Total number of events
    /// - Returns: Impact label string
    private func determineImpactLabel(frequency: Double, averageDuration: Double, eventCount: Int) -> String {
        // High impact: frequent events (>0.5/day) or long duration (>30 min average)
        if frequency > 0.5 || averageDuration > 30 {
            return "High Impact"
        }
        
        // Medium impact: moderate frequency (0.1-0.5/day) or moderate duration (15-30 min)
        if frequency > 0.1 || averageDuration > 15 {
            return "Medium Impact"
        }
        
        // Low impact: infrequent events (<0.1/day) and short duration (<15 min)
        return "Low Impact"
    }
} 