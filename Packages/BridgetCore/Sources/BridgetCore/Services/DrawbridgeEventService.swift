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
                predicate: entityID != nil ? #Predicate<DrawbridgeEvent> { event in
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
                predicate = #Predicate<DrawbridgeEvent> { event in
                    event.entityID == entityID && event.openDateTime >= since
                }
            } else {
                predicate = #Predicate<DrawbridgeEvent> { event in
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
                predicate: #Predicate<DrawbridgeEvent> { event in
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
        do {
            for event in events {
                modelContext.insert(event)
            }
            try modelContext.save()
        } catch {
            throw BridgetDataError.saveFailed(error)
        }
    }
    
    // MARK: - Update Operations
    
    /// Update an existing drawbridge event
    /// - Parameter event: The drawbridge event to update
    public func updateEvent(_ event: DrawbridgeEvent) async throws {
        do {
            event.updatedAt = Date()
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
            event.updatedAt = Date()
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
        do {
            let events = try await fetchEvents(for: entityID)
            for event in events {
                modelContext.delete(event)
            }
            try modelContext.save()
        } catch {
            throw BridgetDataError.deleteFailed(error)
        }
    }
    
    /// Delete events older than a specified date
    /// - Parameter date: Events older than this date will be deleted
    public func deleteEventsOlderThan(_ date: Date) async throws {
        do {
            let descriptor = FetchDescriptor<DrawbridgeEvent>(
                predicate: #Predicate<DrawbridgeEvent> { event in
                    event.openDateTime < date
                }
            )
            
            let events = try modelContext.fetch(descriptor)
            for event in events {
                modelContext.delete(event)
            }
            try modelContext.save()
        } catch {
            throw BridgetDataError.deleteFailed(error)
        }
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
} 