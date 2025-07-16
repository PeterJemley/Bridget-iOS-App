# 🛠️ **Bridget Rebuild Implementation Guide**

**Created**: January 2025
**Purpose**: Practical implementation guide for the Bridget Proactive Rebuild Plan
**Companion**: Works with PROACTIVE_REBUILD_PLAN.md
**Approach**: Step-by-step instructions with code templates and commands

---

## 📋 **Quick Start Checklist**

### **Pre-Implementation Setup**
- [ ] **Environment**: Xcode 16.4+, iOS 18.5+ target, Swift 6.0+
- [ ] **Documentation**: Read PROACTIVE_REBUILD_PLAN.md completely
- [ ] **Tools**: SwiftLint, SwiftFormat, Git hooks configured
- [ ] **Resources**: Access to Apple Developer account, App Store Connect
- [ ] **Testing**: Physical iOS devices for motion/location testing

### **Phase 0 Preparation**
- [ ] **Backup**: Current Bridget project backed up
- [ ] **Clean Slate**: New Xcode project workspace ready
- [ ] **Architecture**: Module dependencies mapped out
- [ ] **Data Models**: Core SwiftData models designed
- [ ] **Development Environment**: All tools configured

---

## 🚀 **Phase 0: Foundation & Planning Implementation**

### **0.1 Project Setup Commands**

#### **Create New Xcode Project**
```bash
# Create new Bridget project
mkdir Bridget-Rebuild
cd Bridget-Rebuild

# Create Xcode project with SwiftUI template
# Target: iOS 18.5+, Swift 6.0+, SwiftUI App
# Enable: SwiftData, SwiftData (for migration)
```

#### **Setup Swift Package Manager Modules**
```bash
# Create package structure
mkdir -p Packages
cd Packages

# Core packages
swift package init --name BridgetCore --type library
swift package init --name BridgetNetworking --type library
swift package init --name BridgetSharedUI --type library
swift package init --name BridgetDashboard --type library
swift package init --name BridgetBridgesList --type library
swift package init --name BridgetBridgeDetail --type library
swift package init --name BridgetRouting --type library
swift package init --name BridgetStatistics --type library
swift package init --name BridgetHistory --type library
swift package init --name BridgetSettings --type library

# Add packages to Xcode project
# File > Add Package Dependencies > Add Local...
```

#### **Configure Development Environment**
```bash
# Install SwiftLint
brew install swiftlint

# Install SwiftFormat
brew install swiftformat

# Create .swiftlint.yml
cat > .swiftlint.yml << EOF
disabled_rules:
  - trailing_whitespace
  - line_length
  - function_body_length
  - type_body_length

opt_in_rules:
  - empty_count
  - force_unwrapping
  - implicitly_unwrapped_optional
  - overridden_super_call
  - redundant_nil_coalescing
  - sorted_imports
  - vertical_whitespace

included:
  - Bridget
  - Packages

excluded:
  - BridgetTests
  - BridgetUITests
EOF

# Create .swiftformat
cat > .swiftformat << EOF
--indent 4
--maxwidth 120
--wraparguments before-first
--wrapparameters before-first
--wraptypealiases before-first
--wrapcollections before-first
--trimwhitespace always
--insertlines enabled
--removelines enabled
--allman false
--header strip
--lineaftermarks enabled
--linebeforemarks enabled
--marktypes enabled
--semicolons never
--commas always
--decimalgrouping 3,4
--binarygrouping 4,8
--octalgrouping 4,8
--hexgrouping 4,8
--fractiongrouping enabled
--exponentgrouping enabled
--hexliteralcase uppercase
--exponentcase lowercase
--decimalgroupingseparator "_"
--binarygroupingseparator "_"
--octalgroupingseparator "_"
--hexgroupingseparator "_"
--fractiongroupingseparator "_"
--exponentgroupingseparator "_"
EOF

# Setup Git hooks
mkdir -p .git/hooks
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
# Pre-commit hook for code quality

echo "Running SwiftLint..."
swiftlint lint --quiet

if [ $? -ne 0 ]; then
    echo "SwiftLint found issues. Please fix them before committing."
    exit 1
fi

echo "Running SwiftFormat..."
swiftformat .

echo "Pre-commit checks passed!"
EOF

chmod +x .git/hooks/pre-commit
```

