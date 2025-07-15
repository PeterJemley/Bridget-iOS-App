# 🏗️ Bridget Technical Architecture

**Purpose:** Define the technical architecture for the Bridget iOS app rebuild, supporting a proactive, stepwise development approach.
**Target:** Xcode 16.4+, iOS 18.5+, Swift 6.0+, SwiftUI 6.0+, SwiftData 2.0+

---

## 📋 Executive Summary

This document describes the core technical architecture, data models, and best practices for the Bridget app. It is designed to ensure maintainability, scalability, and performance, and to support the proactive, stepwise rebuild plan.

---

## 🏛️ Architecture Overview

- **Modular Swift Package Manager (SPM) Architecture**
  - 10+ packages for separation of concerns
  - Clear boundaries between data, networking, UI, analytics, and features
- **SwiftData 2.0+ for persistence**
- **SwiftUI 6.0+ for UI**
- **Async/await for concurrency and networking**
- **CloudKit integration for sync (future phase)**

---

## 🗂️ Data Models (SwiftData)

### Core Models
```swift
@Model
public final class DrawbridgeEvent {
    @Attribute(.unique) public var id: UUID
    @Attribute(.indexed) public var entityID: String
    @Attribute(.indexed) public var openDateTime: Date
    public var entityName: String
    public var entityType: String
    public var closeDateTime: Date?
    public var minutesOpen: Double
    public var latitude: Double
    public var longitude: Double
    public var createdAt: Date
    public var updatedAt: Date
}

@Model
public final class DrawbridgeInfo {
    @Attribute(.unique) public var id: UUID
    @Attribute(.indexed) public var entityID: String
    public var entityName: String
    public var entityType: String
    public var latitude: Double
    public var longitude: Double
    public var createdAt: Date
    public var updatedAt: Date
}

@Model
public final class Route {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var startLocation: String
    public var endLocation: String
    public var bridges: [String]
    public var isFavorite: Bool
    public var createdAt: Date
    public var updatedAt: Date
}

@Model
public final class TrafficFlow {
    @Attribute(.unique) public var id: UUID
    @Attribute(.indexed) public var bridgeID: String
    @Attribute(.indexed) public var timestamp: Date
    public var congestionLevel: Double
    public var trafficVolume: Double
    public var correlationScore: Double
}
```

### ModelContainer Configuration
```swift
let schema = Schema([
    DrawbridgeEvent.self,
    DrawbridgeInfo.self,
    Route.self,
    TrafficFlow.self
])
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    allowsSave: true
)
let modelContainer = try ModelContainer(
    for: schema,
    configurations: [modelConfiguration]
)
```

---

## 🔄 Data Layer & Services

- **Service Protocols** for CRUD and business logic
- **BackgroundDataProcessor** for async/background operations
- **Error Handling** via custom error types and logging
- **Testing** with in-memory ModelContainer and test helpers

---

## 🌐 Networking & API

- **Async/await networking** with URLSession
- **API clients** for bridge data, traffic, and analytics
- **Retry logic** with exponential backoff
- **Data validation and sanitization**
- **Security best practices** (no sensitive data in logs, secure storage)

---

## 🖥️ UI Architecture (SwiftUI)

- **Atomic Design System**: Atoms, Molecules, Organisms, Templates
- **Reusable components** in BridgetSharedUI
- **Accessibility-first**: VoiceOver, Dynamic Type, high contrast
- **NavigationStack** for navigation
- **State management** via Observable and @Environment

---

## ⚡ Performance & Optimization

- **Indexed fields** for fast queries
- **Batch operations** for data updates
- **Efficient background processing**
- **Memory and battery optimization**
- **Performance monitoring utilities**

---

## 🧪 Testing & Validation

- **Unit tests** for all services and models
- **Integration tests** for data and networking
- **UI tests** for all user flows
- **Continuous integration** with automated checks

---

## 🔄 Migration & Evolution

