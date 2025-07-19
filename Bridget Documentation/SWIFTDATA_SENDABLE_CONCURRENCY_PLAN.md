# SwiftData Sendable Concurrency Integration Plan

**Purpose**: Address Swift concurrency model requirements for SwiftData models in Bridget app
**Target**: Xcode 16.4+, iOS 18.5+, Swift 6.0+, SwiftData 2.0+
**Approach**: Proactive, stepwise implementation to ensure thread safety and prevent data races

---

## Executive Summary

This plan addresses the Swift concurrency model requirements for SwiftData models in the Bridget app. The current implementation has potential concurrency issues because SwiftData `@Model` types don't automatically conform to `Sendable`, and the app uses async/await patterns that cross actor boundaries.

### Key Problem Statement
"In Swift's concurrency model, any value crossing an actor boundary must conform to Sendable so the compiler can guarantee it's safe to share between threads. However, SwiftData's @Model types are reference-based and do not automatically conform to Sendable, so if you try to pass a model object directly from one actor to another, you'll get a compiler error about a non-Sendable type."

### Current State Analysis
- **SwiftData Models**: Properly defined with `@Model` and relationships
- **Async/Await Usage**: Network operations use modern concurrency
- **@MainActor**: UI components properly isolated
- **Concurrency Gaps**: Model objects passed across actor boundaries without Sendable conformance
- **Background Operations**: Potential data races in background processing

### Solution Strategy
1. **Actor Isolation**: Isolate model operations behind actors
2. **Sendable DTOs**: Use Data Transfer Objects for actor boundary crossing
3. **PersistentIdentifier**: Use SwiftData's thread-safe identifiers
4. **Avoid @unchecked Sendable**: Maintain compiler safety checks

---

## Phase 1: Assessment & Analysis (Day 1)

### Current Concurrency Pattern Analysis
**Duration**: 4-6 hours
**Deliverables**: Comprehensive concurrency audit report

#### Tasks
- [ ] **Audit Current Async Operations**
  - [ ] Map all `async` functions that access SwiftData models
  - [ ] Identify actor boundary crossings
  - [ ] Document current error handling patterns
  - [ ] Analyze background processing operations

- [ ] **Identify Sendable Violations**
  - [ ] Find places where `@Model` objects cross actor boundaries
  - [ ] Document `ModelContext` usage patterns
  - [ ] Identify potential data race conditions
  - [ ] Map relationship object passing patterns

#### Current Issues Identified
1. **OpenSeattleAPIService**: `fetchAndStoreAllData(modelContext:)` passes `ModelContext` across actor boundaries
2. **DataManager**: Services use `ModelContext` in async operations
3. **Background Processing**: No clear actor isolation for data operations
4. **Model Relationships**: `DrawbridgeEvent.bridge` relationship may cross boundaries

#### Success Criteria
- [ ] Complete concurrency audit documented
- [ ] All actor boundary crossings identified
- [ ] Potential data races mapped
- [ ] Current patterns analyzed for risks

---

## Phase 2: Actor Isolation Strategy (Day 2)

### Actor Architecture Design
**Duration**: 6-8 hours
**Deliverables**: Actor isolation strategy and implementation plan

#### Tasks
- [ ] **Design Actor Boundaries**
  ```swift
  // Proposed Actor Architecture
  @MainActor
  class BridgetApp: App {
      // UI operations only
  }
  
  @ModelActor
  class DataProcessor {
      // Background data operations
  }
  
  actor NetworkProcessor {
      // Network operations and data transformation
  }
  ```

- [ ] **Define Sendable DTOs**
  ```swift
  // Sendable Data Transfer Objects
  struct BridgeEventDTO: Sendable, Codable {
      let id: UUID
      let entityID: String
      let entityName: String
      let openDateTime: Date
      let closeDateTime: Date?
      let minutesOpen: Double
      let latitude: Double
      let longitude: Double
  }
  
  struct BridgeInfoDTO: Sendable, Codable {
      let id: UUID
      let entityID: String
      let entityName: String
      let entityType: String
      let latitude: Double
      let longitude: Double
  }
  ```

- [ ] **Plan Actor Communication**
  - [ ] Define message passing patterns
  - [ ] Design DTO conversion utilities
  - [ ] Plan error propagation across actors
  - [ ] Design transaction coordination

#### Success Criteria
- [ ] Actor architecture fully designed
- [ ] Sendable DTOs defined for all models
- [ ] Communication patterns established
- [ ] Error handling strategy planned