### **0.2 Data Architecture Implementation**

#### **Core SwiftData Models Template**
```swift
// BridgetCore/Sources/BridgetCore/Models/DrawbridgeEvent.swift
import Foundation
import SwiftData

@Model
public final class DrawbridgeEvent {
    @Attribute(.unique) public var id: UUID
    @Attribute(.indexed) public var entityID: String
    @Attribute(.indexed) public var entityName: String
    public var entityType: String
    @Attribute(.indexed) public var openDateTime: Date
    public var closeDateTime: Date?
    public var minutesOpen: Double
    public var latitude: Double
    public var longitude: Double
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        entityID: String,
        entityName: String,
        entityType: String,
        openDateTime: Date,
        closeDateTime: Date? = nil,
        minutesOpen: Double = 0.0,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.entityID = entityID
        self.entityName = entityName
        self.entityType = entityType
        self.openDateTime = openDateTime
        self.closeDateTime = closeDateTime
        self.minutesOpen = minutesOpen
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// BridgetCore/Sources/BridgetCore/Models/Route.swift
@Model
public final class Route {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var startLocation: String
    public var endLocation: String
    public var bridges: [String] // Bridge IDs along route
    public var isFavorite: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        startLocation: String,
        endLocation: String,
        bridges: [String] = [],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.bridges = bridges
        self.isFavorite = isFavorite
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// BridgetCore/Sources/BridgetCore/Models/TrafficFlow.swift
@Model
public final class TrafficFlow {
    @Attribute(.unique) public var id: UUID
    @Attribute(.indexed) public var bridgeID: String
    @Attribute(.indexed) public var timestamp: Date
    public var congestionLevel: Double
    public var trafficVolume: Double
    public var correlationScore: Double

    public init(
        id: UUID = UUID(),
        bridgeID: String,
        timestamp: Date = Date(),
        congestionLevel: Double,
        trafficVolume: Double,
        correlationScore: Double = 0.0
    ) {
        self.id = id
        self.bridgeID = bridgeID
        self.timestamp = timestamp
        self.congestionLevel = congestionLevel
        self.trafficVolume = trafficVolume
        self.correlationScore = correlationScore
    }
}
```

#### **ModelContainer Configuration**
```swift
// BridgetApp.swift
import SwiftUI
import SwiftData

@main
struct BridgetApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                DrawbridgeEvent.self,
                DrawbridgeInfo.self,
                Route.self,
                TrafficFlow.self,
                BridgeAnalytics.self,
                TrendData.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .automatic
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(modelContainer)
    }
}
```

---

## 🏗️ **Phase 1: Core Infrastructure Implementation**

### **1.1 BridgetCore Package Implementation**

#### **Data Services Template**
```swift
// BridgetCore/Sources/BridgetCore/Services/DrawbridgeEventService.swift
import Foundation
import SwiftData

public protocol DrawbridgeEventServiceProtocol {
    func fetchEvents(for bridgeID: String?) async throws -> [DrawbridgeEvent]
    func saveEvent(_ event: DrawbridgeEvent) async throws
    func deleteEvent(_ event: DrawbridgeEvent) async throws
    func updateEvent(_ event: DrawbridgeEvent) async throws
}

public class DrawbridgeEventService: DrawbridgeEventServiceProtocol {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func fetchEvents(for bridgeID: String? = nil) async throws -> [DrawbridgeEvent] {
        let descriptor = FetchDescriptor<DrawbridgeEvent>(
            predicate: bridgeID.map { bridgeID in
                #Predicate<DrawbridgeEvent> { event in
                    event.entityID == bridgeID
                }
            },
            sortBy: [SortDescriptor(\.openDateTime, order: .reverse)]
        )
        descriptor.fetchLimit = 100

        return try modelContext.fetch(descriptor)
    }

    public func saveEvent(_ event: DrawbridgeEvent) async throws {
        modelContext.insert(event)
        try modelContext.save()
    }

    public func deleteEvent(_ event: DrawbridgeEvent) async throws {
        modelContext.delete(event)
        try modelContext.save()
    }

    public func updateEvent(_ event: DrawbridgeEvent) async throws {
        event.updatedAt = Date()
        try modelContext.save()
    }
}
```

