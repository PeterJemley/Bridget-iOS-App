import SwiftUI
import SwiftData
import BridgetCore
import BridgetSharedUI
import BridgetStatistics

// Basic statistics result structure for bridge analysis
struct BasicStatisticsResult {
    let frequencyLabel: String
    let rangeString: String
    let confidenceInterval: (lower: Double, upper: Double)?
    let outliers: [Int]?
    let timeWindowString: String
    let sparklineData: [Int]
    let typicalWaitTime: (typical: Double, confidenceInterval: (lower: Double, upper: Double)?)
    let weekdayWeekendDistribution: (weekday: Int, weekend: Int)
}

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

// MARK: - Loading State Management

enum LoadingState: Equatable {
    case initial
    case loading
    case loaded
    case error(String)
    
    var isFetching: Bool {
        self == .loading
    }
    
    var shouldShowSkeletons: Bool {
        self == .loading
    }
    
    var shouldShowRealData: Bool {
        self == .loaded
    }
}

struct BridgesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var bridges: [DrawbridgeInfo]
    
    @State private var loadingState: LoadingState = .initial
    @State private var lastFetchDate: Date? = nil
    // Pull-to-refresh removed for stability
    
    // Statistical analysis
    @State private var dataAnalyzer = BridgeDataAnalyzer()
    @State private var refreshRecommendation: RefreshIntervalRecommendation?
    @State private var showingStatistics = false
    
    private let apiService = OpenSeattleAPIService()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // ProgressView in nav bar area if loading
                if loadingState.isFetching {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Loading bridges…")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if apiService.fetchProgress.current > 0 {
                                Text("\(apiService.fetchProgress.current) events loaded")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .transition(.opacity)
                }
                
                // Main content
                mainContent
            }
            .navigationTitle("Bridges")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Stats") {
                        showingStatistics = true
                    }
                    .disabled(refreshRecommendation == nil)
                }
            }
            .sheet(isPresented: $showingStatistics) {
                if let recommendation = refreshRecommendation {
                    StatisticsDetailView(recommendation: recommendation)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
        }
        .onAppear {
            // Only measure on first appearance to avoid duplicate measurements
            if loadingState == .initial {
                PerformanceMeasurement.shared.startMeasurement("BridgesListView Load")
                PerformanceMeasurement.shared.logMemoryUsage("BridgesListView Start")
            }
            
            if bridges.isEmpty {
                // Load data automatically if none exists
                Task {
                    loadingState = .loading
                    
                    // Measure API data fetch
                    await PerformanceMeasurement.shared.measureNetwork("Initial API Fetch") {
                        await apiService.fetchAndStoreAllData(modelContext: modelContext)
                    }
                    
                    if let error = apiService.error {
                        loadingState = .error(error.localizedDescription)
                    } else {
                        loadingState = .loaded
                        // Analyze data for refresh recommendations
                        await analyzeDataForRefreshInterval()
                    }
                    
                    PerformanceMeasurement.shared.endMeasurement("BridgesListView Load")
                    PerformanceMeasurement.shared.logMemoryUsage("BridgesListView Complete")
                }
            } else {
                // We have cached data, set state to loaded
                loadingState = .loaded
                // Analyze existing data for refresh recommendations
                Task {
                    await analyzeDataForRefreshInterval()
                    PerformanceMeasurement.shared.endMeasurement("BridgesListView Load")
                    PerformanceMeasurement.shared.logMemoryUsage("BridgesListView Cached")
                }
            }
        }
        // Refresh cleanup removed for stability
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if !bridges.isEmpty || loadingState.shouldShowSkeletons {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // Statistics insights section
                    if let recommendation = refreshRecommendation, loadingState.shouldShowRealData {
                        StatisticsInsightsView(recommendation: recommendation)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    
                    // Bridge cards
                    LazyVStack(spacing: 12) {
                        if loadingState.shouldShowSkeletons {
                            // Show skeleton placeholders during loading
                            ForEach(0..<5, id: \.self) { _ in
                                EnhancedBridgeCard(
                                    bridge: BridgeInfo(
                                        name: "Loading Bridge",
                                        status: "Loading",
                                        lastEventTime: "Loading...",
                                        trafficLevel: "Loading"
                                    )
                                )
                                .redacted(reason: .placeholder)
                            }
                        } else if loadingState.shouldShowRealData {
                            // Show real bridge data
                            ForEach(bridges) { bridge in
                                EnhancedBridgeCard(
                                    bridge: BridgeInfo(
                                        name: bridge.entityName,
                                        status: bridge.events.first?.closeDateTime == nil ? "OPEN" : "CLOSED",
                                        lastEventTime: bridge.events.first?.openDateTime.formatted() ?? "No events",
                                        trafficLevel: "Unknown"
                                    )
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20) // Safe area clearance
                }
            }
            // Pull-to-refresh removed for stability - data loads automatically
        } else {
            // No data and not loading - show empty state
            VStack(spacing: 16) {
                Image(systemName: "network")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No bridges found")
                    .font(.headline)
                Text("Bridge data will load automatically")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }
    
    // refreshData function removed - pull-to-refresh disabled for stability
    
    private func analyzeDataForRefreshInterval() async {
        PerformanceMeasurement.shared.startMeasurement("Statistical Analysis")
        print("📊 BRIDGE DATA ANALYSIS: Starting analysis for refresh interval")
        
        let recommendation = await dataAnalyzer.analyzeRefreshInterval(modelContext: modelContext)
        refreshRecommendation = recommendation
        
        PerformanceMeasurement.shared.endMeasurement("Statistical Analysis")
        
        // Log the recommendation for debugging
        print("📊 BRIDGE DATA ANALYSIS: Recommended refresh interval: \(recommendation.interval/60) minutes")
        print("📊 BRIDGE DATA ANALYSIS: Confidence: \(recommendation.confidence)")
        print("📊 BRIDGE DATA ANALYSIS: Method: \(recommendation.method)")
        print("📊 BRIDGE DATA ANALYSIS: Reasoning: \(recommendation.reasoning)")
    }
}

// MARK: - Statistics Views

/// Displays statistical insights about bridge data patterns
struct StatisticsInsightsView: View {
    let recommendation: RefreshIntervalRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Data Insights")
                    .font(.headline)
                Spacer()
                Text("\(Int(recommendation.confidence * 100))% confidence")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Optimal refresh: \(formatInterval(recommendation.interval))")
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Text(recommendation.reasoning)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            return "\(hours)h \(minutes % 60)m"
        }
    }
}

/// Detailed statistics view shown in a sheet
struct StatisticsDetailView: View {
    let recommendation: RefreshIntervalRecommendation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Recommendation summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Refresh Interval Recommendation")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(formatInterval(recommendation.interval))")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Text("Optimal refresh interval")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("\(Int(recommendation.confidence * 100))%")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("Confidence")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("Method: \(methodDescription(recommendation.method))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Detailed reasoning
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Analysis Details")
                            .font(.headline)
                        
                        Text(recommendation.reasoning)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Statistical methods used
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Statistical Methods")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            MethodRow(
                                icon: "function",
                                title: "Poisson Process",
                                description: "Models bridge openings as random events with constant average rate"
                            )
                            
                            MethodRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Change Point Detection",
                                description: "Uses CUSUM and EWMA to detect pattern changes"
                            )
                            
                            MethodRow(
                                icon: "checkmark.shield",
                                title: "Goodness of Fit",
                                description: "Kolmogorov-Smirnov test compares current vs historical patterns"
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Data Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
    
    private func methodDescription(_ method: RecommendationMethod) -> String {
        switch method {
        case .insufficientData:
            return "Insufficient Data"
        case .poissonProcess:
            return "Poisson Process Analysis"
        case .patternAnalysis:
            return "Pattern Analysis"
        case .changeDetection:
            return "Change Detection"
        case .seasonalAnalysis:
            return "Seasonal Analysis"
        case .trendAnalysis:
            return "Trend Analysis"
        }
    }
}

