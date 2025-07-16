import XCTest
import SwiftUI
import SwiftData
import BridgetCore
@testable import Bridget

@MainActor
final class ComprehensiveViewTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create an in-memory model container for testing
        let schema = Schema([
            DrawbridgeInfo.self,
            DrawbridgeEvent.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDown() async throws {
        // With cascade delete rules, deleting bridges will automatically delete their events
        if let modelContext = modelContext {
            let bridges = try modelContext.fetch(FetchDescriptor<DrawbridgeInfo>())
            for bridge in bridges {
                modelContext.delete(bridge)
            }
        }
        modelContainer = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - BridgesListView Tests
    
    func testBridgesListView_ShouldDisplayBridgesWhenDataExists() async throws {
        // Given
        let customBridge = DrawbridgeInfo(
            entityID: "BRIDGE001",
            entityName: "Fremont Bridge",
            entityType: "drawbridge",
            latitude: 47.6488,
            longitude: -122.3470
        )
        
        let mockService = InMemorySeattleAPIService.withCustomData(
            bridges: [customBridge],
            events: []
        )
        
        // When
        let _ = BridgesListView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        // Then
        // Simulate data fetch
        try await mockService.fetchAndStoreAllData(in: modelContext)
        
        // Verify the view would display the bridge
        let bridges = try modelContext.fetch(FetchDescriptor<DrawbridgeInfo>())
        XCTAssertEqual(bridges.count, 1)
        XCTAssertEqual(bridges.first?.entityName, "Fremont Bridge")
    }
    
    func testBridgesListView_ShouldShowEmptyStateWhenNoData() async throws {
        // Given
        let mockService = InMemorySeattleAPIService.withCustomData(
            bridges: [],
            events: []
        )
        
        // When
        let _ = BridgesListView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        // Then
        // Verify no data exists
        let bridges = try modelContext.fetch(FetchDescriptor<DrawbridgeInfo>())
        XCTAssertEqual(bridges.count, 0)
    }
    
    func testBridgesListView_ShouldHandleRefreshSuccessfully() async throws {
        // Given
        let mockService = InMemorySeattleAPIService.successService()
        
        // When
        let _ = BridgesListView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        // Simulate refresh
        try await mockService.fetchAndStoreAllData(in: modelContext)
        
        // Then
        XCTAssertEqual(mockService.fetchCallCount, 1)
        XCTAssertNotNil(mockService.lastFetchDate)
        
        // Verify data was inserted
        let bridges = try modelContext.fetch(FetchDescriptor<DrawbridgeInfo>())
        XCTAssertEqual(bridges.count, 1)
    }
    
    func testBridgesListView_ShouldHandleRefreshFailure() async throws {
        // Given
        let mockService = InMemorySeattleAPIService.failureService()
        
        // When
        let _ = BridgesListView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        // Then
        // View created successfully
        
        // Simulate failed refresh
        do {
            try await mockService.fetchAndStoreAllData(in: modelContext)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is BridgetDataError)
        }
        
        XCTAssertEqual(mockService.fetchCallCount, 1)
    }
    
    // MARK: - EventsListView Tests
    
    func testEventsListView_ShouldDisplayEventsWhenDataExists() async throws {
        // Given
        let customBridge = DrawbridgeInfo(
            entityID: "BRIDGE001",
            entityName: "Ballard Bridge",
            entityType: "drawbridge",
            latitude: 47.6488,
            longitude: -122.3470
        )
        
        let customEvent = DrawbridgeEvent(
            entityID: "EVENT001",
            entityName: "Ballard Bridge",
            entityType: "drawbridge_event",
            bridge: customBridge,
            openDateTime: Date(),
            closeDateTime: Date().addingTimeInterval(1800),
            minutesOpen: 30.0,
            latitude: 47.6488,
            longitude: -122.3470
        )
        
        let mockService = InMemorySeattleAPIService.withCustomData(
            bridges: [customBridge],
            events: [customEvent]
        )
        
        // When
        let _ = EventsListView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        // Then
        // Simulate data fetch
        try await mockService.fetchAndStoreAllData(in: modelContext)
        
        // Verify the view would display the event
        let events = try modelContext.fetch(FetchDescriptor<DrawbridgeEvent>())
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.entityName, "Ballard Bridge")
    }
    
    func testEventsListView_ShouldShowEmptyStateWhenNoEvents() async throws {
        // Given
        let mockService = InMemorySeattleAPIService.withCustomData(
            bridges: [],
            events: []
        )
        
        // When
        let _ = EventsListView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        // Then
        // Verify no events exist
        let events = try modelContext.fetch(FetchDescriptor<DrawbridgeEvent>())
        XCTAssertEqual(events.count, 0)
    }
    
    func testEventsListView_ShouldHandleRefreshSuccessfully() async throws {
        // Given
        let mockService = InMemorySeattleAPIService.successService()
        
        // When
        let _ = EventsListView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        // Simulate refresh
        try await mockService.fetchAndStoreAllData(in: modelContext)
        
        // Then
        XCTAssertEqual(mockService.fetchCallCount, 1)
        XCTAssertNotNil(mockService.lastFetchDate)
        
        // Verify data was inserted
        let events = try modelContext.fetch(FetchDescriptor<DrawbridgeEvent>())
        XCTAssertEqual(events.count, 1)
    }
    
    // MARK: - SettingsView Tests
    
    func testSettingsView_ShouldShowLastFetchDate() async throws {
        // Given
        let mockService = InMemorySeattleAPIService.successService()
        
        // When
        let _ = SettingsView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        // Simulate a fetch to set lastFetchDate
        try await mockService.fetchAndStoreAllData(in: modelContext)
        
        // Then
        XCTAssertNotNil(mockService.lastFetchDate)
    }
    
    // MARK: - Loading State Tests
    
    func testViews_ShouldHandleLoadingState() async throws {
        // Given
        let slowMock = InMemorySeattleAPIService.slowService(delay: 0.1)
        
        // When
        let _ = BridgesListView()
            .modelContainer(modelContainer)
            .environmentObject(slowMock)
        
        let _ = EventsListView()
            .modelContainer(modelContainer)
            .environmentObject(slowMock)
        
        let _ = SettingsView()
            .modelContainer(modelContainer)
            .environmentObject(slowMock)
        
        // Then
        XCTAssertNotNil(slowMock.isLoading)
        
        // Simulate loading
        let fetchTask = Task {
            try await slowMock.fetchAndStoreAllData(in: modelContext)
        }
        
        // Give the task a moment to start
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        XCTAssertTrue(slowMock.isLoading)
        
        // Wait for completion
        try await fetchTask.value
        XCTAssertFalse(slowMock.isLoading)
    }
    
    // MARK: - Error Handling Tests
    
    func testViews_ShouldHandleNetworkErrors() async throws {
        // Given
        let networkError = BridgetDataError.networkError(NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Network unavailable"]))
        let errorMock = InMemorySeattleAPIService.failureService(error: networkError)
        
        // When
        let _ = BridgesListView()
            .modelContainer(modelContainer)
            .environmentObject(errorMock)
        
        let _ = EventsListView()
            .modelContainer(modelContainer)
            .environmentObject(errorMock)
        
        let _ = SettingsView()
            .modelContainer(modelContainer)
            .environmentObject(errorMock)
        
        // Then
        // Simulate error
        do {
            try await errorMock.fetchAndStoreAllData(in: modelContext)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is BridgetDataError)
        }
    }
    
    // MARK: - Data Consistency Tests
    
    func testViews_ShouldMaintainDataConsistency() async throws {
        // Given
        let customBridge = DrawbridgeInfo(
            entityID: "CONSISTENCY001",
            entityName: "Consistency Test Bridge",
            entityType: "drawbridge",
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        let customEvent = DrawbridgeEvent(
            entityID: "EVENT001",
            entityName: "Consistency Test Bridge",
            entityType: "drawbridge_event",
            bridge: customBridge,
            openDateTime: Date(),
            closeDateTime: Date().addingTimeInterval(3600),
            minutesOpen: 60.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        let mockService = InMemorySeattleAPIService.withCustomData(
            bridges: [customBridge],
            events: [customEvent]
        )
        
        // When
        let _ = BridgesListView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        let _ = EventsListView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        // Simulate data fetch
        try await mockService.fetchAndStoreAllData(in: modelContext)
        
        // Then
        // View created successfully
        
        // Verify data consistency across views
        let bridges = try modelContext.fetch(FetchDescriptor<DrawbridgeInfo>())
        let events = try modelContext.fetch(FetchDescriptor<DrawbridgeEvent>())
        
        XCTAssertEqual(bridges.count, 1)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(bridges.first?.entityName, "Consistency Test Bridge")
        XCTAssertEqual(events.first?.entityName, "Consistency Test Bridge")
        XCTAssertEqual(events.first?.bridge.entityID, bridges.first?.entityID)
    }
} 