#### **Error Handling Implementation**
```swift
// BridgetCore/Sources/BridgetCore/Errors/BridgetDataError.swift
import Foundation

public enum BridgetDataError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case invalidData(String)
    case networkError(Error)
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// BridgetCore/Sources/BridgetCore/Logging/SecurityLogger.swift
import Foundation
import os.log

public class SecurityLogger {
    private static let logger = Logger(subsystem: "com.bridget.app", category: "security")

    public static func info(_ message: String) {
        logger.info("\(message)")
    }

    public static func error(_ message: String, error: Error? = nil) {
        if let error = error {
            logger.error("\(message): \(error.localizedDescription)")
        } else {
            logger.error("\(message)")
        }
    }

    public static func debug(_ message: String) {
        logger.debug("\(message)")
    }
}
```

### **1.2 BridgetNetworking Package Implementation**

#### **API Client Template**
```swift
// BridgetNetworking/Sources/BridgetNetworking/API/DrawbridgeAPI.swift
import Foundation

public protocol DrawbridgeAPIProtocol {
    func fetchBridgeEvents() async throws -> [DrawbridgeEventDTO]
    func fetchBridgeInfo() async throws -> [DrawbridgeInfoDTO]
}

public class DrawbridgeAPI: DrawbridgeAPIProtocol {
    private let session: URLSession
    // Open Seattle API: SDOT Drawbridge Status
    // https://data.seattle.gov/Transportation/SDOT-Drawbridge-Status/gm8h-9449/about_data
    private let baseURL = URL(string: "https://data.seattle.gov/resource/gm8h-9449.json")!

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchBridgeEvents() async throws -> [DrawbridgeEventDTO] {
        // Open Seattle API endpoint for drawbridge status
        // Returns JSON array of bridge events with fields:
        // - entity_id: Bridge identifier
        // - entity_name: Bridge name  
        // - entity_type: Type of bridge
        // - open_date_time: When bridge opened
        // - close_date_time: When bridge closed (nullable)
        // - minutes_open: Duration bridge was open
        // - latitude: Bridge location
        // - longitude: Bridge location
        let (data, response) = try await session.data(from: baseURL)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BridgetDataError.networkError(NSError(domain: "API", code: -1))
        }

        return try JSONDecoder().decode([DrawbridgeEventDTO].self, from: data)
    }

    public func fetchBridgeEventsWithFilter(limit: Int = 100, offset: Int = 0) async throws -> [DrawbridgeEventDTO] {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "$limit", value: "\(limit)"),
            URLQueryItem(name: "$offset", value: "\(offset)"),
            URLQueryItem(name: "$order", value: "open_date_time DESC")
        ]
        
        let (data, response) = try await session.data(from: components.url!)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BridgetDataError.networkError(NSError(domain: "API", code: -1))
        }

        return try JSONDecoder().decode([DrawbridgeEventDTO].self, from: data)
    }

    public func fetchBridgeInfo() async throws -> [DrawbridgeInfoDTO] {
        // For bridge info, we can use the same endpoint with different filters
        // or create a separate endpoint if needed
        return try await fetchBridgeEvents().map { event in
            DrawbridgeInfoDTO(
                id: event.entityID,
                entityID: event.entityID,
                entityName: event.entityName,
                entityType: event.entityType,
                latitude: event.latitude,
                longitude: event.longitude
            )
        }
    }
}

// DTOs for API responses matching Open Seattle API format
public struct DrawbridgeEventDTO: Codable {
    public let entityID: String
    public let entityName: String
    public let entityType: String
    public let openDateTime: String // ISO date string from API
    public let closeDateTime: String? // ISO date string, nullable
    public let minutesOpen: String? // String representation from API
    public let latitude: String? // String representation from API
    public let longitude: String? // String representation from API
    
    enum CodingKeys: String, CodingKey {
        case entityID = "entity_id"
        case entityName = "entity_name"
        case entityType = "entity_type"
        case openDateTime = "open_date_time"
        case closeDateTime = "close_date_time"
        case minutesOpen = "minutes_open"
        case latitude
        case longitude
    }

    public func toModel() -> DrawbridgeEvent {
        let formatter = ISO8601DateFormatter()
        let openDate = formatter.date(from: openDateTime) ?? Date()
        let closeDate = closeDateTime.flatMap { formatter.date(from: $0) }
        
        // Convert string values to appropriate types
        let minutesOpenValue = Double(minutesOpen ?? "0") ?? 0.0
        let latitudeValue = Double(latitude ?? "0") ?? 0.0
        let longitudeValue = Double(longitude ?? "0") ?? 0.0

        return DrawbridgeEvent(
            entityID: entityID,
            entityName: entityName,
            entityType: entityType,
            openDateTime: openDate,
            closeDateTime: closeDate,
            minutesOpen: minutesOpenValue,
            latitude: latitudeValue,
            longitude: longitudeValue
        )
    }
}
```

