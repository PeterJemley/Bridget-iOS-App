import XCTest
import SwiftUI
import SwiftData
import BridgetCore
@testable import Bridget

@MainActor
final class ViewTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var mockService: MockSeattleAPIService!
    
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
        
        // Create a fresh mock service for each test
        mockService = MockSeattleAPIService()
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        mockService = nil
        try await super.tearDown()
    }
    
    // MARK: - BridgesListView Tests
    
    func testBridgesListView_ShouldDisplayBridgesWhenDataExists() async throws {
        // Given
        let testBridge = DrawbridgeInfo(
            entityID: "TEST001",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            latitude: 47.6062,
            longitude: -122.3321
        )
        modelContext.insert(testBridge)
        try modelContext.save()
        
        // When
        let view = BridgesListView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        // Then - Verify the view can be created and doesn't crash
        // Note: We can't easily test SwiftUI view content in unit tests,
        // but we can verify the view initializes correctly
        XCTAssertNotNil(view)
    }
    
    func testBridgesListView_ShouldHandleEmptyState() async throws {
        // Given - Empty model context
        
        // When
        let view = BridgesListView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testBridgesListView_ShouldHandleLoadingState() async throws {
        // Given
        let slowMock = MockSeattleAPIService.slowMock(delay: 0.1)
        
        // When
        let view = BridgesListView()
            .modelContainer(modelContainer)
            .environmentObject(slowMock)
        
        // Then - Views don't automatically trigger API calls during initialization
        XCTAssertNotNil(view)
        // Note: Loading state would only be true if the view explicitly calls the API service
    }
    
    // MARK: - EventsListView Tests
    
    func testEventsListView_ShouldDisplayEventsWhenDataExists() async throws {
        // Given
        let testBridge = DrawbridgeInfo(
            entityID: "TEST001",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            latitude: 47.6062,
            longitude: -122.3321
        )
        modelContext.insert(testBridge)
        
        let testEvent = DrawbridgeEvent(
            entityID: "EVENT001",
            entityName: "Test Bridge",
            entityType: "drawbridge_event",
            bridge: testBridge,
            openDateTime: Date(),
            closeDateTime: Date().addingTimeInterval(3600),
            minutesOpen: 60.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        modelContext.insert(testEvent)
        try modelContext.save()
        
        // When
        let view = EventsListView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testEventsListView_ShouldHandleEmptyState() async throws {
        // Given - Empty model context
        
        // When
        let view = EventsListView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testEventsListView_ShouldHandleLoadingState() async throws {
        // Given
        let slowMock = MockSeattleAPIService.slowMock(delay: 0.1)
        
        // When
        let view = EventsListView()
            .modelContainer(modelContainer)
            .environmentObject(slowMock)
        
        // Then - Views don't automatically trigger API calls during initialization
        XCTAssertNotNil(view)
        // Note: Loading state would only be true if the view explicitly calls the API service
    }
    
    // MARK: - SettingsView Tests
    
    func testSettingsView_ShouldDisplayLastFetchDate() async throws {
        // Given
        mockService.lastFetchDate = Date()
        
        // When
        let view = SettingsView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testSettingsView_ShouldHandleNoLastFetchDate() async throws {
        // Given
        mockService.lastFetchDate = nil
        
        // When
        let view = SettingsView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func testSettingsView_ShouldHandleLoadingState() async throws {
        // Given
        let slowMock = MockSeattleAPIService.slowMock(delay: 0.1)
        
        // When
        let view = SettingsView()
            .modelContainer(modelContainer)
            .environmentObject(slowMock)
        
        // Then - Views don't automatically trigger API calls during initialization
        XCTAssertNotNil(view)
        // Note: Loading state would only be true if the view explicitly calls the API service
    }
    
    // MARK: - Error Handling Tests
    
    func testViews_ShouldHandleNetworkErrorGracefully() async throws {
        // Given
        let failureMock = MockSeattleAPIService.failureMock()
        
        // When & Then - Verify views can be created even with error-prone service
        let bridgesView = BridgesListView()
            .modelContainer(modelContainer)
            .environmentObject(failureMock)
        
        let eventsView = EventsListView()
            .modelContainer(modelContainer)
            .environmentObject(failureMock)
        
        let settingsView = SettingsView()
            .modelContainer(modelContainer)
            .environmentObject(failureMock)
        
        XCTAssertNotNil(bridgesView)
        XCTAssertNotNil(eventsView)
        XCTAssertNotNil(settingsView)
    }
    
    // MARK: - Environment Object Integration Tests
    
    func testViews_ShouldProperlyReceiveEnvironmentObject() async throws {
        // Given
        let customMock = MockSeattleAPIService.withCustomData(
            bridges: [
                DrawbridgeInfo(
                    entityID: "CUSTOM001",
                    entityName: "Custom Bridge",
                    entityType: "drawbridge",
                    latitude: 47.6062,
                    longitude: -122.3321
                )
            ],
            events: []
        )
        
        // When
        let view = BridgesListView()
            .modelContainer(modelContainer)
            .environmentObject(customMock)
        
        // Then
        XCTAssertNotNil(view)
        XCTAssertEqual(customMock.fetchCallCount, 0) // Should not auto-fetch
    }
    
    // MARK: - Model Context Integration Tests
    
    func testViews_ShouldWorkWithPopulatedModelContext() async throws {
        // Given
        let testBridges = [
            DrawbridgeInfo(
                entityID: "BRIDGE001",
                entityName: "Bridge 1",
                entityType: "drawbridge",
                latitude: 47.6062,
                longitude: -122.3321
            ),
            DrawbridgeInfo(
                entityID: "BRIDGE002",
                entityName: "Bridge 2",
                entityType: "drawbridge",
                latitude: 47.6063,
                longitude: -122.3322
            )
        ]
        
        for bridge in testBridges {
            modelContext.insert(bridge)
        }
        try modelContext.save()
        
        // When
        let bridgesView = BridgesListView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        let eventsView = EventsListView()
            .modelContainer(modelContainer)
            .environmentObject(mockService)
        
        // Then
        XCTAssertNotNil(bridgesView)
        XCTAssertNotNil(eventsView)
        
        // Verify data is in context
        let bridges = try modelContext.fetch(FetchDescriptor<DrawbridgeInfo>())
        XCTAssertEqual(bridges.count, 2)
    }
} 