- **Schema versioning** for future data migrations
- **Modular upgrades**: Each package can evolve independently
- **CloudKit integration** for future sync
- **Regular architecture reviews**

---

## 🆔 Use of Locally-Generated UUIDs in SwiftData Models

All core SwiftData models (e.g., DrawbridgeEvent, DrawbridgeInfo) use locally-generated UUIDs as their primary keys. This approach provides:
- Globally unique identification for each object, supporting robust relationship management and UI diffing.
- Reliable primary keys for SwiftUI List/ForEach, drag-and-drop, and state management.
- Support for offline object creation and later sync/merge with server data.
- Simplified conflict resolution and traceability for analytics/debugging.
- Enhanced privacy and security, as UUIDs are non-sequential and hard to guess.

**Future Engineering Considerations:**
- When implementing offline support or multi-device sync, leverage UUIDs for temporary IDs and reconciliation with server-side identifiers.
- Use UUIDs for analytics, debugging, and crash reporting to trace specific objects.
- Consider mapping server-provided IDs to local UUIDs for seamless integration.
- Review UUID usage in all new models and features to ensure consistency and best practices.

---

## 🕵️ Deep Audit Findings & Advanced Recommendations

### Error Handling & Transactional Saves
- All `modelContext.save()` calls are wrapped in `do/catch`, but transactional closures (if available) are not yet used. Recommend adopting transactional blocks for multi-step imports to ensure atomicity and rollback on failure.
- Define and document rollback/recovery strategies for failed saves. Consider using `modelContext.performAndWait { ... }` or similar transactional APIs as SwiftData evolves.

### Merge Policy & Conflict Resolution
- **Current State:** The app currently uses the default SwiftData merge policy ("last write wins") as no explicit `ModelContext.mergePolicy` is set anywhere in the codebase.
- **Implications:** This is safe for single-context or main-actor operations, but may cause silent data loss or overwrites if background imports or multiple contexts are introduced.
- **Recommendation:**
    - Document this default in code and docs.
    - If background contexts are added, explicitly set and test `ModelContext.mergePolicy` (e.g., `.mergeByPropertyObjectTrump` or `.mergeByPropertyStoreTrump`) and add conflict resolution hooks/logging.
    - Add a TODO/warning in code: "If background imports or multiple ModelContexts are introduced, explicitly set and test ModelContext.mergePolicy to avoid data loss or silent overwrites."

#### Why Explicit Merge Policy Matters
- Relying on SwiftData's default ("last write wins") can silently drop changes as you scale to multiple contexts (e.g., background imports, child contexts).
- Explicitly configuring a merge policy avoids silent data loss, documents your intent (UI vs. server authority), and enables robust conflict testing.

#### How to Set a Merge Policy in SwiftData
```swift
import SwiftData

@main
struct BridgetApp: App {
  // Pick the policy that matches your UX:
  // - .mergeByPropertyObjectTrump: UI/context changes win
  // - .mergeByPropertyStoreTrump: Store/server changes win
  let config = ModelConfiguration(
    containerName: "BridgetModel",
    mergePolicy: .mergeByPropertyObjectTrump
  )

  var body: some Scene {
    WindowGroup {
      ContentView()
        .modelContainer(for: [DrawbridgeEvent.self, DrawbridgeInfo.self], configuration: config)
    }
  }
}
```
- For background/child contexts, set mergePolicy as needed:
```swift
let backgroundContext = container.createBackgroundContext(
  mergePolicy: .mergeByPropertyStoreTrump
)
```

#### Testing Your Merge Strategy
- Add unit tests that simulate two contexts racing to update the same entity, saving in different orders, and asserting the final value matches your policy.
- Example:
```swift
func testConflictResolution_objectTrump() throws {
    let container = makeContainer(mergePolicy: .mergeByPropertyObjectTrump)
    let ctxA = container.viewContext
    let ctxB = container.createBackgroundContext()
    // ...simulate conflicting edits and saves...
    // Assert: with objectTrump, ctxA wins
}
```