### **1.3 BridgetSharedUI Package Implementation**

#### **Atomic Design Components**
```swift
// BridgetSharedUI/Sources/BridgetSharedUI/Atoms/BridgetButton.swift
import SwiftUI

public struct BridgetButton: View {
    public enum Style {
        case primary
        case secondary
        case destructive
    }

    public let title: String
    public let style: Style
    public let action: () -> Void

    public init(_ title: String, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(foregroundColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(backgroundColor)
                .cornerRadius(8)
        }
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to activate")
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .blue
        case .secondary:
            return .gray.opacity(0.2)
        case .destructive:
            return .red
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .primary
        case .destructive:
            return .white
        }
    }
}

// BridgetSharedUI/Sources/BridgetSharedUI/Molecules/BridgetCard.swift
public struct BridgetCard<Content: View>: View {
    public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .accessibilityElement(children: .combine)
    }
}
```

---

## 🧪 **Testing Implementation**

### **Unit Testing Template**
```swift
// BridgetCore/Tests/BridgetCoreTests/DrawbridgeEventServiceTests.swift
import XCTest
import SwiftData
@testable import BridgetCore

@MainActor
final class DrawbridgeEventServiceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: DrawbridgeEventService!

    override func setUp() async throws {
        let schema = Schema([DrawbridgeEvent.self])
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
        service = DrawbridgeEventService(modelContext: modelContext)
    }

    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        service = nil
    }

    func testSaveEvent() async throws {
        // Given
        let event = DrawbridgeEvent(
            entityID: "test-bridge",
            entityName: "Test Bridge",
            entityType: "drawbridge",
            openDateTime: Date(),
            latitude: 47.6062,
            longitude: -122.3321
        )

        // When
        try await service.saveEvent(event)

        // Then
        let events = try await service.fetchEvents()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.entityID, "test-bridge")
    }

    func testFetchEventsForSpecificBridge() async throws {
        // Given
        let event1 = DrawbridgeEvent(
            entityID: "bridge-1",
            entityName: "Bridge 1",
            entityType: "drawbridge",
            openDateTime: Date(),
            latitude: 47.6062,
            longitude: -122.3321
        )

        let event2 = DrawbridgeEvent(
            entityID: "bridge-2",
            entityName: "Bridge 2",
            entityType: "drawbridge",
            openDateTime: Date(),
            latitude: 47.6062,
            longitude: -122.3321
        )

        try await service.saveEvent(event1)
        try await service.saveEvent(event2)

        // When
        let events = try await service.fetchEvents(for: "bridge-1")

        // Then
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.entityID, "bridge-1")
    }
}
```

