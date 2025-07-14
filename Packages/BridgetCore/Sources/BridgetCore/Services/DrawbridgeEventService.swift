import Foundation
import SwiftData

public protocol DrawbridgeEventServiceProtocol {
    func fetchEvents(for bridgeID: String?) async throws -> [DrawbridgeEvent]
    func saveEvent(_ event: DrawbridgeEvent) async throws
    func deleteEvent(_ event: DrawbridgeEvent) async throws
    func updateEvent(_ event: DrawbridgeEvent) async throws
}

public class DrawbridgeEventService: DrawbridgeEventServiceProtocol {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func fetchEvents(for bridgeID: String? = nil) async throws -> [DrawbridgeEvent] {
        let descriptor = FetchDescriptor<DrawbridgeEvent>(
            predicate: bridgeID.map { bridgeID in
                #Predicate<DrawbridgeEvent> { event in
                    event.entityID == bridgeID
                }
            },
            sortBy: [SortDescriptor(\.openDateTime, order: .reverse)]
        )
        descriptor.fetchLimit = 100

        return try modelContext.fetch(descriptor)
    }

    public func saveEvent(_ event: DrawbridgeEvent) async throws {
        modelContext.insert(event)
        try modelContext.save()
    }

    public func deleteEvent(_ event: DrawbridgeEvent) async throws {
        modelContext.delete(event)
        try modelContext.save()
    }

    public func updateEvent(_ event: DrawbridgeEvent) async throws {
        event.updatedAt = Date()
        try modelContext.save()
    }
} 