---

## Phase 3: DTO Implementation (Day 3)

### Sendable DTO Creation
**Duration**: 4-6 hours
**Deliverables**: Complete DTO system for actor boundary crossing

#### Tasks
- [ ] **Create DTO Package**
  ```swift
  // Packages/BridgetCore/Sources/BridgetCore/DTOs/
  public struct BridgeEventDTO: Sendable, Codable, Identifiable {
      public let id: UUID
      public let entityID: String
      public let entityName: String
      public let entityType: String
      public let bridgeID: UUID // Reference to bridge
      public let openDateTime: Date
      public let closeDateTime: Date?
      public let minutesOpen: Double
      public let latitude: Double
      public let longitude: Double
      public let createdAt: Date
      public let updatedAt: Date
      
      public init(from event: DrawbridgeEvent) {
          self.id = event.id
          self.entityID = event.entityID
          self.entityName = event.entityName
          self.entityType = event.entityType
          self.bridgeID = event.bridge.id
          self.openDateTime = event.openDateTime
          self.closeDateTime = event.closeDateTime
          self.minutesOpen = event.minutesOpen
          self.latitude = event.latitude
          self.longitude = event.longitude
          self.createdAt = event.createdAt
          self.updatedAt = event.updatedAt
      }
  }
  
  public struct BridgeInfoDTO: Sendable, Codable, Identifiable {
      public let id: UUID
      public let entityID: String
      public let entityName: String
      public let entityType: String
      public let latitude: Double
      public let longitude: Double
      public let createdAt: Date
      public let updatedAt: Date
      
      public init(from bridge: DrawbridgeInfo) {
          self.id = bridge.id
          self.entityID = bridge.entityID
          self.entityName = bridge.entityName
          self.entityType = bridge.entityType
          self.latitude = bridge.latitude
          self.longitude = bridge.longitude
          self.createdAt = bridge.createdAt
          self.updatedAt = bridge.updatedAt
      }
  }
  ```

- [ ] **Create Conversion Utilities**
  ```swift
  // Packages/BridgetCore/Sources/BridgetCore/Utilities/ModelConversion.swift
  public extension DrawbridgeEvent {
      func toDTO() -> BridgeEventDTO {
          BridgeEventDTO(from: self)
      }
  }
  
  public extension DrawbridgeInfo {
      func toDTO() -> BridgeInfoDTO {
          BridgeInfoDTO(from: self)
      }
  }
  
  public extension BridgeEventDTO {
      func toModel(in context: ModelContext, bridge: DrawbridgeInfo) -> DrawbridgeEvent {
          DrawbridgeEvent(
              id: id,
              entityID: entityID,
              entityName: entityName,
              entityType: entityType,
              bridge: bridge,
              openDateTime: openDateTime,
              closeDateTime: closeDateTime,
              minutesOpen: minutesOpen,
              latitude: latitude,
              longitude: longitude
          )
      }
  }
  ```

#### Success Criteria
- [ ] All DTOs implemented and tested
- [ ] Conversion utilities working
- [ ] Sendable conformance verified
- [ ] Codable implementation complete

---

## Phase 4: Actor Refactoring (Day 4-5)

### Network Actor Implementation
**Duration**: 8-10 hours
**Deliverables**: Refactored network operations with proper actor isolation