---

## 🎨 **Phase 2: User Interface Implementation**

### **Main Tab View Implementation**
```swift
// Bridget/Sources/Bridget/Views/MainTabView.swift
import SwiftUI

public struct MainTabView: View {
    public init() {}

    public var body: some View {
        TabView {
            DashboardTabView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            RoutesTabView()
                .tabItem {
                    Label("Routes", systemImage: "map.fill")
                }

            HistoryTabView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }

            StatisticsTabView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .accessibilityIdentifier("MainTabView")
    }
}

// BridgetDashboard/Sources/BridgetDashboard/Views/DashboardTabView.swift
import SwiftUI
import SwiftData

public struct DashboardTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [DrawbridgeEvent]

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(events) { event in
                        BridgeStatusCard(event: event)
                    }
                }
                .padding()
            }
            .navigationTitle("Bridge Status")
            // NOTE: As of the latest update, pull-to-refresh functionality has been removed from the Bridget app. Data is now loaded automatically when views appear and can be refreshed only through explicit user actions (such as tapping a refresh button or performing a specific action). This change was made to improve accessibility (especially for users with motor impairments), increase reliability, and simplify the user experience. All references to pull-to-refresh should be considered legacy and are no longer part of the supported UX.
        }
    }
}

// BridgetSharedUI/Sources/BridgetSharedUI/Organisms/BridgeStatusCard.swift
public struct BridgeStatusCard: View {
    public let event: DrawbridgeEvent

    public init(event: DrawbridgeEvent) {
        self.event = event
    }

    public var body: some View {
        BridgetCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(event.entityName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    StatusIndicator(isOpen: event.closeDateTime == nil)
                }

                if let closeDateTime = event.closeDateTime {
                    Text("Closed at \(closeDateTime, style: .time)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Opened at \(event.openDateTime, style: .time)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Label("\(event.minutesOpen, specifier: "%.1f") min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Label("\(event.latitude, specifier: "%.4f"), \(event.longitude, specifier: "%.4f")",
                          systemImage: "location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bridge status for \(event.entityName)")
        .accessibilityHint("Double tap for details")
    }
}

private struct StatusIndicator: View {
    public let isOpen: Bool

    public var body: some View {
        Circle()
            .fill(isOpen ? Color.red : Color.green)
            .frame(width: 12, height: 12)
            .accessibilityLabel(isOpen ? "Bridge is open" : "Bridge is closed")
    }
}
```

---

## 📋 **Implementation Commands & Scripts**

### **Build and Test Commands**
```bash
# Build all packages
xcodebuild -scheme Bridget -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Run all tests
xcodebuild -scheme Bridget -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test

# Build specific package
swift build -p BridgetCore

# Test specific package
swift test -p BridgetCore

# Run SwiftLint
swiftlint lint --reporter html --output swiftlint-report.html

# Run SwiftFormat
swiftformat . --verbose

# Generate documentation
xcodebuild docbuild -scheme Bridget -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### **Development Workflow Scripts**
```bash
# Create new feature branch
git checkout -b feature/phase-1-core-infrastructure

# Run pre-commit checks
./Scripts/pre-commit.sh

# Run full test suite
./Scripts/run-tests.sh

# Generate test coverage report
./Scripts/coverage-report.sh

# Build for release
./Scripts/build-release.sh
```

### **Quality Assurance Scripts**
```bash
#!/bin/bash
# Scripts/pre-commit.sh
echo "Running pre-commit checks..."

