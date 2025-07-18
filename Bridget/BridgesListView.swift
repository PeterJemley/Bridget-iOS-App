import SwiftUI
import SwiftData
import BridgetCore
import BridgetSharedUI
import BridgetStatistics

// Local event type for DateProvider conformance
struct TestEvent: DateProvider {
    let date: Date
}

// Reusable About section component
struct AboutSectionView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            // App Name with Laurel Decorations
            HStack(spacing: 8) {
                Image(systemName: "laurel.leading")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Bridget")
                    .font(.title)
                    .fontWeight(.bold)
                
                Image(systemName: "laurel.trailing")
                    .foregroundColor(.green)
                    .font(.title2)
            }
            
            // Catchphrase
            Text("Ditch the spanxiety: Bridge the gap between *you* and on time")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .italic()
            
            // Seattle Open Data API Link
            Link(destination: URL(string: "https://data.seattle.gov/Transportation/Drawbridge-Openings/3h5e-q24y")!) {
                HStack {
                    Image(systemName: "info.circle")
                    Text("Seattle Open Data API")
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

enum BridgesViewState {
    case loading
    case loaded
    case empty
    case error(String)
}

struct BridgesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var bridges: [DrawbridgeInfo]
    @EnvironmentObject private var apiService: OpenSeattleAPIService
    @State private var viewState: BridgesViewState = .loading
    @State private var lastFetchDate: Date? = nil
    @State private var debounceTask: Task<Void, Never>? = nil
    
    var body: some View {
        ZStack {
            switch viewState {
            case .loading:
                BrandingLoadingOverlay()
            case .loaded:
                NavigationView {
                    ZStack {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                if let lastFetchDate = lastFetchDate {
                                    Text("Last updated: \(lastFetchDate.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading)
                                }
                                LazyVStack(spacing: 16) {
                                    ForEach(bridges) { bridge in
                                        EnhancedBridgeCardView(bridge: bridge)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 8)
                            }
                        }
                        .refreshable {
                            await refreshData()
                        }
                    }
                    .navigationTitle("Bridges")
                }
            case .empty:
                NavigationView {
                    Text("No bridge data available.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .navigationTitle("Bridges")
                }
            case .error(let message):
                NavigationView {
                    VStack(spacing: 16) {
                        Text("Error loading data")
                            .font(.title3)
                            .foregroundColor(.red)
                        Text(message)
                            .font(.body)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task { await refreshData() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .navigationTitle("Bridges")
                }
            }
        }
        .onAppear {
            if case .loading = viewState {
                Task { await refreshData() }
            }
        }
    }
    
    private func refreshData() async {
        viewState = .loading
        await apiService.fetchAndStoreAllData(modelContext: modelContext)
        lastFetchDate = Date()
        if !bridges.isEmpty {
            viewState = .loaded
        } else {
            viewState = .empty
        }
    }
}

// New: Branding overlay for loading state
// NOTE: Use SwiftUI-only APIs for all UI, animation, and font scaling—no UIKit interop.
struct BrandingLoadingOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color(.systemBackground))
                .ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer(minLength: 60)
                // Branding near the top
                HStack(spacing: 8) {
                    Image(systemName: "laurel.leading")
                        .foregroundColor(.green)
                        .font(.title2)
                    Text("Bridget")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Image(systemName: "laurel.trailing")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                .padding(.top, 24)
                // Catchphrase (font size set to 22 for wrapping)
                Text("Ditch the spanxiety: Bridge the gap between you and on time")
                    .font(.system(size: 22))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .italic()
                    .padding(.horizontal)
                // Animated arrow with zero-code pulsing
                // (Arrow SF Symbol code removed)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct EnhancedBridgeCardView: View {
    let bridge: DrawbridgeInfo
    
    private var lastEvent: DrawbridgeEvent? {
        bridge.events.sorted(by: { $0.openDateTime > $1.openDateTime }).first
    }
    
    private var timeSinceLastEvent: String {
        guard let lastEvent = lastEvent else { return "No recent events" }
        let timeInterval = Date().timeIntervalSince(lastEvent.openDateTime)
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            return "Recently"
        }
    }
    
    private var bridgeStatus: String {
        guard let lastEvent = lastEvent else { return "UNKNOWN" }
        return lastEvent.closeDateTime != nil ? "CLOSED" : "OPEN"
    }
    
    private var trafficLevel: String {
        guard let lastEvent = lastEvent else { return "Unknown" }
        let duration = lastEvent.minutesOpen
        
        switch duration {
        case 0:
            return "Minimal"
        case 5..<10:
            return "Moderate"
        default:
            return "Heavy"
        }
    }
    
    private var bridgeStatistics: BridgeStatistics? {
        guard !bridge.events.isEmpty else { return nil }
        
        // Calculate cascade strengths from event durations for frequency analysis
        let strengths = bridge.events.map { event in
            // Normalize duration to 0-1 scale (assuming max 30 minutes)
            min(event.minutesOpen / 30.0, 1.0)
        }
        
        // Get actual durations for range calculation
        let durations = bridge.events.map { $0.minutesOpen }
        
        // Use our enhanced statistical service to compute insights
        let result = CascadeStatisticsService.compute(
            strengths: strengths,
            timeWindowDays: 30,
            events: bridge.events.map { TestEvent(date: $0.openDateTime) },
            durations: durations,
            useDataDrivenThresholds: true
        )
        
        // Calculate duration range from actual duration values
        let durationRangeString = StatisticsAPI.rangeString(
            p25: StatisticsAPI.percentile(durations, 0.25) ?? 0,
            p75: StatisticsAPI.percentile(durations, 0.75) ?? 0,
            unit: "min"
        )
        
        return BridgeStatistics(
            frequencyLabel: result.frequencyLabel,
            rangeString: durationRangeString,
            confidenceInterval: result.confidenceInterval,
            hasOutliers: result.outliers != nil && !result.outliers!.isEmpty,
            timeWindowString: result.timeWindowString,
            sparklineData: result.sparklineData,
            typicalWaitTime: result.typicalWaitTime,
            weekdayWeekendDistribution: result.weekdayWeekendDistribution
        )
    }
    
    // Compute contextual outlier info for the warning/drilldown
    private var outlierInfo: OutlierInfo? {
        guard let _ = bridgeStatistics, let lastEvent = lastEvent else { return nil }
        // Use the 25th and 75th percentiles as the normal range
        let durations = bridge.events.map { $0.minutesOpen }
        let p25 = StatisticsAPI.percentile(durations, 0.25) ?? 0
        let p75 = StatisticsAPI.percentile(durations, 0.75) ?? 0
        let actual = lastEvent.minutesOpen
        // Only flag as outlier if actual < p25 or actual > p75
        if actual < p25 {
            return OutlierInfo(
                bridgeName: bridge.entityName,
                actualValue: actual,
                normalRange: (p25, p75),
                timeWindow: "30 days",
                eventType: lastEvent.closeDateTime == nil ? "opening" : "closing",
                isHigh: false // shorter than normal
            )
        } else if actual > p75 {
            return OutlierInfo(
                bridgeName: bridge.entityName,
                actualValue: actual,
                normalRange: (p25, p75),
                timeWindow: "30 days",
                eventType: lastEvent.closeDateTime == nil ? "opening" : "closing",
                isHigh: true // longer than normal
            )
        } else {
            return nil // not an outlier
        }
    }
    
    var body: some View {
        EnhancedBridgeCard(
            bridge: BridgeInfo(
                name: bridge.entityName,
                status: bridgeStatus,
                lastEventTime: timeSinceLastEvent,
                trafficLevel: trafficLevel,
                duration: lastEvent.map { "\(Int($0.minutesOpen)) min" },
                openTime: lastEvent.map { $0.openDateTime.formatted(date: .omitted, time: .shortened) }
            ),
            statistics: bridgeStatistics
            , outlierInfo: outlierInfo
        )
    }
}

// Legacy components for backward compatibility
struct BridgeCardView: View {
    let bridge: DrawbridgeInfo
    
    private var lastEvent: DrawbridgeEvent? {
        bridge.events.sorted(by: { $0.openDateTime > $1.openDateTime }).first
    }
    
    private var timeSinceLastEvent: String {
        guard let lastEvent = lastEvent else { return "No recent events" }
        let timeInterval = Date().timeIntervalSince(lastEvent.openDateTime)
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            return "Recently"
        }
    }
    
    private var bridgeStatus: String {
        guard let lastEvent = lastEvent else { return "UNKNOWN" }
        return lastEvent.closeDateTime != nil ? "CLOSED" : "OPEN"
    }
    
    private var statusColor: Color {
        bridgeStatus == "OPEN" ? .red : .green
    }
    
    private var trafficLevel: (String, Color) {
        guard let lastEvent = lastEvent else { return ("Unknown", .gray) }
        let duration = lastEvent.minutesOpen
        
        switch duration {
        case 0:
            return ("Minimal", .green)
        case 5..<10:
            return ("Moderate", .orange)
        default:
            return ("Heavy", .red)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing:12) {
            // Bridge Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bridge.entityName)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(bridgeStatus)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor)
                    
                    Text(timeSinceLastEvent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(trafficLevel.0)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(trafficLevel.1.opacity(0.2))
                        .foregroundColor(trafficLevel.1)
                        .cornerRadius(8)
                    
                    if let lastEvent = lastEvent {
                        Text("\(Int(lastEvent.minutesOpen)) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(lastEvent.openDateTime, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Bridge Statistics
            if !bridge.events.isEmpty {
                HStack(spacing: 16) {
                    StatItem(title: "Total Events", value: "\(bridge.events.count)")
                    StatItem(title: "Avg Duration", value: "\(Int(bridge.events.reduce(0) { $0 + $1.minutesOpen } / Double(bridge.events.count))) min")
                    StatItem(title: "Last 24h", value: "\(bridge.events.filter { Date().timeIntervalSince($0.openDateTime) < 86400 }.count)")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    BridgesListView()
        .modelContainer(for: [DrawbridgeInfo.self], inMemory: true)
} 
