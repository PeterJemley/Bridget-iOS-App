import Foundation
import SwiftUI
import SwiftData
import BridgetCore

/// Mock implementation of SeattleAPIProviding for unit and UI testing
/// Provides configurable behavior to test different scenarios
@MainActor
class MockSeattleAPIService: ObservableObject {
    @Published var isLoading = false
    @Published var lastFetchDate: Date?
    
    // MARK: - Configurable Test Behavior
    
    /// Whether to simulate an error during fetch
    var shouldSimulateError = false
    
    /// The error to throw when shouldSimulateError is true
    var errorToThrow: Error = BridgetDataError.networkError(NSError(domain: "Mock", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mock network error"]))
    
    /// Whether to simulate a delay during fetch (useful for testing loading states)
    var shouldSimulateDelay = false
    
    /// Delay duration in seconds when shouldSimulateDelay is true
    var delayDuration: TimeInterval = 1.0
    
    /// Mock data to return when fetch succeeds
    var mockBridges: [DrawbridgeInfo] = []
    var mockEvents: [DrawbridgeEvent] = []
    
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
        
        // Insert mock bridges if provided
        if !mockBridges.isEmpty {
            for bridge in mockBridges {
                modelContext.insert(bridge)
            }
        }
        
        // Insert mock events if provided
        if !mockEvents.isEmpty {
            for event in mockEvents {
                modelContext.insert(event)
            }
        }
        
        // If no mock data provided, insert some default test data
        if mockBridges.isEmpty && mockEvents.isEmpty {
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

extension MockSeattleAPIService {
    
    /// Create a mock service that always succeeds
    static func successMock() -> MockSeattleAPIService {
        let mock = MockSeattleAPIService()
        mock.shouldSimulateError = false
        mock.shouldSimulateDelay = false
        return mock
    }
    
    /// Create a mock service that always fails with the specified error
    static func failureMock(error: Error = BridgetDataError.networkError(NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Test error"]))) -> MockSeattleAPIService {
        let mock = MockSeattleAPIService()
        mock.shouldSimulateError = true
        mock.errorToThrow = error
        mock.shouldSimulateDelay = false
        return mock
    }
    
    /// Create a mock service that simulates a slow network
    static func slowMock(delay: TimeInterval = 2.0) -> MockSeattleAPIService {
        let mock = MockSeattleAPIService()
        mock.shouldSimulateError = false
        mock.shouldSimulateDelay = true
        mock.delayDuration = delay
        return mock
    }
    
    /// Create a mock service with custom test data
    static func withCustomData(bridges: [DrawbridgeInfo], events: [DrawbridgeEvent]) -> MockSeattleAPIService {
        let mock = MockSeattleAPIService()
        mock.mockBridges = bridges
        mock.mockEvents = events
        return mock
    }
} 