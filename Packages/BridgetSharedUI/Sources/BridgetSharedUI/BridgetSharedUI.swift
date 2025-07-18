// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

/// A reusable, HIG-compliant loading overlay for indeterminate API loading states.
public struct LoadingOverlayView: View {
    public var label: String
    public var body: some View {
        ZStack {
            Color.black
                .opacity(0.3)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView(label)
                    .progressViewStyle(.circular)
                    .accessibilityLabel(Text(label))
            }
        }
        .transition(.opacity)
        .accessibilityElement(children: .combine)
    }
    public init(label: String = "Loading data…") {
        self.label = label
    }
}

/// A HIG-compliant content unavailable view for empty states.
public struct ContentUnavailableView: View {
    public let title: String
    public let systemImage: String
    public let description: Text
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            description
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
    
    public init(_ title: String, systemImage: String, description: Text) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
    }
}

/// A HIG-compliant statistics card for displaying statistical insights.
public struct StatisticsCard: View {
    public let title: String
    public let primaryValue: String
    public let primaryLabel: String
    public let secondaryValue: String?
    public let secondaryLabel: String?
    public let frequencyLabel: String?
    public let confidenceInterval: (lower: Double, upper: Double)?
    public let hasOutliers: Bool
    public let timeWindow: String
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let frequencyLabel = frequencyLabel {
                    FrequencyBadge(label: frequencyLabel)
                }
            }
            
            // Primary Statistics
            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(primaryValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(primaryLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let secondaryValue = secondaryValue {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(secondaryValue)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(secondaryLabel ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Confidence Interval (if available)
            if let confidenceInterval = confidenceInterval {
                ConfidenceIntervalView(interval: confidenceInterval)
            }
            
            // Outlier Indicator
            if hasOutliers {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Unusual data detected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Time Window
            Text(timeWindow)
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
    }
    
    public init(
        title: String,
        primaryValue: String,
        primaryLabel: String,
        secondaryValue: String? = nil,
        secondaryLabel: String? = nil,
        frequencyLabel: String? = nil,
        confidenceInterval: (lower: Double, upper: Double)? = nil,
        hasOutliers: Bool = false,
        timeWindow: String
    ) {
        self.title = title
        self.primaryValue = primaryValue
        self.primaryLabel = primaryLabel
        self.secondaryValue = secondaryValue
        self.secondaryLabel = secondaryLabel
        self.frequencyLabel = frequencyLabel
        self.confidenceInterval = confidenceInterval
        self.hasOutliers = hasOutliers
        self.timeWindow = timeWindow
    }
}

/// A HIG-compliant frequency badge for displaying frequency labels.
public struct FrequencyBadge: View {
    public let label: String
    
    private var badgeColor: Color {
        switch label.lowercased() {
        case "low":
            return .green
        case "medium":
            return .orange
        case "high":
            return .red
        default:
            return .gray
        }
    }
    
    public var body: some View {
        Text(label)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.2))
            .foregroundColor(badgeColor)
            .cornerRadius(8)
            .accessibilityLabel("Frequency: \(label)")
    }
    
    public init(label: String) {
        self.label = label
    }
}

/// A HIG-compliant confidence interval view.
public struct ConfidenceIntervalView: View {
    public let interval: (lower: Double, upper: Double)
    
    public var body: some View {
        HStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundColor(.blue)
                .font(.caption)
            
            Text("Confidence: \(String(format: "%.1f", interval.lower)) - \(String(format: "%.1f", interval.upper))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityLabel("Confidence interval from \(String(format: "%.1f", interval.lower)) to \(String(format: "%.1f", interval.upper))")
    }
    
    public init(interval: (lower: Double, upper: Double)) {
        self.interval = interval
    }
}

/// A HIG-compliant enhanced bridge card with statistical insights.
public struct EnhancedBridgeCard: View {
    public let bridge: BridgeInfo
    public let statistics: BridgeStatistics?
    // New: contextual outlier info
    public let outlierInfo: OutlierInfo?
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Bridge Header
            BridgeHeaderView(bridge: bridge)
            // Outlier warning (if present)
            if let outlierInfo = outlierInfo {
                OutlierWarningWithDrilldown(outlierInfo: outlierInfo)
            }
            // Statistical Insights (if available)
            if let statistics = statistics {
                EnhancedStatisticsCard(
                    title: "Bridge Activity",
                    primaryValue: statistics.frequencyLabel,
                    primaryLabel: "Activity Level",
                    secondaryValue: statistics.rangeString,
                    secondaryLabel: "Typical Duration",
                    frequencyLabel: statistics.frequencyLabel,
                    confidenceInterval: statistics.confidenceInterval,
                    hasOutliers: statistics.hasOutliers,
                    timeWindow: statistics.timeWindowString,
                    detailedTimeWindow: statistics.timeWindowString,
                    sparklineData: statistics.sparklineData ?? Array(repeating: 0, count: 7),
                    typicalWaitTime: statistics.typicalWaitTime ?? (typical: 0, confidenceInterval: nil),
                    weekdayWeekendDistribution: statistics.weekdayWeekendDistribution ?? (weekday: 0, weekend: 0)
                )
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.top, 8)
        .padding(.horizontal)
    }
    
    public init(bridge: BridgeInfo, statistics: BridgeStatistics? = nil, outlierInfo: OutlierInfo? = nil) {
        self.bridge = bridge
        self.statistics = statistics
        self.outlierInfo = outlierInfo
    }
}

/// Bridge information structure for the enhanced card.
public struct BridgeInfo {
    public let name: String
    public let status: String
    public let lastEventTime: String
    public let trafficLevel: String
    public let duration: String?
    public let openTime: String?
    
    public init(
        name: String,
        status: String,
        lastEventTime: String,
        trafficLevel: String,
        duration: String? = nil,
        openTime: String? = nil
    ) {
        self.name = name
        self.status = status
        self.lastEventTime = lastEventTime
        self.trafficLevel = trafficLevel
        self.duration = duration
        self.openTime = openTime
    }
}

/// Bridge statistics structure for the enhanced card.
public struct BridgeStatistics {
    public let frequencyLabel: String
    public let rangeString: String?
    public let confidenceInterval: (lower: Double, upper: Double)?
    public let hasOutliers: Bool
    public let timeWindowString: String
    public let sparklineData: [Int]?
    public let typicalWaitTime: (typical: Double, confidenceInterval: (lower: Double, upper: Double)?)?
    public let weekdayWeekendDistribution: (weekday: Int, weekend: Int)?
    
    public init(
        frequencyLabel: String,
        rangeString: String? = nil,
        confidenceInterval: (lower: Double, upper: Double)? = nil,
        hasOutliers: Bool = false,
        timeWindowString: String,
        sparklineData: [Int]? = nil,
        typicalWaitTime: (typical: Double, confidenceInterval: (lower: Double, upper: Double)?)? = nil,
        weekdayWeekendDistribution: (weekday: Int, weekend: Int)? = nil
    ) {
        self.frequencyLabel = frequencyLabel
        self.rangeString = rangeString
        self.confidenceInterval = confidenceInterval
        self.hasOutliers = hasOutliers
        self.timeWindowString = timeWindowString
        self.sparklineData = sparklineData
        self.typicalWaitTime = typicalWaitTime
        self.weekdayWeekendDistribution = weekdayWeekendDistribution
    }
}

/// Bridge header view component.
public struct BridgeHeaderView: View {
    public let bridge: BridgeInfo
    
    private var statusColor: Color {
        bridge.status == "OPEN" ? .red : .green
    }
    
    private var trafficColor: Color {
        switch bridge.trafficLevel.lowercased() {
        case "minimal":
            return .green
        case "moderate":
            return .orange
        case "heavy":
            return .red
        default:
            return .gray
        }
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bridge.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(bridge.status)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
                
                Text(bridge.lastEventTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(bridge.trafficLevel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(trafficColor.opacity(0.2))
                    .foregroundColor(trafficColor)
                    .cornerRadius(8)
                
                if let duration = bridge.duration {
                    Text(duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let openTime = bridge.openTime {
                    Text(openTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    public init(bridge: BridgeInfo) {
        self.bridge = bridge
    }
}

// MARK: - Enhanced Features

/// A HIG-compliant sparkline view for showing daily activity trends.
public struct SparklineView: View {
    public let data: [Int]
    public let maxValue: Int
    
    public var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                Rectangle()
                    .fill(value > 0 ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 3, height: max(2, CGFloat(value) / CGFloat(maxValue) * 20))
                    .cornerRadius(1)
            }
        }
        .frame(height: 20)
        .accessibilityLabel("Daily activity sparkline showing \(data.filter { $0 > 0 }.count) active days")
    }
    
    public init(data: [Int]) {
        self.data = data
        self.maxValue = data.max() ?? 1
    }
}

/// A HIG-compliant drill-down view for detailed statistics.
public struct DrillDownView: View {
    public let isExpanded: Bool
    public let sparklineData: [Int]
    public let typicalWaitTime: (typical: Double, confidenceInterval: (lower: Double, upper: Double)?)
    public let weekdayWeekendDistribution: (weekday: Int, weekend: Int)
    public let detailedTimeWindow: String
    
    public var body: some View {
        if isExpanded {
            VStack(alignment: .leading, spacing: 16) {
                // Time Window Context
                Text(detailedTimeWindow)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                
                // Sparkline
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Activity")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SparklineView(data: sparklineData)
                }
                
                // Wait Time Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Typical Wait Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("\(Int(typicalWaitTime.typical)) min")
                            .font(.body)
                            .fontWeight(.semibold)
                        
                        if let confidenceInterval = typicalWaitTime.confidenceInterval {
                            Text("(\(Int(confidenceInterval.lower))-\(Int(confidenceInterval.upper)) min)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Weekday vs Weekend Distribution
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity Distribution")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(weekdayWeekendDistribution.weekday)")
                                .font(.body)
                                .fontWeight(.semibold)
                            Text("Weekdays")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(weekdayWeekendDistribution.weekend)")
                                .font(.body)
                                .fontWeight(.semibold)
                            Text("Weekends")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(.background)
            .cornerRadius(8)
            .transition(.opacity.combined(with: .scale))
        }
    }
    
    public init(
        isExpanded: Bool,
        sparklineData: [Int],
        typicalWaitTime: (typical: Double, confidenceInterval: (lower: Double, upper: Double)?),
        weekdayWeekendDistribution: (weekday: Int, weekend: Int),
        detailedTimeWindow: String
    ) {
        self.isExpanded = isExpanded
        self.sparklineData = sparklineData
        self.typicalWaitTime = typicalWaitTime
        self.weekdayWeekendDistribution = weekdayWeekendDistribution
        self.detailedTimeWindow = detailedTimeWindow
    }
}

/// A HIG-compliant enhanced statistics card with drill-down capabilities.
public struct EnhancedStatisticsCard: View {
    public let title: String
    public let primaryValue: String
    public let primaryLabel: String
    public let secondaryValue: String?
    public let secondaryLabel: String?
    public let frequencyLabel: String?
    public let confidenceInterval: (lower: Double, upper: Double)?
    public let hasOutliers: Bool
    public let timeWindow: String
    public let detailedTimeWindow: String
    public let sparklineData: [Int]
    public let typicalWaitTime: (typical: Double, confidenceInterval: (lower: Double, upper: Double)?)
    public let weekdayWeekendDistribution: (weekday: Int, weekend: Int)
    
    @State private var isExpanded = false
    @State private var showLearnMore = false
    
    private var severityIcon: String {
        hasOutliers ? "exclamationmark.triangle.fill" : "info.circle.fill"
    }
    
    private var severityColor: Color {
        hasOutliers ? .orange : .blue
    }
    
    private var severityAltText: String {
        hasOutliers ? "Unusual data detected" : "Information"
    }
    
    private var actualValue: String?
    private var normalRange: String?
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with expand/collapse
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let frequencyLabel = frequencyLabel {
                    FrequencyBadge(label: frequencyLabel)
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                .accessibilityLabel(isExpanded ? "Collapse details" : "Show more details")
            }
            
            // Primary Statistics
            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(primaryValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(primaryLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let secondaryValue = secondaryValue {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(secondaryValue)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(secondaryLabel ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Confidence Interval (if available)
            if let confidenceInterval = confidenceInterval {
                ConfidenceIntervalView(interval: confidenceInterval)
            }
            
            // Time Window
            Text(timeWindow)
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
            
            // Drill-down content
            DrillDownView(
                isExpanded: isExpanded,
                sparklineData: sparklineData,
                typicalWaitTime: typicalWaitTime,
                weekdayWeekendDistribution: weekdayWeekendDistribution,
                detailedTimeWindow: detailedTimeWindow
            )
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
    }
    
    public init(
        title: String,
        primaryValue: String,
        primaryLabel: String,
        secondaryValue: String? = nil,
        secondaryLabel: String? = nil,
        frequencyLabel: String? = nil,
        confidenceInterval: (lower: Double, upper: Double)? = nil,
        hasOutliers: Bool = false,
        timeWindow: String,
        detailedTimeWindow: String,
        sparklineData: [Int],
        typicalWaitTime: (typical: Double, confidenceInterval: (lower: Double, upper: Double)?),
        weekdayWeekendDistribution: (weekday: Int, weekend: Int)
    ) {
        self.title = title
        self.primaryValue = primaryValue
        self.primaryLabel = primaryLabel
        self.secondaryValue = secondaryValue
        self.secondaryLabel = secondaryLabel
        self.frequencyLabel = frequencyLabel
        self.confidenceInterval = confidenceInterval
        self.hasOutliers = hasOutliers
        self.timeWindow = timeWindow
        self.detailedTimeWindow = detailedTimeWindow
        self.sparklineData = sparklineData
        self.typicalWaitTime = typicalWaitTime
        self.weekdayWeekendDistribution = weekdayWeekendDistribution
    }
}

// MARK: - Supporting Types and Views

/// A HIG-compliant sheet for explaining unusual data detection.
public struct LearnMoreUnusualDataSheet: View {
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Unusual Data Detection")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("""
                When we detect unusual data for a bridge, it means the event (like an opening or closing) occurred outside the typical range of values observed over the last 30 days.
                This could indicate:
                • A temporary traffic surge or event
                • A change in bridge operations
                • A system error
                • An unusual weather or marine condition
                
                **What does this mean for you?**
                • You might experience longer waits or unexpected closures.
                • It's important to stay informed and consider alternate routes if timing is critical.
                • We use statistical analysis (like Interquartile Range - IQR) to identify these patterns.
                
                **How do we calculate it?**
                IQR is a measure of statistical dispersion, calculated as the difference between the third quartile (Q3) and the first quartile (Q1) of a dataset.
                If a value falls outside the range of Q1 - 1.5 * IQR or Q3 + 1.5 * IQR, it's considered an outlier.
                
                **Why is this important?**
                Outliers can skew statistical analysis and lead to incorrect conclusions.
                By identifying and handling them, we ensure the reliability of our data and the accuracy of our insights.
                """)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Button(action: {
                // Dismiss the sheet
            }) {
                Text("Got it!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .accessibilityLabel("Dismiss unusual data explanation sheet")
        }
        .padding()
        .presentationDetents([.medium])
    }
}

public struct DrillDownUnusualDataExplanation: View {
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How we decide something is unusual")
                .font(.headline)
                .fontWeight(.semibold)
            Text("1. We take every opening time from the past 30 days.\n2. We find the middle range (what statisticians call the ‘75 % box’).\n3. Anything that lands >1.5× that range above or below is flagged.\n\nThis is called the *Inter-Quartile Range* (IQR) method—an industry standard way to spot outliers without false alarms.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
    }
    public init() {}
}

// New: OutlierInfo struct for contextual drill-down
public struct OutlierInfo {
    public let bridgeName: String
    public let actualValue: Double
    public let normalRange: (Double, Double)
    public let timeWindow: String
    public let eventType: String // "opening" or "closing"
    public let isHigh: Bool // true if above normal, false if below
    public init(bridgeName: String, actualValue: Double, normalRange: (Double, Double), timeWindow: String, eventType: String, isHigh: Bool) {
        self.bridgeName = bridgeName
        self.actualValue = actualValue
        self.normalRange = normalRange
        self.timeWindow = timeWindow
        self.eventType = eventType
        self.isHigh = isHigh
    }
}

// New: Outlier warning with contextual drill-down
public struct OutlierWarningWithDrilldown: View {
    public let outlierInfo: OutlierInfo
    @State private var showDetails = false
    public var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Button(action: { withAnimation { showDetails.toggle() } }) {
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: outlierInfo.isHigh ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .accessibilityLabel("Unusual data detected")
                    Text("Unusual data detected")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity)
            }
            .accessibilityLabel(showDetails ? "Hide details about unusual data" : "Show details about unusual data")
            if showDetails {
                OutlierDrilldownExplanation(outlierInfo: outlierInfo)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
    }
    public init(outlierInfo: OutlierInfo) {
        self.outlierInfo = outlierInfo
    }
}

// New: Contextual drill-down explanation
public struct OutlierDrilldownExplanation: View {
    public let outlierInfo: OutlierInfo
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why is this unusual?")
                .font(.headline)
                .fontWeight(.semibold)
            Text("For \(outlierInfo.bridgeName), this \(outlierInfo.eventType) lasted \(Int(outlierInfo.actualValue)) min, which is \(outlierInfo.isHigh ? "longer" : "shorter") than the typical range (\(Int(outlierInfo.normalRange.0))–\(Int(outlierInfo.normalRange.1)) min) observed over the last \(outlierInfo.timeWindow).")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            Text("How we decide something is unusual")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.top, 4)
            Text("We use a method called Inter-Quartile Range (IQR) to spot outliers. If an event falls outside the usual range for this bridge over the last \(outlierInfo.timeWindow), it’s flagged as unusual.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
    }
    public init(outlierInfo: OutlierInfo) {
        self.outlierInfo = outlierInfo
    }
}