#### Tasks
- [ ] **Refactor OpenSeattleAPIService**
  ```swift
  // Bridget/OpenSeattleAPIService.swift
  @MainActor
  class OpenSeattleAPIService: ObservableObject {
      @Published var isLoading = false
      @Published var lastFetchDate: Date?
      @Published var error: Error?
      
      private let networkProcessor: NetworkProcessor
      
      init(networkProcessor: NetworkProcessor = NetworkProcessor()) {
          self.networkProcessor = networkProcessor
      }
      
      func fetchAndStoreAllData(modelContext: ModelContext) async {
          isLoading = true
          defer { isLoading = false }
          
          do {
              // Fetch data using actor
              let bridgeDTOs = try await networkProcessor.fetchBridgeData()
              let eventDTOs = try await networkProcessor.fetchEventData()
              
              // Process on main actor with ModelContext
              try await processDataOnMainActor(
                  bridgeDTOs: bridgeDTOs,
                  eventDTOs: eventDTOs,
                  modelContext: modelContext
              )
              
              lastFetchDate = Date()
              error = nil
          } catch {
              self.error = error
          }
      }
      
      @MainActor
      private func processDataOnMainActor(
          bridgeDTOs: [BridgeInfoDTO],
          eventDTOs: [BridgeEventDTO],
          modelContext: ModelContext
      ) async throws {
          try modelContext.transaction {
              // Process bridge data
              var bridgeMap: [UUID: DrawbridgeInfo] = [:]
              for bridgeDTO in bridgeDTOs {
                  let bridge = bridgeDTO.toModel(in: modelContext)
                  modelContext.insert(bridge)
                  bridgeMap[bridge.id] = bridge
              }
              
              // Process event data
              for eventDTO in eventDTOs {
                  guard let bridge = bridgeMap[eventDTO.bridgeID] else { continue }
                  let event = eventDTO.toModel(in: modelContext, bridge: bridge)
                  modelContext.insert(event)
              }
          }
      }
  }
  
  actor NetworkProcessor {
      private let baseURL = "https://data.seattle.gov/resource/gm8h-9449.json"
      private let batchSize = 1000
      private let networkSession: NetworkSession
      private let decoder: JSONDecoder
      
      init(networkSession: NetworkSession = URLSession.shared) {
          self.networkSession = networkSession
          let d = JSONDecoder()
          d.dateDecodingStrategy = .iso8601
          self.decoder = d
      }
      
      func fetchBridgeData() async throws -> [BridgeInfoDTO] {
          // Network operations here - returns Sendable DTOs
          let responses = try await fetchAllBatches()
          return responses.compactMap { response in
              guard let entityID = response.entityid,
                    let entityName = response.entityname,
                    let entityType = response.entitytype,
                    let latitudeString = response.latitude,
                    let latitude = Double(latitudeString),
                    let longitudeString = response.longitude,
                    let longitude = Double(longitudeString) else { return nil }
              
              return BridgeInfoDTO(
                  id: UUID(),
                  entityID: entityID,
                  entityName: entityName,
                  entityType: entityType,
                  latitude: latitude,
                  longitude: longitude,
                  createdAt: Date(),
                  updatedAt: Date()
              )
          }
      }
      
      func fetchEventData() async throws -> [BridgeEventDTO] {
          // Similar implementation for events
          // Returns Sendable DTOs
      }
      
      private func fetchAllBatches() async throws -> [DrawbridgeEventResponse] {
          // Existing batch fetching logic
          // Returns network response objects
      }
  }
  ```

#### Success Criteria
- [ ] Network operations isolated in actor
- [ ] DTOs used for actor boundary crossing
- [ ] MainActor properly handles ModelContext
- [ ] Error handling preserved across actors

---

## Phase 5: Service Layer Refactoring (Day 6)

### Data Services Actor Isolation
**Duration**: 6-8 hours
**Deliverables**: Refactored data services with proper actor isolation

#### Tasks
- [ ] **Refactor DataManager**
  ```swift
  // Packages/BridgetCore/Sources/BridgetCore/Services/DataManager.swift
  @MainActor
  @Observable
  public final class DataManager {
      private let modelContext: ModelContext
      private let backgroundProcessor: BackgroundDataProcessor
      
      // MARK: - Services
      public let eventService: DrawbridgeEventService
      public let infoService: DrawbridgeInfoServiceProtocol
      public let routeService: RouteService
      public let trafficService: TrafficFlowService
      
      public init(
          modelContext: ModelContext,
          backgroundProcessor: BackgroundDataProcessor = BackgroundDataProcessor()
      ) {
          self.modelContext = modelContext
          self.backgroundProcessor = backgroundProcessor
          
          // Initialize services with main actor context
          self.eventService = DrawbridgeEventService(modelContext: modelContext)
          self.infoService = DrawbridgeInfoService(modelContext: modelContext)
          self.routeService = RouteService(modelContext: modelContext)
          self.trafficService = TrafficFlowService(modelContext: modelContext)
      }
      
      // MARK: - Data Synchronization
      
      /// Synchronize all data from external sources
      /// - Parameter forceRefresh: If true, force refresh even if data is recent
      public func synchronizeData(forceRefresh: Bool = false) async throws {
          do {
              // Use background processor for heavy operations
              let syncData = try await backgroundProcessor.prepareSyncData(forceRefresh: forceRefresh)
              
              // Apply changes on main actor
              try await applySyncData(syncData)
          } catch {
              throw BridgetDataError.networkError(error)
          }
      }
      
      @MainActor
      private func applySyncData(_ syncData: SyncDataDTO) async throws {
          try modelContext.transaction {
              // Apply bridge updates
              for bridgeDTO in syncData.bridges {
                  let bridge = bridgeDTO.toModel(in: modelContext)
                  modelContext.insert(bridge)
              }
              
              // Apply event updates
              for eventDTO in syncData.events {
                  guard let bridge = try? modelContext.fetch(FetchDescriptor<DrawbridgeInfo>(
                      predicate: #Predicate<DrawbridgeInfo> { $0.id == eventDTO.bridgeID }
                  )).first else { continue }
                  
                  let event = eventDTO.toModel(in: modelContext, bridge: bridge)
                  modelContext.insert(event)
              }
          }
      }
  }
  
  actor BackgroundDataProcessor {
      func prepareSyncData(forceRefresh: Bool) async throws -> SyncDataDTO {
          // Background processing logic
          // Returns Sendable DTOs
          return SyncDataDTO(bridges: [], events: [])
      }
  }
  
  struct SyncDataDTO: Sendable {
      let bridges: [BridgeInfoDTO]
      let events: [BridgeEventDTO]
  }
  ```