#### Next Steps
1. Pick & document the merge policy that matches your UX expectations.
2. Centralize configuration so all contexts use the right policy.
3. Add conflict tests to protect against regressions.
4. Review all child/background contexts for correct policy inheritance.

### Change Notification Throttling
- Large inserts/deletes may trigger excessive SwiftData change notifications, potentially causing UI stutter. Profile full-import runs and, if needed, batch notifications or use `withAnimation(.none)` to throttle UI updates.
- Large data imports (e.g., full event/bridge refresh) are now wrapped in `withAnimation(.none)` in `OpenSeattleAPIService` to suppress SwiftUI diffing/animation and reduce UI stutter during large inserts/deletes.
- This approach minimizes the performance impact of SwiftData change notifications and is recommended for any batch operation that mutates many objects at once.
- Profile UI responsiveness as data volumes grow, and consider more advanced batching/observer strategies if needed in future SwiftData releases.

### Memory Usage During Import
- The import logic now uses a stream-parse-insert pattern: each batch of API data is processed and inserted as it arrives, rather than accumulating all responses in memory. This minimizes memory usage and improves scalability.
- Only minimal state (e.g., a bridge map) is kept in memory during import.
- See OpenSeattleAPIService for implementation details and rationale.

### FetchDescriptor Selectivity
- All core data services currently use FetchDescriptor<T> to fetch full model objects (all fields/properties), even for existence checks or lightweight queries.
- **Recommendation:** For existence checks or lightweight queries, use field projection in FetchDescriptor (if/when supported by SwiftData) to fetch only the fields you need (e.g., just the id or entityID).
- Document this pattern and encourage contributors to monitor for new SwiftData APIs that allow more granular field selection.
- As data grows, this optimization will help reduce memory usage and improve query performance.

### SwiftUI Context Save Semantics
- All SwiftUI views that mutate the modelContext (insert/delete) are now required to call modelContext.save() explicitly after the mutation.
- This ensures changes are persisted immediately and avoids relying on implicit or parent-driven saves, which can lead to data loss.
- See AddRouteView and AddTrafficFlowView for code examples and rationale.

- SwiftData now supports true batch deletes via ModelContext.delete(model:where:includeSubentities:).
- Use this API for all full data replacements and conditional deletes (e.g., delete all events, delete events older than X).
- This is more efficient than per-object delete loops and does not require NSBatchDeleteRequest unless you are interoperating with legacy Core Data.
- See OpenSeattleAPIService and all core data services for code examples and rationale.

- SwiftData now supports true transactional blocks via modelContext.transaction { ... } (iOS 18+/SwiftData 1.1+).
- Use this API for all multi-step imports/updates to ensure atomicity and rollback. All changes inside the block are committed together or not at all.
- No need to call save() inside the block; the transaction auto-commits on success and rolls back on error.
- For pre-iOS 18 or legacy environments, fallback to per-operation save() and document the limitation.
- See OpenSeattleAPIService for code example and rationale.

## SwiftData Import Pattern (2025-07-15)

- **All async network fetches must occur before entering the SwiftData transaction block.**
- **Accumulate all DrawbridgeEventResponse objects in memory.**
- **Perform a single transaction for all SwiftData mutations (deletes/inserts/updates).**
- **Rationale:** SwiftData's transaction block is synchronous and must not contain any `await` calls. This ensures atomicity, rollback, and thread safety. See `OpenSeattleAPIService.swift` for the reference implementation.
- **Alternative:** For very large datasets, consider a batch-streaming approach: fetch and transact in mini-batches to avoid high memory usage, at the cost of more transactions.
- **Reference:** See comments in `OpenSeattleAPIService.swift` and `REBUILD_IMPLEMENTATION_GUIDE.md` for further details.