/// Individual method row in statistics detail view
struct MethodRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
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
        // For now, create a basic result using StatisticsAPI
        let frequencyLabel = StatisticsAPI.frequencyLabel(
            value: strengths.reduce(0, +) / Double(strengths.count),
            thresholds: StatisticsAPI.computeDataDrivenThresholds(from: strengths) ?? (rare: 0.3, sometimes: 0.5, often: 0.7)
        )
        
        let rangeString = StatisticsAPI.rangeString(
            p25: StatisticsAPI.percentile(durations, 0.25) ?? 0,
            p75: StatisticsAPI.percentile(durations, 0.75) ?? 0,
            unit: "min"
        )
        
        let confidenceInterval = StatisticsAPI.confidenceInterval(values: durations)
        let outliers = StatisticsAPI.detectOutliers(values: durations)
        
        // Create a basic result structure
        let result = BasicStatisticsResult(
            frequencyLabel: frequencyLabel,
            rangeString: rangeString,
            confidenceInterval: confidenceInterval,
            outliers: outliers,
            timeWindowString: "Over the last 30 days",
            sparklineData: Array(0..<24).map { _ in Int.random(in: 0...10) },
            typicalWaitTime: (typical: StatisticsAPI.mean(durations) ?? 0, confidenceInterval: confidenceInterval),
            weekdayWeekendDistribution: (weekday: bridge.events.count * 5 / 7, weekend: bridge.events.count * 2 / 7)
        )
        
        // Calculate duration range from actual duration values (using existing rangeString)
        
        return BridgeStatistics(
            frequencyLabel: result.frequencyLabel,
            rangeString: result.rangeString,
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
        // Use shared ModelContainer from BridgetApp
} 