- [ ] **Update Service Protocols**
  ```swift
  // Packages/BridgetCore/Sources/BridgetCore/Services/DrawbridgeEventService.swift
  @MainActor
  public final class DrawbridgeEventService {
      private let modelContext: ModelContext
      
      public init(modelContext: ModelContext) {
          self.modelContext = modelContext
      }
      
      // All methods remain @MainActor for ModelContext access
      public func fetchEvents(for entityID: String? = nil) throws -> [DrawbridgeEvent] {
          // Existing implementation
      }
      
      public func saveEvent(_ event: DrawbridgeEvent) throws {
          // Existing implementation
      }
  }
  ```

#### Success Criteria
- [ ] DataManager properly isolated
- [ ] Background processing in separate actor
- [ ] Service protocols maintain @MainActor
- [ ] DTOs used for heavy operations

---

## Phase 6: Testing & Validation (Day 7)

### Concurrency Testing
**Duration**: 6-8 hours
**Deliverables**: Comprehensive concurrency tests and validation

#### Tasks
- [ ] **Create Concurrency Test Suite**
  ```swift
  // Packages/BridgetCore/Tests/BridgetCoreTests/ConcurrencyTests.swift
  @MainActor
  final class ConcurrencyTests: XCTestCase {
      var modelContainer: ModelContainer!
      var modelContext: ModelContext!
      var dataManager: DataManager!
      var networkProcessor: NetworkProcessor!
      
      override func setUp() async throws {
          let schema = Schema([
              DrawbridgeEvent.self,
              DrawbridgeInfo.self,
              Route.self,
              TrafficFlow.self
          ])
          let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
          modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
          modelContext = ModelContext(modelContainer)
          networkProcessor = NetworkProcessor()
          dataManager = DataManager(modelContext: modelContext)
      }
      
      func testActorBoundaryCrossing() async throws {
          // Test that DTOs can cross actor boundaries
          let bridgeDTO = BridgeInfoDTO(
              id: UUID(),
              entityID: "test-bridge",
              entityName: "Test Bridge",
              entityType: "drawbridge",
              latitude: 47.6062,
              longitude: -122.3321,
              createdAt: Date(),
              updatedAt: Date()
          )
          
          // This should compile without Sendable errors
          let _: BridgeInfoDTO = await networkProcessor.processBridgeDTO(bridgeDTO)
      }
      
      func testConcurrentDataAccess() async throws {
          // Test concurrent access to data
          async let task1 = dataManager.synchronizeData(forceRefresh: true)
          async let task2 = dataManager.synchronizeData(forceRefresh: false)
          
          // Both should complete without data races
          try await (task1, task2)
      }
      
      func testModelContextIsolation() async throws {
          // Test that ModelContext is only accessed on MainActor
          let bridge = DrawbridgeInfo(
              entityID: "test",
              entityName: "Test",
              entityType: "drawbridge",
              latitude: 0,
              longitude: 0
          )
          
          // This should work (MainActor)
          modelContext.insert(bridge)
          
          // This should not compile (crossing actor boundary)
          // await networkProcessor.insertBridge(bridge) // Should fail
      }
  }
  ```