# SwiftLint
echo "Running SwiftLint..."
swiftlint lint --quiet
if [ $? -ne 0 ]; then
    echo "❌ SwiftLint found issues"
    exit 1
fi

# SwiftFormat
echo "Running SwiftFormat..."
swiftformat . --lint
if [ $? -ne 0 ]; then
    echo "❌ SwiftFormat found issues"
    exit 1
fi

# Build check
echo "Building project..."
xcodebuild -scheme Bridget -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build -quiet
if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ All pre-commit checks passed!"
```

---

## 🎯 **Success Validation Checklist**

### **Phase 0 Validation**
- [ ] Project compiles without errors
- [ ] All packages properly linked
- [ ] SwiftData models working correctly
- [ ] Development environment configured
- [ ] Git hooks functional

### **Phase 1 Validation**
- [ ] All core packages implemented
- [ ] Data services functional
- [ ] Network layer working
- [ ] UI components accessible
- [ ] 95%+ test coverage achieved

### **Phase 2 Validation**
- [ ] Main app launches successfully
- [ ] Tab navigation working
- [ ] Dashboard displaying data
- [ ] All views accessible
- [ ] Performance benchmarks met

### **Overall Quality Gates**
- [ ] 0 critical issues
- [ ] <5 minor issues
- [ ] 95%+ test coverage
- [ ] 100% accessibility compliance
- [ ] Performance targets met
- [ ] Security audit passed

---

## 📚 **Reference Documentation**

### **Key Files to Reference**
- `PROACTIVE_REBUILD_PLAN.md` - Complete rebuild plan
- `TECHNOLOGY_GUIDE.md` - Apple technologies reference
- `SWIFTDATA_GUIDE.md` - SwiftData implementation guide
- `FEATURES.md` - Feature specifications
- `DEVELOPMENT_WORKFLOW_GUIDE.md` - Development process

### **External Resources**
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/SwiftUI)
- [SwiftData Guide](https://developer.apple.com/documentation/swiftdata)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

*This implementation guide provides practical steps, code templates, and commands to execute the Bridget Proactive Rebuild Plan successfully.*

---

## 🕵️ Deep Audit Checklist & Implementation Guidance

This section summarizes the critical findings from the deep audit and provides actionable steps for implementation. For architectural rationale, see the 'Deep Audit Findings & Advanced Recommendations' section in TECHNICAL_ARCHITECTURE.md.

### 1. Error Handling & Transactional Saves
- Ensure all `modelContext.save()` calls are wrapped in `do/catch` and consider using transactional closures or blocks for multi-step operations.
- Define rollback/recovery strategies for failed saves. Document these in code comments and contributor guides.

### 2. Merge Policy & Conflict Resolution
- The app currently uses the default SwiftData merge policy ("last write wins").
- This is safe for single-context/main-actor use, but may cause silent data loss or overwrites if background imports or multiple contexts are introduced.
- **Action:**
    - Document this default in code and docs.
    - If background contexts are added, explicitly set and test `ModelContext.mergePolicy` (e.g., `.mergeByPropertyObjectTrump` or `.mergeByPropertyStoreTrump`) and add conflict resolution hooks/logging.
    - Add a TODO/warning in code: "If background imports or multiple ModelContexts are introduced, explicitly set and test ModelContext.mergePolicy to avoid data loss or silent overwrites."

- **Why Explicit Merge Policy Matters:** Relying on SwiftData's default ("last write wins") can silently drop changes as you scale to multiple contexts (e.g., background imports, child contexts). Explicitly configuring a merge policy avoids silent data loss, documents your intent (UI vs. server authority), and enables robust conflict testing.
- **How to Set a Merge Policy:**
```swift
let config = ModelConfiguration(
  containerName: "BridgetModel",
  mergePolicy: .mergeByPropertyObjectTrump // or .mergeByPropertyStoreTrump
)
```
- For background/child contexts:
```swift
let backgroundContext = container.createBackgroundContext(
  mergePolicy: .mergeByPropertyStoreTrump
)
```
- **Testing Your Merge Strategy:** Add unit tests that simulate two contexts racing to update the same entity, saving in different orders, and asserting the final value matches your policy.
- **Next Steps:**
    1. Pick & document the merge policy that matches your UX expectations.
    2. Centralize configuration so all contexts use the right policy.
    3. Add conflict tests to protect against regressions.
    4. Review all child/background contexts for correct policy inheritance.

### 3. Change Notification Throttling
- Profile UI performance during large imports. If UI stutter is observed, batch notifications or use `withAnimation(.none)` to throttle updates.

- **Change Notification Throttling:** Large data imports (e.g., full event/bridge refresh) are now wrapped in `withAnimation(.none)` in `OpenSeattleAPIService` to suppress SwiftUI diffing/animation and reduce UI stutter during large inserts/deletes. This minimizes the performance impact of SwiftData change notifications. Profile UI responsiveness as data volumes grow.

- **Memory Usage During Import:** The import logic now uses a stream-parse-insert pattern: each batch of API data is processed and inserted as it arrives, rather than accumulating all responses in memory. This minimizes memory usage and improves scalability. Only minimal state (e.g., a bridge map) is kept in memory. See OpenSeattleAPIService for implementation details.

- **FetchDescriptor Selectivity:** All fetches currently load full model objects (all fields/properties). For existence checks or lightweight queries, use field projection in FetchDescriptor (if/when supported by SwiftData) to fetch only the fields you need (e.g., just the id or entityID). Document this pattern and encourage contributors to monitor for new SwiftData APIs that allow more granular field selection. This will help reduce memory usage and improve query performance as data grows.

- **SwiftUI Context Save Semantics:** All SwiftUI views that mutate the modelContext (insert/delete) are now required to call modelContext.save() explicitly after the mutation. This ensures changes are persisted immediately and avoids relying on implicit or parent-driven saves, which can lead to data loss. See AddRouteView and AddTrafficFlowView for code examples and rationale.

### 6. Advanced Recommendations
- Use batch delete (e.g., `NSBatchDeleteRequest`) for full data replacements, especially if CloudKit is used.
- Adopt transactional blocks for multi-step imports/updates.
- Add instrumentation/metrics for batch sizes, save durations, and memory use. Monitor these metrics over time to guide further optimization.

- **Batch Delete:** SwiftData now supports true batch deletes via ModelContext.delete(model:where:includeSubentities:). Use this API for all full data replacements and conditional deletes (e.g., delete all events, delete events older than X). This is more efficient than per-object delete loops and does not require NSBatchDeleteRequest unless you are interoperating with legacy Core Data. See OpenSeattleAPIService and all core data services for code examples and rationale.

- **Transactional Blocks:** SwiftData now supports true transactional blocks via modelContext.transaction { ... } (iOS 18+/SwiftData 1.1+). Use this API for all multi-step imports/updates to ensure atomicity and rollback. No need to call save() inside the block; the transaction auto-commits on success and rolls back on error. For pre-iOS 18 or legacy environments, fallback to per-operation save() and document the limitation. Reference OpenSeattleAPIService for code example and rationale.

---

### SwiftData Import Refactor (2025-07-15)

- **Pattern:**
    1. Fetch all data from the network (async) and accumulate responses.
    2. Enter a single SwiftData transaction block to perform all deletes/inserts/updates (sync, no await).
- **Why:** SwiftData's transaction block is synchronous and must not contain any `await` calls. This ensures atomicity, rollback, and thread safety.
- **Reference:** See `TECHNICAL_ARCHITECTURE.md` and `OpenSeattleAPIService.swift` for rationale and implementation.
- **Alternative:** For large datasets, use a batch-streaming approach: fetch and transact in mini-batches to reduce memory usage.