import Foundation
import SwiftUI
import SwiftData
import BridgetCore

/// In-memory implementation of SeattleAPIProviding for unit and UI testing
/// Provides deterministic, API-driven behavior to test app logic as dictated by the API contract
@MainActor
class InMemorySeattleAPIService: ObservableObject {
    @Published var isLoading = false
    @Published var lastFetchDate: Date?
    
    // MARK: - Configurable Test Behavior
    
    /// Whether to simulate an error during fetch
    var shouldSimulateError = false
    
    /// The error to throw when shouldSimulateError is true
    var errorToThrow: Error = BridgetDataError.networkError(NSError(domain: "InMemory", code: 0, userInfo: [NSLocalizedDescriptionKey: "InMemory network error"]))
    
    /// Whether to simulate a delay during fetch (useful for testing loading states)
    var shouldSimulateDelay = false
    
    /// Delay duration in seconds when shouldSimulateDelay is true
    var delayDuration: TimeInterval = 1.0
    
    /// In-memory data to return when fetch succeeds
    var inMemoryBridges: [DrawbridgeInfo] = []
    var inMemoryEvents: [DrawbridgeEvent] = []
    
    // MARK: - Call Tracking
    
    /// Number of times fetchAndStoreAllData has been called
    private(set) var fetchCallCount = 0
    
    /// Reset call tracking for clean test state
    func resetCallTracking() {
        fetchCallCount = 0
    }
    
    // MARK: - SeattleAPIProviding Implementation
    
    func fetchAndStoreAllData(in modelContext: ModelContext) async throws {
        fetchCallCount += 1
        
        // Simulate loading state
        isLoading = true
        defer { isLoading = false }
        
        // Simulate delay if configured
        if shouldSimulateDelay {
            try await Task.sleep(nanoseconds: UInt64(delayDuration * 1_000_000_000))
        }
        
        // Simulate error if configured
        if shouldSimulateError {
            throw errorToThrow
        }
        
        // Simulate successful fetch
        try await simulateSuccessfulFetch(in: modelContext)
        
        // Update last fetch date
        lastFetchDate = Date()
    }
    
    // MARK: - Private Helper Methods
    
    private func simulateSuccessfulFetch(in modelContext: ModelContext) async throws {
        // Clear existing data
        try await clearExistingData(in: modelContext)
        
        // Insert in-memory bridges if provided
        if !inMemoryBridges.isEmpty {
            for bridge in inMemoryBridges {
                modelContext.insert(bridge)
            }
        }
        
        // Insert in-memory events if provided
        if !inMemoryEvents.isEmpty {
            for event in inMemoryEvents {
                modelContext.insert(event)
            }
        }
        
        // If no in-memory data provided, insert some default test data
        if inMemoryBridges.isEmpty && inMemoryEvents.isEmpty {
            try await insertDefaultTestData(in: modelContext)
        }
        
        try modelContext.save()
    }
    
    private func clearExistingData(in modelContext: ModelContext) async throws {
        // Delete existing events first (child objects)
        let eventDescriptor = FetchDescriptor<DrawbridgeEvent>()
        let existingEvents = try modelContext.fetch(eventDescriptor)
        for event in existingEvents {
            modelContext.delete(event)
        }
        
        // Delete existing bridges
        let bridgeDescriptor = FetchDescriptor<DrawbridgeInfo>()
        let existingBridges = try modelContext.fetch(bridgeDescriptor)
        for bridge in existingBridges {
            modelContext.delete(bridge)
        }
    }
    
    private func insertDefaultTestData(in modelContext: ModelContext) async throws {
        // Create a sample bridge
        let sampleBridge = DrawbridgeInfo(
            entityID: "TEST001",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            latitude: 47.6062,
            longitude: -122.3321
        )
        modelContext.insert(sampleBridge)
        
        // Create a sample event
        let sampleEvent = DrawbridgeEvent(
            entityID: "EVENT001",
            entityName: "Test Bridge",
            entityType: "drawbridge_event",
            bridge: sampleBridge,
            openDateTime: Date(),
            closeDateTime: Date().addingTimeInterval(3600), // 1 hour later
            minutesOpen: 60.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        modelContext.insert(sampleEvent)
    }
}

// MARK: - Convenience Initializers for Common Test Scenarios

extension InMemorySeattleAPIService {
    /// Create a service that always succeeds
    static func successService() -> InMemorySeattleAPIService {
        let service = InMemorySeattleAPIService()
        service.shouldSimulateError = false
        service.shouldSimulateDelay = false
        return service
    }
    /// Create a service that always fails with the specified error
    static func failureService(error: Error = BridgetDataError.networkError(NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Test error"]))) -> InMemorySeattleAPIService {
        let service = InMemorySeattleAPIService()
        service.shouldSimulateError = true
        service.errorToThrow = error
        service.shouldSimulateDelay = false
        return service
    }
    /// Create a service that simulates a slow network
    static func slowService(delay: TimeInterval = 2.0) -> InMemorySeattleAPIService {
        let service = InMemorySeattleAPIService()
        service.shouldSimulateError = false
        service.shouldSimulateDelay = true
        service.delayDuration = delay
        return service
    }
    /// Create a service with custom test data
    static func withCustomData(bridges: [DrawbridgeInfo], events: [DrawbridgeEvent]) -> InMemorySeattleAPIService {
        let service = InMemorySeattleAPIService()
        service.inMemoryBridges = bridges
        service.inMemoryEvents = events
        return service
    }
} 