- [ ] **Create Performance Tests**
  ```swift
  // Packages/BridgetCore/Tests/BridgetCoreTests/PerformanceTests.swift
  @MainActor
  final class PerformanceTests: XCTestCase {
      func testLargeDataSyncPerformance() async throws {
          // Test performance of large data synchronization
          let startTime = CFAbsoluteTimeGetCurrent()
          
          // Perform large sync operation
          try await dataManager.synchronizeData(forceRefresh: true)
          
          let endTime = CFAbsoluteTimeGetCurrent()
          let duration = endTime - startTime
          
          // Should complete within reasonable time
          XCTAssertLessThan(duration, 5.0, "Large data sync took too long")
      }
  }
  ```

#### Success Criteria
- [ ] All concurrency tests passing
- [ ] No Sendable violations detected
- [ ] Performance benchmarks established
- [ ] Data race conditions eliminated

---

## Phase 7: Documentation & Guidelines (Day 8)

### Concurrency Guidelines
**Duration**: 4-6 hours
**Deliverables**: Comprehensive concurrency documentation

#### Tasks
- [ ] **Update Technical Architecture**
  ```markdown
  # Concurrency Guidelines for Bridget
  
  ## Actor Isolation Strategy
  
  ### MainActor Usage
  - All UI operations must be on @MainActor
  - ModelContext access must be on @MainActor
  - SwiftData transactions must be on @MainActor
  
  ### Background Actor Usage
  - Network operations use dedicated NetworkProcessor actor
  - Heavy data processing uses BackgroundDataProcessor actor
  - All actor communication uses Sendable DTOs
  
  ### Sendable DTOs
  - BridgeEventDTO: For event data crossing actor boundaries
  - BridgeInfoDTO: For bridge data crossing actor boundaries
  - SyncDataDTO: For bulk synchronization data
  
  ### Best Practices
  1. Never pass @Model objects across actor boundaries
  2. Always use DTOs for actor communication
  3. Keep ModelContext operations on MainActor
  4. Use transactions for atomic operations
  5. Handle errors appropriately across actors
  ```

- [ ] **Create Code Review Checklist**
  ```markdown
  # Concurrency Code Review Checklist
  
  ## Actor Boundaries
  - [ ] Are all async functions properly isolated?
  - [ ] Do any @Model objects cross actor boundaries?
  - [ ] Are DTOs used for actor communication?
  - [ ] Is ModelContext only accessed on MainActor?
  
  ## Sendable Compliance
  - [ ] Do all DTOs conform to Sendable?
  - [ ] Are there any @unchecked Sendable annotations?
  - [ ] Are value types used for actor communication?
  - [ ] Are reference types properly isolated?
  
  ## Error Handling
  - [ ] Are errors properly propagated across actors?
  - [ ] Is error handling consistent across the app?
  - [ ] Are network errors handled gracefully?
  - [ ] Are data validation errors caught?
  ```

#### Success Criteria
- [ ] Concurrency guidelines documented
- [ ] Code review checklist created
- [ ] Best practices established
- [ ] Team training materials prepared

---

## Phase 8: Integration & Deployment (Day 9)

### Final Integration
**Duration**: 6-8 hours
**Deliverables**: Fully integrated concurrency-safe system

#### Tasks
- [ ] **Update UI Components**
  ```swift
  // Bridget/BridgesListView.swift
  @MainActor
  struct BridgesListView: View {
      @Environment(\.modelContext) private var modelContext
      @StateObject private var dataManager: DataManager
      
      init() {
          // Initialize with proper actor isolation
          self._dataManager = StateObject(wrappedValue: DataManager(modelContext: modelContext))
      }
      
      var body: some View {
          // Existing UI implementation
          // All ModelContext access is on MainActor
      }
  }
  ```

- [ ] **Update App Entry Point**
  ```swift
  // Bridget/BridgetApp.swift
  @main
  struct BridgetApp: App {
      @StateObject private var apiService: OpenSeattleAPIService
      
      var sharedModelContainer: ModelContainer = {
          // Existing ModelContainer setup
      }()
      
      init() {
          // Initialize with proper actor isolation
          let networkProcessor = NetworkProcessor()
          self._apiService = StateObject(wrappedValue: OpenSeattleAPIService(networkProcessor: networkProcessor))
      }
      
      var body: some Scene {
          WindowGroup {
              ContentView()
                  .environmentObject(apiService)
          }
          .modelContainer(sharedModelContainer)
      }
  }
  ```

- [ ] **Final Build and Test**
  - [ ] Build project with all concurrency changes
  - [ ] Run comprehensive test suite
  - [ ] Verify no Sendable violations
  - [ ] Test performance and memory usage

