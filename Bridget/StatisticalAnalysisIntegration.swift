import Foundation
import SwiftUI
import SwiftData
import BridgetCore
import BridgetStatistics

/// Integration layer for the enhanced statistical analysis system
/// Provides easy-to-use methods for the main app to leverage data-driven refresh intervals
@Observable
class StatisticalAnalysisIntegration {
    private let analysisService: BridgeDataAnalysisService
    private let modelContext: ModelContext
    
    // MARK: - Observable Properties for UI
    var currentRecommendation: RefreshIntervalRecommendation?
    var currentInsights: BridgeDataInsights?
    var analysisState: AnalysisState?
    var isAnalyzing = false
    var lastAnalysisDate: Date?
    var error: Error?
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.analysisService = BridgeDataAnalysisService(modelContext: modelContext)
    }
    
    // MARK: - Public Interface
    
    /// Performs comprehensive analysis and updates all published properties
    @MainActor
    func performComprehensiveAnalysis() async {
        print("📊 INTEGRATION: Starting comprehensive analysis")
        isAnalyzing = true
        error = nil
        
        // Get current recommendation
        let recommendation = await analysisService.analyzeAndRecommendRefreshInterval()
        currentRecommendation = recommendation
        
        // Get detailed insights
        let insights = await analysisService.getDetailedInsights()
        currentInsights = insights
        
        // Get analysis state
        let state = analysisService.getCurrentAnalysisState()
        analysisState = state
        
        // Update timestamp
        lastAnalysisDate = Date()
        
        print("📊 INTEGRATION: Analysis completed successfully")
        print("📊 INTEGRATION: Recommended interval: \(recommendation.interval/60) minutes")
        print("📊 INTEGRATION: Confidence: \(recommendation.confidence)")
        print("📊 INTEGRATION: Method: \(recommendation.method)")
        
        isAnalyzing = false
    }
    
    /// Gets the optimal refresh interval based on current conditions
    func getOptimalRefreshInterval() -> TimeInterval {
        return currentRecommendation?.interval ?? 3600 // Default 1 hour
    }
    
    /// Gets human-readable explanation of the current recommendation
    func getRecommendationExplanation() -> String {
        return currentRecommendation?.reasoning ?? "No analysis available"
    }
    
    /// Gets confidence level in the current recommendation
    func getRecommendationConfidence() -> Double {
        return currentRecommendation?.confidence ?? 0.0
    }
    
    /// Checks if the current recommendation is based on sufficient data
    func hasSufficientData() -> Bool {
        return currentRecommendation?.method != .insufficientData
    }
    
    /// Gets current bridge activity summary
    func getActivitySummary() -> String {
        guard let insights = currentInsights else {
            return "No data available"
        }
        
        return "\(insights.totalEvents) total events, \(insights.currentlyOpen) currently open, avg \(String(format: "%.1f", insights.averageDuration)) min duration"
    }
    
    /// Gets peak activity hours
    func getPeakHours() -> [Int] {
        return currentInsights?.peakHours ?? []
    }
    
    /// Gets busy days of the week
    func getBusyDays() -> [Int] {
        return currentInsights?.busyDays ?? []
    }
    
    /// Checks if current time is during peak hours
    func isCurrentlyPeakHour() -> Bool {
        let currentHour = Calendar.current.component(.hour, from: Date())
        return getPeakHours().contains(currentHour)
    }
    
    /// Checks if current day is a busy day
    func isCurrentlyBusyDay() -> Bool {
        let currentWeekday = Calendar.current.component(.weekday, from: Date())
        return getBusyDays().contains(currentWeekday)
    }
    
    /// Gets urgency score for current conditions
    func getCurrentUrgencyScore() -> Double {
        guard let insights = currentInsights else { return 0.0 }
        
        var score = 0.0
        
        // Factor in currently open bridges
        score += Double(insights.currentlyOpen) * 0.2
        
        // Factor in peak hour status
        if isCurrentlyPeakHour() {
            score += 0.3
        }
        
        // Factor in busy day status
        if isCurrentlyBusyDay() {
            score += 0.2
        }
        
        // Factor in pattern stability
        if let state = analysisState {
            switch state.patternStability {
            case .veryUnstable:
                score += 0.3
            case .unstable:
                score += 0.2
            case .stable, .veryStable:
                score += 0.0
            case .unknown:
                score += 0.1
            }
        }
        
        return min(score, 1.0)
    }
    
    /// Gets recommended refresh interval adjusted for current urgency
    func getUrgencyAdjustedInterval() -> TimeInterval {
        let baseInterval = getOptimalRefreshInterval()
        let urgencyScore = getCurrentUrgencyScore()
        
        // Adjust interval based on urgency (higher urgency = shorter interval)
        let adjustmentFactor = 1.0 - (urgencyScore * 0.5) // Max 50% reduction
        let adjustedInterval = baseInterval * adjustmentFactor
        
        // Ensure minimum interval of 5 minutes
        return max(adjustedInterval, 300)
    }
    
    /// Gets formatted string for current refresh interval
    func getFormattedRefreshInterval() -> String {
        let interval = getUrgencyAdjustedInterval()
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
    
    /// Gets status summary for UI display
    func getStatusSummary() -> String {
        guard let recommendation = currentRecommendation else {
            return "Analysis not available"
        }
        
        let interval = getFormattedRefreshInterval()
        let confidence = Int(recommendation.confidence * 100)
        
        return "Refresh every \(interval) (confidence: \(confidence)%)"
    }
    
    /// Gets detailed status for debugging
    func getDetailedStatus() -> String {
        guard let recommendation = currentRecommendation,
              let insights = currentInsights else {
            return "No analysis data available"
        }
        
        var status = "📊 BRIDGE DATA ANALYSIS STATUS\n"
        status += "Recommended interval: \(getFormattedRefreshInterval())\n"
        status += "Confidence: \(Int(recommendation.confidence * 100))%\n"
        status += "Method: \(recommendation.method)\n"
        status += "Total events: \(insights.totalEvents)\n"
        status += "Currently open: \(insights.currentlyOpen)\n"
        status += "Average duration: \(String(format: "%.1f", insights.averageDuration)) minutes\n"
        status += "Peak hours: \(insights.peakHours.map(String.init).joined(separator: ", "))\n"
        status += "Busy days: \(insights.busyDays.map(String.init).joined(separator: ", "))\n"
        status += "Urgency score: \(String(format: "%.2f", getCurrentUrgencyScore()))\n"
        status += "Pattern stability: \(analysisState?.patternStability ?? .unknown)\n"
        status += "Seasonal patterns: \(analysisState?.seasonalPatterns ?? .none)\n"
        status += "Trend direction: \(analysisState?.trendDirection ?? .stable)\n"
        status += "Last analysis: \(lastAnalysisDate?.formatted() ?? "Never")"
        
        return status
    }
}

