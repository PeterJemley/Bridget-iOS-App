# Concurrency Audit Report - Phase 1

**Purpose**: Comprehensive audit of current concurrency patterns in Bridget app
**Scope**: All async operations, actor boundaries, and SwiftData model usage
**Status**: Phase 1 Assessment & Analysis Complete

---

## Executive Summary

This audit identifies critical concurrency issues in the Bridget app that violate Swift's Sendable requirements for SwiftData models. The current implementation has several areas where `@Model` objects cross actor boundaries without proper Sendable conformance, creating potential data race conditions and compiler safety violations.

### Key Findings
- **Critical Issues**: 4 major Sendable violations identified
- **High Risk**: ModelContext passed across actor boundaries
- **Medium Risk**: Background processing without proper actor isolation
- **Low Risk**: UI components properly isolated with @MainActor

### Risk Assessment
- **Data Race Probability**: HIGH - Multiple concurrent access patterns
- **Compiler Safety**: MEDIUM - Some violations may not trigger compiler errors
- **Performance Impact**: LOW - Current patterns work but are unsafe
- **Maintainability**: MEDIUM - Code works but violates best practices

---

## Critical Issues Identified

### Issue #1: OpenSeattleAPIService - ModelContext Actor Boundary Crossing

**Location**: `Bridget/OpenSeattleAPIService.swift:28-60`
**Severity**: CRITICAL
**Risk**: Data Race, Compiler Safety Violation

#### Problem Description
```swift
@MainActor
class OpenSeattleAPIService: ObservableObject {
    // ...
    func fetchAndStoreAllData(modelContext: ModelContext) async {
        // This function is @MainActor but performs network operations
        // Network operations should be on background actor
        let batch = try await fetchBatch(offset: offset, limit: batchSize)
        
        // ModelContext operations mixed with network operations
        try modelContext.transaction {
            // SwiftData operations here
        }
    }
}
```

#### Issues Identified
1. **Mixed Actor Contexts**: Network operations and ModelContext operations in same function
2. **No Actor Isolation**: Network operations should be on dedicated actor
3. **Potential Data Races**: ModelContext accessed during async network operations
4. **Sendable Violation**: ModelContext passed across potential actor boundaries

#### Impact
- **Data Integrity**: Risk of data corruption during concurrent access
- **Performance**: Network operations block MainActor unnecessarily
- **Safety**: Violates Swift concurrency safety guarantees

### Issue #2: DataManager - Async Operations Without Actor Isolation

**Location**: `Packages/BridgetCore/Sources/BridgetCore/Services/DataManager.swift:1-93`
**Severity**: HIGH
**Risk**: Data Race, Inconsistent State

#### Problem Description
```swift
@Observable
public final class DataManager {
    private let modelContext: ModelContext
    
    public func synchronizeData(forceRefresh: Bool = false) async throws {
        // Multiple async operations without proper actor isolation
        try await refreshBridgeEvents(forceRefresh: forceRefresh)
        try await refreshBridgeInfo(forceRefresh: forceRefresh)
        try await refreshTrafficData(forceRefresh: forceRefresh)
    }
}
```

#### Issues Identified
1. **No Actor Annotation**: DataManager not properly isolated
2. **Concurrent Access**: Multiple services access ModelContext concurrently
3. **Background Processing**: No dedicated actor for background operations
4. **Service Coordination**: Services not coordinated across actors

#### Impact
- **Concurrency Safety**: Multiple threads may access ModelContext simultaneously
- **Data Consistency**: Risk of inconsistent state during synchronization
- **Error Handling**: Errors may not propagate correctly across actor boundaries

### Issue #3: Service Layer - Inconsistent Actor Isolation

**Location**: Multiple service files in `Packages/BridgetCore/Sources/BridgetCore/Services/`
**Severity**: MEDIUM
**Risk**: Inconsistent Concurrency Patterns

#### Problem Description
```swift
// DrawbridgeInfoService.swift
public func fetchAllBridges() async throws -> [DrawbridgeInfo] {
    // No actor isolation specified
    return try modelContext.fetch(descriptor)
}

// RouteService.swift  
public func fetchRoutes(favoritesOnly: Bool = false) async throws -> [Route] {
    // No actor isolation specified
    return try modelContext.fetch(descriptor)
}
```

#### Issues Identified
1. **Missing Actor Annotations**: Services not explicitly isolated
2. **Inconsistent Patterns**: Some services may be called from different actors
3. **ModelContext Access**: Direct ModelContext access without actor guarantees
4. **Return Value Safety**: @Model objects returned without Sendable conformance

#### Impact
- **Code Clarity**: Unclear which actor should call these services
- **Safety**: No compile-time guarantees for actor isolation
- **Maintainability**: Difficult to reason about concurrency behavior

### Issue #4: SettingsView - Task Usage Without Actor Coordination

**Location**: `Bridget/SettingsView.swift:96-149`
**Severity**: MEDIUM
**Risk**: UI Blocking, Error Propagation Issues

#### Problem Description
```swift
private func deleteAllBridgeData() {
    Task {
        do {
            // Multiple async operations without proper coordination
            try await deleteAllBridgeData()
            let eventCount = try modelContext.fetchCount(FetchDescriptor<DrawbridgeEvent>())
            await apiService.fetchAndStoreAllData(modelContext: modelContext)
        } catch {
            // Error handling on different actor
            errorMessage = error.localizedDescription
        }
    }
}
```

#### Issues Identified
1. **Task Coordination**: Multiple async operations not properly coordinated
2. **Actor Boundary Crossing**: ModelContext passed to API service
3. **Error Handling**: Errors handled across actor boundaries
4. **UI Blocking**: Long-running operations may block UI

#### Impact
- **User Experience**: UI may become unresponsive during operations
- **Error Handling**: Errors may not be properly propagated to UI
- **Data Consistency**: Risk of inconsistent state during operations

---

## Current Async Operations Analysis

### Network Operations
| Operation | Location | Actor Context | Risk Level |
|-----------|----------|---------------|------------|
| `fetchBatch` | OpenSeattleAPIService | @MainActor | HIGH |
| `fetchAndStoreAllData` | OpenSeattleAPIService | @MainActor | CRITICAL |
| `synchronizeData` | DataManager | None | HIGH |

### Data Operations
| Operation | Location | Actor Context | Risk Level |
|-----------|----------|---------------|------------|
| `fetchAllBridges` | DrawbridgeInfoService | None | MEDIUM |
| `fetchRoutes` | RouteService | None | MEDIUM |
| `fetchTrafficFlow` | TrafficFlowService | None | MEDIUM |
| `fetchEvents` | DrawbridgeEventService | None | MEDIUM |

### UI Operations
| Operation | Location | Actor Context | Risk Level |
|-----------|----------|---------------|------------|
| `deleteAllBridgeData` | SettingsView | @MainActor | MEDIUM |
| `BridgesListView` | UI Components | @MainActor | LOW |

---

## Actor Boundary Crossings Identified

### ModelContext Crossings
1. **OpenSeattleAPIService.fetchAndStoreAllData(modelContext:)**
   - ModelContext passed as parameter
   - Used in async network operations
   - **Risk**: HIGH - Potential data race

2. **SettingsView.deleteAllBridgeData()**
   - ModelContext accessed in Task
   - Passed to API service 