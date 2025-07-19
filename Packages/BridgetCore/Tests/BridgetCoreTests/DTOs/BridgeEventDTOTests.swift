import XCTest
import SwiftData
@testable import BridgetCore

@MainActor
final class BridgeEventDTOTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: DrawbridgeInfo.self, DrawbridgeEvent.self, Route.self, TrafficFlow.self, configurations: config)
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDownWithError() throws {
        modelContext = nil
        modelContainer = nil
    }
    
    // MARK: - Initialization Tests
    
    func testBridgeEventDTOInitialization() {
        let bridgeID = UUID()
        let openDateTime = Date()
        let closeDateTime = openDateTime.addingTimeInterval(3600) // 1 hour later
        
        let dto = BridgeEventDTO(
            entityID: "test-bridge-1",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            bridgeID: bridgeID,
            openDateTime: openDateTime,
            closeDateTime: closeDateTime,
            minutesOpen: 60.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        XCTAssertEqual(dto.entityID, "test-bridge-1")
        XCTAssertEqual(dto.entityName, "Test Bridge")
        XCTAssertEqual(dto.entityType, "drawbridge")
        XCTAssertEqual(dto.bridgeID, bridgeID)
        XCTAssertEqual(dto.openDateTime, openDateTime)
        XCTAssertEqual(dto.closeDateTime, closeDateTime)
        XCTAssertEqual(dto.minutesOpen, 60.0)
        XCTAssertEqual(dto.latitude, 47.6062)
        XCTAssertEqual(dto.longitude, -122.3321)
        XCTAssertFalse(dto.isCurrentlyOpen)
    }
    
    func testBridgeEventDTOFromModel() throws {
        // Create a bridge first
        let bridge = DrawbridgeInfo(
            entityID: "test-bridge-1",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            latitude: 47.6062,
            longitude: -122.3321
        )
        modelContext.insert(bridge)
        
        // Create an event
        let openDateTime = Date()
        let event = DrawbridgeEvent(
            entityID: "test-event-1",
            entityName: "Test Event",
            entityType: "drawbridge",
            bridge: bridge,
            openDateTime: openDateTime,
            closeDateTime: nil,
            minutesOpen: 0.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        modelContext.insert(event)
        
        // Convert to DTO
        let dto = event.toDTO()
        
        XCTAssertEqual(dto.id, event.id)
        XCTAssertEqual(dto.entityID, event.entityID)
        XCTAssertEqual(dto.entityName, event.entityName)
        XCTAssertEqual(dto.entityType, event.entityType)
        XCTAssertEqual(dto.bridgeID, bridge.id)
        XCTAssertEqual(dto.openDateTime, event.openDateTime)
        XCTAssertEqual(dto.closeDateTime, event.closeDateTime)
        XCTAssertEqual(dto.minutesOpen, event.minutesOpen)
        XCTAssertEqual(dto.latitude, event.latitude)
        XCTAssertEqual(dto.longitude, event.longitude)
        XCTAssertTrue(dto.isCurrentlyOpen)
    }
    
    // MARK: - Sendable Compliance Tests
    
    func testBridgeEventDTOSendableCompliance() async {
        let dto = BridgeEventDTO(
            entityID: "test-bridge-1",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            bridgeID: UUID(),
            openDateTime: Date(),
            closeDateTime: nil,
            minutesOpen: 0.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        // This should compile without Sendable errors
        let _: BridgeEventDTO = await Task.detached {
            return dto
        }.value
        
        XCTAssertNotNil(dto)
    }
    
    // MARK: - Convenience Properties Tests
    
    func testIsCurrentlyOpen() {
        let openDateTime = Date()
        
        // Test currently open bridge
        let openDTO = BridgeEventDTO(
            entityID: "test-bridge-1",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            bridgeID: UUID(),
            openDateTime: openDateTime,
            closeDateTime: nil,
            minutesOpen: 0.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        XCTAssertTrue(openDTO.isCurrentlyOpen)
        
        // Test closed bridge
        let closeDateTime = openDateTime.addingTimeInterval(3600)
        let closedDTO = BridgeEventDTO(
            entityID: "test-bridge-1",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            bridgeID: UUID(),
            openDateTime: openDateTime,
            closeDateTime: closeDateTime,
            minutesOpen: 60.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        XCTAssertFalse(closedDTO.isCurrentlyOpen)
    }
    
    func testDuration() {
        let openDateTime = Date()
        let closeDateTime = openDateTime.addingTimeInterval(3600) // 1 hour
        
        let dto = BridgeEventDTO(
            entityID: "test-bridge-1",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            bridgeID: UUID(),
            openDateTime: openDateTime,
            closeDateTime: closeDateTime,
            minutesOpen: 60.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        XCTAssertEqual(dto.duration, 3600, accuracy: 1.0)
    }
    
    func testDurationForCurrentlyOpen() {
        let openDateTime = Date().addingTimeInterval(-1800) // 30 minutes ago
        
        let dto = BridgeEventDTO(
            entityID: "test-bridge-1",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            bridgeID: UUID(),
            openDateTime: openDateTime,
            closeDateTime: nil,
            minutesOpen: 0.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        XCTAssertGreaterThan(dto.duration, 1700) // Should be around 30 minutes
        XCTAssertLessThan(dto.duration, 1900)
    }
    
    func testFormattedDuration() {
        let openDateTime = Date()
        
        // Test 45 minutes
        let closeDateTime1 = openDateTime.addingTimeInterval(45 * 60)
        let dto1 = BridgeEventDTO(
            entityID: "test-bridge-1",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            bridgeID: UUID(),
            openDateTime: openDateTime,
            closeDateTime: closeDateTime1,
            minutesOpen: 45.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        XCTAssertEqual(dto1.formattedDuration, "45m")
        
        // Test 2 hours 30 minutes
        let closeDateTime2 = openDateTime.addingTimeInterval(2 * 3600 + 30 * 60)
        let dto2 = BridgeEventDTO(
            entityID: "test-bridge-1",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            bridgeID: UUID(),
            openDateTime: openDateTime,
            closeDateTime: closeDateTime2,
            minutesOpen: 150.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        XCTAssertEqual(dto2.formattedDuration, "2h 30m")
    }
    
    // MARK: - Model Conversion Tests
    
    func testToModelWithBridge() throws {
        // Create a bridge first
        let bridge = DrawbridgeInfo(
            entityID: "test-bridge-1",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            latitude: 47.6062,
            longitude: -122.3321
        )
        modelContext.insert(bridge)
        
        let dto = BridgeEventDTO(
            entityID: "test-event-1",
            entityName: "Test Event",
            entityType: "drawbridge",
            bridgeID: bridge.id,
            openDateTime: Date(),
            closeDateTime: nil,
            minutesOpen: 0.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        let model = dto.toModel(in: modelContext, bridge: bridge)
        
        XCTAssertEqual(model.id, dto.id)
        XCTAssertEqual(model.entityID, dto.entityID)
        XCTAssertEqual(model.entityName, dto.entityName)
        XCTAssertEqual(model.entityType, dto.entityType)
        XCTAssertEqual(model.bridge.id, dto.bridgeID)
        XCTAssertEqual(model.openDateTime, dto.openDateTime)
        XCTAssertEqual(model.closeDateTime, dto.closeDateTime)
        XCTAssertEqual(model.minutesOpen, dto.minutesOpen)
        XCTAssertEqual(model.latitude, dto.latitude)
        XCTAssertEqual(model.longitude, dto.longitude)
    }
    
    func testToModelWithBridgeLookup() throws {
        // Create a bridge first
        let bridge = DrawbridgeInfo(
            entityID: "test-bridge-1",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            latitude: 47.6062,
            longitude: -122.3321
        )
        modelContext.insert(bridge)
        
        let dto = BridgeEventDTO(
            entityID: "test-event-1",
            entityName: "Test Event",
            entityType: "drawbridge",
            bridgeID: bridge.id,
            openDateTime: Date(),
            closeDateTime: nil,
            minutesOpen: 0.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        let model = dto.toModel(in: modelContext)
        
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.id, dto.id)
        XCTAssertEqual(model?.entityID, dto.entityID)
        XCTAssertEqual(model?.bridge.id, dto.bridgeID)
    }
    
    func testToModelWithNonExistentBridge() throws {
        let dto = BridgeEventDTO(
            entityID: "test-event-1",
            entityName: "Test Event",
            entityType: "drawbridge",
            bridgeID: UUID(), // Non-existent bridge ID
            openDateTime: Date(),
            closeDateTime: nil,
            minutesOpen: 0.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        let model = dto.toModel(in: modelContext)
        
        XCTAssertNil(model)
    }
    
    // MARK: - Equatable and Hashable Tests
    
    func testEquatable() {
        let id = UUID()
        let bridgeID = UUID()
        let openDateTime = Date()
        
        let dto1 = BridgeEventDTO(
            id: id,
            entityID: "test-bridge-1",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            bridgeID: bridgeID,
            openDateTime: openDateTime,
            closeDateTime: nil,
            minutesOpen: 0.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        let dto2 = BridgeEventDTO(
            id: id,
            entityID: "test-bridge-2", // Different entity ID
            entityName: "Test Bridge 2", // Different name
            entityType: "drawbridge",
            bridgeID: bridgeID,
            openDateTime: openDateTime,
            closeDateTime: nil,
            minutesOpen: 0.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        // Should be equal because they have the same ID
        XCTAssertEqual(dto1, dto2)
        
        let dto3 = BridgeEventDTO(
            id: UUID(), // Different ID
            entityID: "test-bridge-1",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            bridgeID: bridgeID,
            openDateTime: openDateTime,
            closeDateTime: nil,
            minutesOpen: 0.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        // Should not be equal because they have different IDs
        XCTAssertNotEqual(dto1, dto3)
    }
    
    func testHashable() {
        let id = UUID()
        let bridgeID = UUID()
        let openDateTime = Date()
        
        let dto1 = BridgeEventDTO(
            id: id,
            entityID: "test-bridge-1",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            bridgeID: bridgeID,
            openDateTime: openDateTime,
            closeDateTime: nil,
            minutesOpen: 0.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        let dto2 = BridgeEventDTO(
            id: id,
            entityID: "test-bridge-2",
            entityName: "Test Bridge 2",
            entityType: "drawbridge",
            bridgeID: bridgeID,
            openDateTime: openDateTime,
            closeDateTime: nil,
            minutesOpen: 0.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        // Should have the same hash because they have the same ID
        XCTAssertEqual(dto1.hashValue, dto2.hashValue)
        
        var set = Set<BridgeEventDTO>()
        set.insert(dto1)
        set.insert(dto2)
        
        // Should only have one element because they're considered equal
        XCTAssertEqual(set.count, 1)
    }
    
    // MARK: - Codable Tests
    
    func testCodable() throws {
        let dto = BridgeEventDTO(
            entityID: "test-bridge-1",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            bridgeID: UUID(),
            openDateTime: Date(),
            closeDateTime: nil,
            minutesOpen: 0.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(dto)
        let decodedDTO = try decoder.decode(BridgeEventDTO.self, from: data)
        
        XCTAssertEqual(dto.id, decodedDTO.id)
        XCTAssertEqual(dto.entityID, decodedDTO.entityID)
        XCTAssertEqual(dto.entityName, decodedDTO.entityName)
        XCTAssertEqual(dto.entityType, decodedDTO.entityType)
        XCTAssertEqual(dto.bridgeID, decodedDTO.bridgeID)
        XCTAssertEqual(dto.openDateTime, decodedDTO.openDateTime)
        XCTAssertEqual(dto.closeDateTime, decodedDTO.closeDateTime)
        XCTAssertEqual(dto.minutesOpen, decodedDTO.minutesOpen)
        XCTAssertEqual(dto.latitude, decodedDTO.latitude)
        XCTAssertEqual(dto.longitude, decodedDTO.longitude)
    }
} 