#### Success Criteria
- [ ] App builds without concurrency errors
- [ ] All tests passing
- [ ] Performance maintained or improved
- [ ] No data race conditions

---

## Success Metrics & Validation

### Quantitative Metrics
- **Sendable Compliance**: 100% of actor boundary crossings use Sendable types
- **Build Success**: 0 concurrency-related build errors
- **Test Coverage**: 95%+ concurrency test coverage
- **Performance**: No degradation in app performance
- **Memory Usage**: Stable memory usage under concurrent load

### Qualitative Metrics
- **Code Quality**: Cleaner, more maintainable concurrency code
- **Developer Experience**: Clear patterns for actor communication
- **Error Handling**: Robust error propagation across actors
- **Documentation**: Comprehensive concurrency guidelines

### Risk Mitigation
- **Incremental Migration**: Changes applied step by step
- **Comprehensive Testing**: Extensive testing at each phase
- **Rollback Plan**: Ability to revert changes if issues arise
- **Performance Monitoring**: Continuous performance validation

---

## Future Enhancements

### Advanced Concurrency Features
- **Structured Concurrency**: Task groups for complex operations
- **Async Sequences**: Streaming data processing
- **Custom Actors**: Specialized actors for specific operations
- **Concurrency Debugging**: Enhanced debugging tools

### Performance Optimizations
- **Actor Pooling**: Reuse actors for better performance
- **Batch Processing**: Optimize bulk operations
- **Caching Strategies**: Intelligent data caching
- **Memory Management**: Optimize memory usage patterns

---

## Implementation Checklist

### Phase 1: Assessment & Analysis
- [ ] Audit current async operations
- [ ] Identify actor boundary crossings
- [ ] Document current error handling patterns
- [ ] Analyze background processing operations
- [ ] Find places where @Model objects cross actor boundaries
- [ ] Document ModelContext usage patterns
- [ ] Identify potential data race conditions
- [ ] Map relationship object passing patterns

### Phase 2: Actor Isolation Strategy
- [ ] Design actor boundaries
- [ ] Define Sendable DTOs
- [ ] Plan actor communication patterns
- [ ] Design DTO conversion utilities
- [ ] Plan error propagation across actors
- [ ] Design transaction coordination

### Phase 3: DTO Implementation
- [ ] Create DTO package structure
- [ ] Implement BridgeEventDTO
- [ ] Implement BridgeInfoDTO
- [ ] Create conversion utilities
- [ ] Test Sendable conformance
- [ ] Verify Codable implementation

### Phase 4: Actor Refactoring
- [ ] Refactor OpenSeattleAPIService
- [ ] Implement NetworkProcessor actor
- [ ] Update network operations
- [ ] Test actor boundary crossing
- [ ] Verify error handling
- [ ] Test performance impact

### Phase 5: Service Layer Refactoring
- [ ] Refactor DataManager
- [ ] Implement BackgroundDataProcessor actor
- [ ] Update service protocols
- [ ] Test background processing
- [ ] Verify data consistency
- [ ] Test error propagation

### Phase 6: Testing & Validation
- [ ] Create concurrency test suite
- [ ] Implement performance tests
- [ ] Test actor boundary crossing
- [ ] Test concurrent data access
- [ ] Test ModelContext isolation
- [ ] Validate performance benchmarks

### Phase 7: Documentation & Guidelines
- [ ] Update technical architecture
- [ ] Create concurrency guidelines
- [ ] Create code review checklist
- [ ] Document best practices
- [ ] Prepare team training materials
- [ ] Update UI_ELEMENT_MANIFEST.md

### Phase 8: Integration & Deployment
- [ ] Update UI components
- [ ] Update app entry point
- [ ] Final build and test
- [ ] Verify no concurrency errors
- [ ] Test performance and memory usage
- [ ] Deploy to production

---

## Next Steps

1. **Begin Phase 1**: Start with comprehensive concurrency audit
2. **Document Current State**: Map all async operations and actor boundaries
3. **Identify Violations**: Find all Sendable compliance issues
4. **Plan Migration**: Design step-by-step migration strategy
5. **Implement Incrementally**: Apply changes phase by phase
6. **Test Thoroughly**: Validate each phase before proceeding
7. **Document Progress**: Update documentation throughout process

This plan ensures that the Bridget app fully complies with Swift's concurrency model while maintaining performance, reliability, and maintainability. The plan addresses the specific Sendable requirements for SwiftData models and provides a clear path for implementation. 