// MARK: - SwiftUI Integration

/// SwiftUI view that displays statistical analysis results
struct StatisticalAnalysisView: View {
    @State private var integration: StatisticalAnalysisIntegration
    @State private var showingDetails = false
    
    init(modelContext: ModelContext) {
        self._integration = State(initialValue: StatisticalAnalysisIntegration(modelContext: modelContext))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Data-Driven Refresh Analysis")
                    .font(.headline)
                Spacer()
                Button("Analyze") {
                    Task {
                        await integration.performComprehensiveAnalysis()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(integration.isAnalyzing)
            }
            
            if integration.isAnalyzing {
                ProgressView("Analyzing bridge data...")
                    .frame(maxWidth: .infinity)
            } else if let error = integration.error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Analysis Error")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else if integration.hasSufficientData() {
                // Analysis Results
                VStack(spacing: 12) {
                    // Current recommendation
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Recommended Refresh")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(integration.getFormattedRefreshInterval())
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Confidence")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(Int(integration.getRecommendationConfidence() * 100))%")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(confidenceColor)
                        }
                    }
                    
                    // Activity summary
                    HStack {
                        Image(systemName: "bridge.fill")
                            .foregroundColor(.green)
                        Text(integration.getActivitySummary())
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    // Current conditions
                    HStack {
                        if integration.isCurrentlyPeakHour() {
                            Label("Peak Hour", systemImage: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        if integration.isCurrentlyBusyDay() {
                            Label("Busy Day", systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                        
                        Text("Urgency: \(String(format: "%.1f", integration.getCurrentUrgencyScore()))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Explanation
                    Text(integration.getRecommendationExplanation())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
                
                // Details button
                Button("Show Detailed Analysis") {
                    showingDetails = true
                }
                .buttonStyle(.bordered)
            } else {
                // Insufficient data
                VStack {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(.gray)
                        .font(.title)
                    Text("Insufficient Data")
                        .font(.headline)
                    Text("Need more bridge events to perform analysis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .sheet(isPresented: $showingDetails) {
            NavigationView {
                ScrollView {
                    Text(integration.getDetailedStatus())
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
                .navigationTitle("Detailed Analysis")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingDetails = false
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await integration.performComprehensiveAnalysis()
            }
        }
    }
    
    private var confidenceColor: Color {
        let confidence = integration.getRecommendationConfidence()
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Preview
#Preview {
    // Use shared ModelContainer from BridgetApp
    StatisticalAnalysisView(modelContext: ModelContext(try! ModelContainer(for: DrawbridgeEvent.self, DrawbridgeInfo.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))))
} 