import XCTest
import SwiftUI
import SwiftData
import BridgetCore
@testable import Bridget

@MainActor
final class InMemorySeattleAPIServiceTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var mockService: InMemorySeattleAPIService!
    
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
        mockService = InMemorySeattleAPIService()
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        mockService = nil
        try await super.tearDown()
    }
    
    // MARK: - Success Tests
    
    func testSuccessMock_ShouldCompleteWithoutError() async throws {
        // Given
        let successMock = InMemorySeattleAPIService.successService()
        
        // When
        try await successMock.fetchAndStoreAllData(in: modelContext)
        
        // Then
        XCTAssertFalse(successMock.isLoading)
        XCTAssertNotNil(successMock.lastFetchDate)
        XCTAssertEqual(successMock.fetchCallCount, 1)
    }
    
    func testSuccessMock_ShouldInsertDefaultTestData() async throws {
        // Given
        let successMock = InMemorySeattleAPIService.successService()
        
        // When
        try await successMock.fetchAndStoreAllData(in: modelContext)
        
        // Then
        let bridges = try modelContext.fetch(FetchDescriptor<DrawbridgeInfo>())
        let events = try modelContext.fetch(FetchDescriptor<DrawbridgeEvent>())
        
        XCTAssertEqual(bridges.count, 1)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(bridges.first?.entityName, "Test Bridge")
        XCTAssertEqual(events.first?.entityName, "Test Bridge")
    }
    
    // MARK: - Failure Tests
    
    func testFailureMock_ShouldThrowConfiguredError() async throws {
        // Given
        let customError = BridgetDataError.networkError(NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Custom test error"]))
        let failureMock = InMemorySeattleAPIService.failureService(error: customError)
        
        // When & Then
        do {
            try await failureMock.fetchAndStoreAllData(in: modelContext)
            XCTFail("Expected error to be thrown")
        } catch {
            // Verify the error was thrown (we can't easily compare BridgetDataError instances)
            XCTAssertTrue(error is BridgetDataError)
        }
        
        XCTAssertFalse(failureMock.isLoading)
        XCTAssertEqual(failureMock.fetchCallCount, 1)
    }
    
    // MARK: - Slow Network Tests
    
    func testSlowMock_ShouldSimulateDelay() async throws {
        // Given
        let delayDuration: TimeInterval = 0.1 // Short delay for testing
        let slowMock = InMemorySeattleAPIService.slowService(delay: delayDuration)
        
        // When
        let startTime = Date()
        try await slowMock.fetchAndStoreAllData(in: modelContext)
        let endTime = Date()
        
        // Then
        let actualDuration = endTime.timeIntervalSince(startTime)
        XCTAssertGreaterThanOrEqual(actualDuration, delayDuration)
        XCTAssertFalse(slowMock.isLoading)
        XCTAssertEqual(slowMock.fetchCallCount, 1)
    }
    
    // MARK: - Custom Data Tests
    
    func testWithCustomData_ShouldInsertProvidedData() async throws {
        // Given
        let customBridge = DrawbridgeInfo(
            entityID: "CUSTOM001",
            entityName: "Custom Bridge",
            entityType: "drawbridge",
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        let customEvent = DrawbridgeEvent(
            entityID: "EVENT001",
            entityName: "Custom Bridge",
            entityType: "drawbridge_event",
            bridge: customBridge,
            openDateTime: Date(),
            closeDateTime: Date().addingTimeInterval(1800), // 30 minutes later
            minutesOpen: 30.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        let customDataMock = InMemorySeattleAPIService.withCustomData(
            bridges: [customBridge],
            events: [customEvent]
        )
        
        // When
        try await customDataMock.fetchAndStoreAllData(in: modelContext)
        
        // Then
        let bridges = try modelContext.fetch(FetchDescriptor<DrawbridgeInfo>())
        let events = try modelContext.fetch(FetchDescriptor<DrawbridgeEvent>())
        
        XCTAssertEqual(bridges.count, 1)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(bridges.first?.entityName, "Custom Bridge")
        XCTAssertEqual(events.first?.entityName, "Custom Bridge")
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingState_ShouldBeTrueDuringFetch() async throws {
        // Given
        let slowMock = InMemorySeattleAPIService.slowService(delay: 0.1)
        
        // When
        let fetchTask = Task {
            try await slowMock.fetchAndStoreAllData(in: modelContext)
        }
        
        // Give the task a moment to start
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Then
        XCTAssertTrue(slowMock.isLoading)
        
        // Wait for completion
        try await fetchTask.value
        XCTAssertFalse(slowMock.isLoading)
    }
    
    // MARK: - Call Tracking Tests
    
    func testCallTracking_ShouldIncrementOnEachCall() async throws {
        // Given
        let mock = InMemorySeattleAPIService.successService()
        
        // When
        try await mock.fetchAndStoreAllData(in: modelContext)
        try await mock.fetchAndStoreAllData(in: modelContext)
        try await mock.fetchAndStoreAllData(in: modelContext)
        
        // Then
        XCTAssertEqual(mock.fetchCallCount, 3)
    }
    
    func testResetCallTracking_ShouldResetToZero() async throws {
        // Given
        let mock = InMemorySeattleAPIService.successService()
        try await mock.fetchAndStoreAllData(in: modelContext)
        XCTAssertEqual(mock.fetchCallCount, 1)
        
        // When
        mock.resetCallTracking()
        
        // Then
        XCTAssertEqual(mock.fetchCallCount, 0)
    }
    
    // MARK: - Data Clearing Tests
    
    func testDataClearing_ShouldRemoveExistingData() async throws {
        // Given
        let existingBridge = DrawbridgeInfo(
            entityID: "EXISTING001",
            entityName: "Existing Bridge",
            entityType: "drawbridge",
            latitude: 47.6062,
            longitude: -122.3321
        )
        modelContext.insert(existingBridge)
        try modelContext.save()
        
        let mock = InMemorySeattleAPIService.successService()
        
        // When
        try await mock.fetchAndStoreAllData(in: modelContext)
        
        // Then
        let bridges = try modelContext.fetch(FetchDescriptor<DrawbridgeInfo>())
        XCTAssertEqual(bridges.count, 1) // Should have the new test data, not the old
        XCTAssertEqual(bridges.first?.entityName, "Test Bridge")
    }
} 