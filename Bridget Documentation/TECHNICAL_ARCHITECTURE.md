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

*This technical architecture document provides the foundation for a robust, scalable, and maintainable Bridget app, supporting the proactive, stepwise rebuild plan.* 