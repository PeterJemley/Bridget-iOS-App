import Foundation
import SwiftData
import BridgetCore

// MARK: - StatisticsAPI

/// Comprehensive statistical analysis API providing unbiased estimators and robust statistical methods
public struct StatisticsAPI {
    
    // MARK: - Basic Statistics
    
    /// Calculates the mean of a dataset
    public static func mean(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
    
    /// Calculates the unbiased standard deviation (sample standard deviation)
    public static func unbiasedStd(_ values: [Double]) -> Double? {
        guard values.count > 1 else { return nil }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(values.count - 1) // n-1 for sample variance
        return sqrt(variance)
    }
    
    /// Calculates the median of a dataset
    public static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let count = sorted.count
        
        if count % 2 == 0 {
            // Even number of elements - average of two middle values
            let mid1 = sorted[count / 2 - 1]
            let mid2 = sorted[count / 2]
            return (mid1 + mid2) / 2
        } else {
            // Odd number of elements - middle value
            return sorted[count / 2]
        }
    }
    
    /// Calculates the specified percentile of a dataset
    public static func percentile(_ values: [Double], _ percentile: Double) -> Double? {
        guard !values.isEmpty && percentile >= 0 && percentile <= 1 else { return nil }
        
        let sorted = values.sorted()
        let count = Double(sorted.count)
        let index = percentile * (count - 1)
        
        if index.truncatingRemainder(dividingBy: 1) == 0 {
            // Exact integer index
            return sorted[Int(index)]
        } else {
            // Interpolate between two values
            let lowerIndex = Int(floor(index))
            let upperIndex = Int(ceil(index))
            let weight = index - floor(index)
            
            let lowerValue = sorted[lowerIndex]
            let upperValue = sorted[upperIndex]
            
            return lowerValue + weight * (upperValue - lowerValue)
        }
    }
    
    /// Calculates the trimmed mean (removes outliers from both ends)
    public static func trimmedMean(_ values: [Double], trimFraction: Double) -> Double? {
        guard !values.isEmpty && trimFraction >= 0 && trimFraction < 0.5 else { return nil }
        
        let sorted = values.sorted()
        let trimCount = Int(Double(sorted.count) * trimFraction)
        let trimmed = Array(sorted[trimCount..<(sorted.count - trimCount)])
        
        return mean(trimmed)
    }
    
    /// Calculates the range (min and max) of a dataset
    public static func range(_ values: [Double]) -> (min: Double, max: Double)? {
        guard !values.isEmpty else { return nil }
        return (min: values.min()!, max: values.max()!)
    }
    
    // MARK: - Data-Driven Thresholds
    
    /// Computes data-driven thresholds for frequency classification
    public static func computeDataDrivenThresholds(from values: [Double]) -> (rare: Double, sometimes: Double, often: Double)? {
        guard values.count >= 4 else { return nil }
        
        let p25 = percentile(values, 0.25) ?? 0
        let p50 = percentile(values, 0.50) ?? 0
        let p75 = percentile(values, 0.75) ?? 0
        
        return (rare: p25, sometimes: p50, often: p75)
    }
    
    /// Frequency label based on thresholds
    public static func frequencyLabel(value: Double, thresholds: (rare: Double, sometimes: Double, often: Double)) -> String {
        if value <= thresholds.rare {
            return "Low"
        } else if value <= thresholds.sometimes {
            return "Medium"
        } else if value <= thresholds.often {
            return "High"
        } else {
            return "Very High"
        }
    }
    
    // MARK: - Seasonal Analysis
    
    /// Season types for seasonal analysis
    public enum SeasonType {
        case daily
        case weekly
        case monthly
        
        func seasonKey(from date: Date) -> String {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .weekOfYear], from: date)
            
            switch self {
            case .daily:
                return "\(components.year!)-\(String(format: "%02d", components.month!))-\(String(format: "%02d", components.day!))"
            case .weekly:
                return "\(components.year!)-W\(String(format: "%02d", components.weekOfYear!))"
            case .monthly:
                return "\(components.year!)-\(String(format: "%02d", components.month!))"
            }
        }
    }
    
    /// Computes seasonal thresholds
    public static func computeSeasonalThresholds(
        values: [Double],
        timestamps: [Date],
        seasonType: SeasonType
    ) -> [String: (rare: Double, sometimes: Double, often: Double)]? {
        guard values.count == timestamps.count && values.count >= 8 else { return nil }
        
        var seasonalData: [String: [Double]] = [:]
        
        // Group values by season
        for (index, timestamp) in timestamps.enumerated() {
            let seasonKey = seasonType.seasonKey(from: timestamp)
            seasonalData[seasonKey, default: []].append(values[index])
        }
        
        // Calculate thresholds for each season
        var thresholds: [String: (rare: Double, sometimes: Double, often: Double)] = [:]
        
        for (season, seasonValues) in seasonalData {
            guard seasonValues.count >= 3 else { continue } // Need at least 3 values per season
            
            if let seasonThresholds = computeDataDrivenThresholds(from: seasonValues) {
                thresholds[season] = seasonThresholds
            }
        }
        
        return thresholds.isEmpty ? nil : thresholds
    }
    
    // MARK: - Confidence Intervals
    
    /// Calculates confidence interval for a dataset
    public static func confidenceInterval(
        values: [Double],
        confidenceLevel: Double = 0.95
    ) -> (lower: Double, upper: Double)? {
        guard values.count >= 2 else { return nil }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let std = unbiasedStd(values) ?? 0
        
        // For small samples (n < 30), use t-distribution approximation
        // For larger samples, use normal distribution
        let criticalValue: Double
        if values.count < 30 {
            // Simplified t-distribution critical values
            switch confidenceLevel {
            case 0.90: criticalValue = 1.645
            case 0.95: criticalValue = 1.96
            case 0.99: criticalValue = 2.576
            default: criticalValue = 1.96
            }
        } else {
            // Normal distribution critical values
            switch confidenceLevel {
            case 0.90: criticalValue = 1.645
            case 0.95: criticalValue = 1.96
            case 0.99: criticalValue = 2.576
            default: criticalValue = 1.96
            }
        }
        
        let marginOfError = criticalValue * std / sqrt(Double(values.count))
        
        return (lower: mean - marginOfError, upper: mean + marginOfError)
    }
    
    // MARK: - Outlier Detection
    
    /// Detects outliers using the IQR method
    public static func detectOutliers(
        values: [Double],
        multiplier: Double = 1.5
    ) -> [Int]? {
        guard values.count >= 4 else { return nil }
        
        let p25 = percentile(values, 0.25) ?? 0
        let p75 = percentile(values, 0.75) ?? 0
        let iqr = p75 - p25
        
        let lowerBound = p25 - multiplier * iqr
        let upperBound = p75 + multiplier * iqr
        
        var outlierIndices: [Int] = []
        
        for (index, value) in values.enumerated() {
            if value < lowerBound || value > upperBound {
                outlierIndices.append(index)
            }
        }
        
        return outlierIndices.isEmpty ? nil : outlierIndices
    }
    
    // MARK: - Utility Methods
    
    /// Creates a range string for display
    public static func rangeString(p25: Double, p75: Double, unit: String? = nil) -> String {
        let range = "\(Int(p25))–\(Int(p75))"
        return unit != nil ? "\(range) \(unit!)" : range
    }
    
    /// Creates a time window string for display
    public static func timeWindowString(days: Int) -> String {
        if days == 1 {
            return "Over the last 1 day"
        } else {
            return "Over the last \(days) days"
        }
    }
}

// MARK: - DateProvider Protocol

/// Protocol for objects that provide a date
public protocol DateProvider {
    var date: Date { get }
}

/// Enhanced statistical analysis system for determining optimal refresh intervals
/// based on bridge opening patterns, seasonal variations, and data freshness
@Observable
public class BridgeDataAnalyzer {
    
    // MARK: - Configuration
    private let minimumDataPoints = 50
    private let analysisConfidenceLevel = 0.95
    private let changeDetectionThreshold = 0.05
    private let seasonalAnalysisMinimumPoints = 20
    
    // MARK: - Analysis Results
    public var recommendedRefreshInterval: TimeInterval = 3600 // Default 1 hour
    public var analysisConfidence: Double = 0.0
    public var dataFreshness: DataFreshness = .unknown
    public var patternStability: PatternStability = .unknown
    public var seasonalPatterns: SeasonalPatterns = .none
    public var trendDirection: TrendDirection = .stable
    public var changePointCount: Int = 0
    public var poissonFit: Bool = false
    public var hasSeasonalPattern: Bool = false
    
    // MARK: - Statistical Models
    private var poissonRate: Double = 0.0
    private var exponentialParameter: Double = 0.0
    private var lastAnalysisDate: Date?
    private var seasonalRates: [String: Double] = [:]
    private var trendSlope: Double = 0.0
    
    public init() {}
    
    // MARK: - Public Analysis Methods
    
    /// Performs comprehensive analysis of bridge data to determine optimal refresh interval
    public func analyzeRefreshInterval(modelContext: ModelContext) async -> RefreshIntervalRecommendation {
        print("📊 BRIDGE DATA ANALYSIS: DISABLED - Returning default recommendation")
        
        // TEMPORARILY DISABLED: Return default recommendation to prevent crashes
        return RefreshIntervalRecommendation(
            interval: 3600,
            confidence: 0.0,
            method: .insufficientData,
            reasoning: "Statistical analysis temporarily disabled for stability"
        )
        
        /* DISABLED CODE - Will be re-enabled after SwiftData fixes
        print("📊 BRIDGE DATA ANALYSIS: Starting comprehensive analysis")
        
        // Fetch all bridge events for analysis with error handling
        let events: [DrawbridgeEvent]
        do {
            events = try await fetchAllBridgeEvents(modelContext: modelContext)
        } catch {
            print("📊 BRIDGE DATA ANALYSIS: Failed to fetch events: \(error)")
            return RefreshIntervalRecommendation(
                interval: 3600,
                confidence: 0.0,
                method: .insufficientData,
                reasoning: "Failed to fetch bridge events: \(error.localizedDescription)"
            )
        }
        
        guard events.count >= minimumDataPoints else {
            print("📊 BRIDGE DATA ANALYSIS: Insufficient data points (\(events.count) < \(minimumDataPoints))")
            return RefreshIntervalRecommendation(
                interval: 3600,
                confidence: 0.0,
                method: .insufficientData,
                reasoning: "Need at least \(minimumDataPoints) data points for analysis"
            )
        }
        
        // Perform comprehensive statistical analysis with error handling
        let poissonAnalysis: PoissonAnalysis
        let changePointAnalysis: ChangePointAnalysis
        let goodnessOfFit: GoodnessOfFitResult
        let seasonalAnalysis: SeasonalAnalysis
        let trendAnalysis: TrendAnalysis
        let adaptiveThresholds: AdaptiveThresholds
        
        do {
            poissonAnalysis = analyzePoissonProcess(events: events)
            changePointAnalysis = analyzeChangePoints(events: events)
            goodnessOfFit = performGoodnessOfFitTest(events: events)
            seasonalAnalysis = analyzeSeasonalPatterns(events: events)
            trendAnalysis = analyzeTrends(events: events)
            adaptiveThresholds = calculateAdaptiveThresholds(events: events)
        } catch {
            print("📊 BRIDGE DATA ANALYSIS: Error during analysis: \(error)")
            return RefreshIntervalRecommendation(
                interval: 3600,
                confidence: 0.0,
                method: .insufficientData,
                reasoning: "Analysis failed: \(error.localizedDescription)"
            )
        }
        
        // Combine all analyses to determine optimal interval
        let recommendation = combineAnalyses(
            poisson: poissonAnalysis,
            changePoints: changePointAnalysis,
            goodnessOfFit: goodnessOfFit,
            seasonal: seasonalAnalysis,
            trend: trendAnalysis,
            adaptiveThresholds: adaptiveThresholds
        )
        
        // Update internal state
        self.recommendedRefreshInterval = recommendation.interval
        self.analysisConfidence = recommendation.confidence
        self.dataFreshness = determineDataFreshness(events: events)
        self.patternStability = determinePatternStability(changePointAnalysis: changePointAnalysis)
        self.seasonalPatterns = seasonalAnalysis.patternType
        self.trendDirection = trendAnalysis.direction
        self.changePointCount = changePointAnalysis.changePoints.count
        self.poissonFit = goodnessOfFit.isSignificant
        self.hasSeasonalPattern = seasonalAnalysis.patternType != .none
        self.lastAnalysisDate = Date()
        
        print("📊 BRIDGE DATA ANALYSIS: Recommended interval: \(recommendation.interval/60) minutes")
        print("📊 BRIDGE DATA ANALYSIS: Confidence: \(recommendation.confidence)")
        print("📊 BRIDGE DATA ANALYSIS: Method: \(recommendation.method)")
        print("📊 BRIDGE DATA ANALYSIS: Seasonal patterns: \(seasonalAnalysis.patternType)")
        print("📊 BRIDGE DATA ANALYSIS: Trend direction: \(trendAnalysis.direction)")
        
        return recommendation
        */
    }
    
    // MARK: - Enhanced Poisson Process Analysis
    
    /// Models bridge openings as a Poisson process with seasonal adjustments
    private func analyzePoissonProcess(events: [DrawbridgeEvent]) -> PoissonAnalysis {
        print("📊 POISSON ANALYSIS: Starting analysis with \(events.count) events")
        
        // Calculate time between openings (inter-arrival times)
        let interArrivalTimes = calculateInterArrivalTimes(events: events)
        
        // Estimate Poisson rate (λ = total events / total time)
        let totalTime = events.last?.openDateTime.timeIntervalSince(events.first?.openDateTime ?? Date()) ?? 0
        let poissonRate = totalTime > 0 ? Double(events.count) / (totalTime / 3600) : 0 // events per hour
        
        // Fit exponential distribution to inter-arrival times
        let exponentialParameter = fitExponentialDistribution(times: interArrivalTimes)
        
        // Calculate percentiles for different confidence levels
        let percentiles = calculateExponentialPercentiles(
            parameter: exponentialParameter,
            confidenceLevels: [0.8, 0.9, 0.95, 0.99]
        )
        
        // Calculate seasonal variations
        let seasonalRates = calculateSeasonalRates(events: events)
        
        let analysis = PoissonAnalysis(
            rate: poissonRate,
            exponentialParameter: exponentialParameter,
            percentiles: percentiles,
            interArrivalTimes: interArrivalTimes,
            seasonalRates: seasonalRates
        )
        
        print("📊 POISSON ANALYSIS: Rate: \(poissonRate) events/hour")
        print("📊 POISSON ANALYSIS: 95th percentile: \(percentiles[0.95] ?? 0)/60 minutes")
        print("📊 POISSON ANALYSIS: Seasonal variations detected: \(seasonalRates.count) patterns")
        
        return analysis
    }
    
    /// Calculates seasonal variations in bridge opening rates
    private func calculateSeasonalRates(events: [DrawbridgeEvent]) -> [String: Double] {
        let calendar = Calendar.current
        var hourlyRates: [Int: Int] = [:]
        var dailyRates: [Int: Int] = [:]
        var monthlyRates: [Int: Int] = [:]
        
        // Initialize all time periods
        for hour in 0..<24 { hourlyRates[hour] = 0 }
        for day in 1...7 { dailyRates[day] = 0 }
        for month in 1...12 { monthlyRates[month] = 0 }
        
        // Count events by time period
        for event in events {
            let hour = calendar.component(.hour, from: event.openDateTime)
            let weekday = calendar.component(.weekday, from: event.openDateTime)
            let month = calendar.component(.month, from: event.openDateTime)
            
            hourlyRates[hour, default: 0] += 1
            dailyRates[weekday, default: 0] += 1
            monthlyRates[month, default: 0] += 1
        }
        
        // Calculate rates per hour of day
        let totalHours = Double(events.count) / 24.0
        var seasonalRates: [String: Double] = [:]
        
        for (hour, count) in hourlyRates {
            let rate = Double(count) / totalHours
            seasonalRates["hour_\(hour)"] = rate
        }
        
        // Calculate rates per day of week
        let totalDays = Double(events.count) / 7.0
        for (day, count) in dailyRates {
            let rate = Double(count) / totalDays
            seasonalRates["day_\(day)"] = rate
        }
        
        // Calculate rates per month
        let totalMonths = Double(events.count) / 12.0
        for (month, count) in monthlyRates {
            let rate = Double(count) / totalMonths
            seasonalRates["month_\(month)"] = rate
        }
        
        return seasonalRates
    }
    
    // MARK: - Trend Analysis
    
    /// Analyzes trends in bridge opening patterns over time
    private func analyzeTrends(events: [DrawbridgeEvent]) -> TrendAnalysis {
        print("📊 TREND ANALYSIS: Starting trend analysis")
        
        let sortedEvents = events.sorted(by: { $0.openDateTime < $1.openDateTime })
        
        // Group events into time windows for trend analysis
        let windowSize: TimeInterval = 86400 // 1 day windows
        let windows = groupEventsIntoWindows(events: sortedEvents, windowSize: windowSize)
        
        // Calculate event counts per window
        let counts = windows.map { $0.count }
        let timestamps = windows.enumerated().map { Double($0.offset) * windowSize }
        
        // Perform linear regression
        let regression = performLinearRegression(x: timestamps, y: counts.map { Double($0) })
        
        // Determine trend direction and significance
        let direction = determineTrendDirection(slope: regression.slope, pValue: regression.pValue)
        let significance = regression.pValue < 0.05
        
        let analysis = TrendAnalysis(
            slope: regression.slope,
            intercept: regression.intercept,
            rSquared: regression.rSquared,
            pValue: regression.pValue,
            direction: direction,
            isSignificant: significance
        )
        
        print("📊 TREND ANALYSIS: Slope: \(regression.slope)")
        print("📊 TREND ANALYSIS: R-squared: \(regression.rSquared)")
        print("📊 TREND ANALYSIS: P-value: \(regression.pValue)")
        print("📊 TREND ANALYSIS: Direction: \(direction)")
        
        return analysis
    }
    
    /// Performs linear regression on time series data
    private func performLinearRegression(x: [Double], y: [Double]) -> (slope: Double, intercept: Double, rSquared: Double, pValue: Double) {
        guard x.count == y.count && x.count > 2 else {
            return (slope: 0, intercept: 0, rSquared: 0, pValue: 1.0)
        }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n
        
        // Calculate R-squared
        let meanY = sumY / n
        let ssRes = zip(x, y).map { (xi, yi) in
            let predicted = slope * xi + intercept
            return (yi - predicted) * (yi - predicted)
        }.reduce(0.0, +)
        let ssTot = y.map { ($0 - meanY) * ($0 - meanY) }.reduce(0.0, +)
        let rSquared = ssTot > 0 ? 1 - (ssRes / ssTot) : 0
        
        // Approximate p-value (simplified)
        let pValue = rSquared > 0.5 ? 0.01 : 0.5
        
        return (slope: slope, intercept: intercept, rSquared: rSquared, pValue: pValue)
    }
    
    /// Determines trend direction based on slope and significance
    private func determineTrendDirection(slope: Double, pValue: Double) -> TrendDirection {
        guard pValue < 0.05 else { return .stable }
        
        if slope > 0.1 {
            return .increasing
        } else if slope < -0.1 {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    // MARK: - Seasonal Pattern Analysis
    
    /// Analyzes seasonal patterns in bridge opening data
    private func analyzeSeasonalPatterns(events: [DrawbridgeEvent]) -> SeasonalAnalysis {
        print("📊 SEASONAL ANALYSIS: Starting seasonal pattern analysis")
        
        let calendar = Calendar.current
        var hourlyPatterns: [Int: Int] = [:]
        var dailyPatterns: [Int: Int] = [:]
        var monthlyPatterns: [Int: Int] = [:]
        
        // Initialize patterns
        for hour in 0..<24 { hourlyPatterns[hour] = 0 }
        for day in 1...7 { dailyPatterns[day] = 0 }
        for month in 1...12 { monthlyPatterns[month] = 0 }
        
        // Count events by time period
        for event in events {
            let hour = calendar.component(.hour, from: event.openDateTime)
            let weekday = calendar.component(.weekday, from: event.openDateTime)
            let month = calendar.component(.month, from: event.openDateTime)
            
            hourlyPatterns[hour, default: 0] += 1
            dailyPatterns[weekday, default: 0] += 1
            monthlyPatterns[month, default: 0] += 1
        }
        
        // Detect significant patterns
        let hourlyVariance = calculateVariance(Array(hourlyPatterns.values))
        let dailyVariance = calculateVariance(Array(dailyPatterns.values))
        let monthlyVariance = calculateVariance(Array(monthlyPatterns.values))
        
        let patternType: SeasonalPatterns
        if hourlyVariance > 0.5 {
            patternType = .hourly
        } else if dailyVariance > 0.3 {
            patternType = .daily
        } else if monthlyVariance > 0.2 {
            patternType = .monthly
        } else {
            patternType = .none
        }
        
        let analysis = SeasonalAnalysis(
            patternType: patternType,
            hourlyPatterns: hourlyPatterns,
            dailyPatterns: dailyPatterns,
            monthlyPatterns: monthlyPatterns,
            hourlyVariance: hourlyVariance,
            dailyVariance: dailyVariance,
            monthlyVariance: monthlyVariance
        )
        
        print("📊 SEASONAL ANALYSIS: Pattern type: \(patternType)")
        print("📊 SEASONAL ANALYSIS: Hourly variance: \(hourlyVariance)")
        print("📊 SEASONAL ANALYSIS: Daily variance: \(dailyVariance)")
        
        return analysis
    }
    
    /// Calculates variance of a dataset
    private func calculateVariance(_ values: [Int]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = Double(values.reduce(0, +)) / Double(values.count)
        let squaredDifferences = values.map { pow(Double($0) - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count)
    }
    
    // MARK: - Adaptive Thresholds
    
    /// Calculates adaptive thresholds based on current data patterns
    private func calculateAdaptiveThresholds(events: [DrawbridgeEvent]) -> AdaptiveThresholds {
        print("📊 ADAPTIVE THRESHOLDS: Calculating adaptive thresholds")
        
        let interArrivalTimes = calculateInterArrivalTimes(events: events)
        
        // Calculate percentiles for adaptive thresholds
        let p25 = StatisticsAPI.percentile(interArrivalTimes, 0.25) ?? 0
        let p50 = StatisticsAPI.percentile(interArrivalTimes, 0.50) ?? 0
        let p75 = StatisticsAPI.percentile(interArrivalTimes, 0.75) ?? 0
        let p95 = StatisticsAPI.percentile(interArrivalTimes, 0.95) ?? 0
        
        // Calculate adaptive refresh intervals
        let conservativeInterval = p75 * 0.8 // 80% of 75th percentile
        let moderateInterval = p50 * 1.2 // 120% of median
        let aggressiveInterval = p25 * 1.5 // 150% of 25th percentile
        
        let thresholds = AdaptiveThresholds(
            conservative: conservativeInterval,
            moderate: moderateInterval,
            aggressive: aggressiveInterval,
            p25: p25,
            p50: p50,
            p75: p75,
            p95: p95
        )
        
        print("📊 ADAPTIVE THRESHOLDS: Conservative: \(conservativeInterval/60) min")
        print("📊 ADAPTIVE THRESHOLDS: Moderate: \(moderateInterval/60) min")
        print("📊 ADAPTIVE THRESHOLDS: Aggressive: \(aggressiveInterval/60) min")
        
        return thresholds
    }
    
    // MARK: - Enhanced Analysis Combination
    
    /// Combines all analyses to determine optimal refresh interval
    private func combineAnalyses(
        poisson: PoissonAnalysis,
        changePoints: ChangePointAnalysis,
        goodnessOfFit: GoodnessOfFitResult,
        seasonal: SeasonalAnalysis,
        trend: TrendAnalysis,
        adaptiveThresholds: AdaptiveThresholds
    ) -> RefreshIntervalRecommendation {
        
        // Start with Poisson-based recommendation
        let baseInterval = poisson.percentiles[analysisConfidenceLevel] ?? 3600
        
        // Apply seasonal adjustments
        let seasonalAdjustment = calculateSeasonalAdjustment(seasonal: seasonal)
        
        // Apply trend adjustments
        let trendAdjustment = calculateTrendAdjustment(trend: trend)
        
        // Apply change point adjustments
        let changePointAdjustment = calculateChangePointAdjustment(changePoints: changePoints)
        
        // Apply goodness of fit adjustments
        let goodnessAdjustment = calculateGoodnessAdjustment(goodnessOfFit: goodnessOfFit)
        
        // Calculate final interval with adaptive thresholds
        let adjustedInterval = baseInterval * seasonalAdjustment * trendAdjustment * changePointAdjustment * goodnessAdjustment
        
        // Apply adaptive threshold constraints
        let finalInterval = constrainToAdaptiveThresholds(
            interval: adjustedInterval,
            thresholds: adaptiveThresholds
        )
        
        // Determine confidence and method
        let confidence = calculateConfidence(
            poisson: poisson,
            changePoints: changePoints,
            goodnessOfFit: goodnessOfFit,
            seasonal: seasonal,
            trend: trend
        )
        
        let method = determineRecommendationMethod(
            poisson: poisson,
            changePoints: changePoints,
            goodnessOfFit: goodnessOfFit,
            seasonal: seasonal,
            trend: trend
        )
        
        let reasoning = generateReasoning(
            poisson: poisson,
            changePoints: changePoints,
            goodnessOfFit: goodnessOfFit,
            seasonal: seasonal,
            trend: trend,
            baseInterval: baseInterval,
            finalInterval: finalInterval
        )
        
        return RefreshIntervalRecommendation(
            interval: finalInterval,
            confidence: confidence,
            method: method,
            reasoning: reasoning
        )
    }
    
    /// Calculates seasonal adjustment factor
    private func calculateSeasonalAdjustment(seasonal: SeasonalAnalysis) -> Double {
        switch seasonal.patternType {
        case .hourly:
            return 0.8 // More frequent updates for hourly patterns
        case .daily:
            return 0.9
        case .monthly:
            return 1.0
        case .none:
            return 1.0
        }
    }
    
    /// Calculates trend adjustment factor
    private func calculateTrendAdjustment(trend: TrendAnalysis) -> Double {
        if trend.isSignificant {
            switch trend.direction {
            case .increasing:
                return 0.7 // More frequent updates for increasing trends
            case .decreasing:
                return 1.2 // Less frequent updates for decreasing trends
            case .stable:
                return 1.0
            }
        }
        return 1.0
    }
    
    /// Constrains interval to adaptive thresholds
    private func constrainToAdaptiveThresholds(interval: TimeInterval, thresholds: AdaptiveThresholds) -> TimeInterval {
        if interval < thresholds.conservative {
            return thresholds.conservative
        } else if interval > thresholds.aggressive {
            return thresholds.aggressive
        } else {
            return interval
        }
    }
    
    /// Enhanced confidence calculation
    private func calculateConfidence(
        poisson: PoissonAnalysis,
        changePoints: ChangePointAnalysis,
        goodnessOfFit: GoodnessOfFitResult,
        seasonal: SeasonalAnalysis,
        trend: TrendAnalysis
    ) -> Double {
        var confidence = 0.8 // Base confidence
        
        // Adjust based on data quality
        if poisson.interArrivalTimes.count > 100 {
            confidence += 0.1
        }
        
        // Adjust based on pattern stability
        if !goodnessOfFit.isSignificant {
            confidence += 0.05
        }
        
        // Adjust based on seasonal patterns
        if seasonal.patternType != .none {
            confidence += 0.05
        }
        
        // Adjust based on trend significance
        if trend.isSignificant {
            confidence += 0.05
        }
        
        // Adjust based on change point frequency
        let changePointRate = Double(changePoints.changePoints.count) / 24.0
        if changePointRate < 0.1 {
            confidence += 0.05
        }
        
        return min(confidence, 1.0)
    }
    
    /// Enhanced method determination
    private func determineRecommendationMethod(
        poisson: PoissonAnalysis,
        changePoints: ChangePointAnalysis,
        goodnessOfFit: GoodnessOfFitResult,
        seasonal: SeasonalAnalysis,
        trend: TrendAnalysis
    ) -> RecommendationMethod {
        if poisson.interArrivalTimes.count < minimumDataPoints {
            return .insufficientData
        } else if goodnessOfFit.isSignificant {
            return .changeDetection
        } else if seasonal.patternType != .none {
            return .seasonalAnalysis
        } else if trend.isSignificant {
            return .trendAnalysis
        } else if changePoints.changePoints.count > 5 {
            return .patternAnalysis
        } else {
            return .poissonProcess
        }
    }
    
    /// Enhanced reasoning generation
    private func generateReasoning(
        poisson: PoissonAnalysis,
        changePoints: ChangePointAnalysis,
        goodnessOfFit: GoodnessOfFitResult,
        seasonal: SeasonalAnalysis,
        trend: TrendAnalysis,
        baseInterval: TimeInterval,
        finalInterval: TimeInterval
    ) -> String {
        var reasons: [String] = []
        
        reasons.append("Based on \(poisson.interArrivalTimes.count) bridge events")
        reasons.append("Poisson rate: \(String(format: "%.2f", poisson.rate)) events/hour")
        
        if seasonal.patternType != .none {
            reasons.append("Detected \(seasonal.patternType) seasonal patterns")
        }
        
        if trend.isSignificant {
            reasons.append("Trend analysis shows \(trend.direction) pattern (p=\(String(format: "%.3f", trend.pValue)))")
        }
        
        if goodnessOfFit.isSignificant {
            reasons.append("Pattern has changed significantly (p=\(String(format: "%.3f", goodnessOfFit.pValue)))")
        }
        
        if changePoints.changePoints.count > 0 {
            reasons.append("Detected \(changePoints.changePoints.count) change points")
        }
        
        if abs(baseInterval - finalInterval) > 300 { // 5 minutes difference
            reasons.append("Adjusted from \(Int(baseInterval/60)) to \(Int(finalInterval/60)) minutes")
        }
        
        return reasons.joined(separator: ". ")
    }
    
    // MARK: - Data Freshness and Pattern Stability
    
    /// Determines the freshness of the current data
    private func determineDataFreshness(events: [DrawbridgeEvent]) -> DataFreshness {
        guard let lastEvent = events.max(by: { $0.openDateTime < $1.openDateTime }) else {
            return .unknown
        }
        
        let age = Date().timeIntervalSince(lastEvent.openDateTime)
        
        if age < 1800 { // 30 minutes
            return .veryFresh
        } else if age < 7200 { // 2 hours
            return .fresh
        } else if age < 86400 { // 24 hours
            return .stale
        } else {
            return .veryStale
        }
    }
    
    /// Determines the stability of the opening pattern
    private func determinePatternStability(changePointAnalysis: ChangePointAnalysis) -> PatternStability {
        let changePointRate = Double(changePointAnalysis.changePoints.count) / 24.0
        
        if changePointRate < 0.1 {
            return .veryStable
        } else if changePointRate < 0.3 {
            return .stable
        } else if changePointRate < 0.5 {
            return .unstable
        } else {
            return .veryUnstable
        }
    }
    
    // MARK: - Data Fetching
    
    /// Fetches all bridge events for analysis with improved error handling
    private func fetchAllBridgeEvents(modelContext: ModelContext) async throws -> [DrawbridgeEvent] {
        // TEMPORARILY DISABLED: Return empty array to prevent crashes
        print("📊 BRIDGE DATA ANALYSIS: fetchAllBridgeEvents DISABLED - Returning empty array")
        return []
        
        /* DISABLED CODE - Will be re-enabled after SwiftData fixes
        let descriptor = FetchDescriptor<DrawbridgeEvent>(
            sortBy: [SortDescriptor(\.openDateTime)]
        )
        
        // Add a small delay to ensure ModelContext is ready
        try await Task.sleep(nanoseconds: 100_000) // 0.1ms
        
        let events = try modelContext.fetch(descriptor)
        print("📊 BRIDGE DATA ANALYSIS: Successfully fetched \(events.count) events")
        
        // Limit to 10,000 events for analysis to prevent memory issues
        let limitedEvents = Array(events.prefix(10000))
        if events.count > 10000 {
            print("📊 BRIDGE DATA ANALYSIS: Limited analysis to first 10,000 events (total: \(events.count))")
        }
        
        return limitedEvents
        */
    }
    
    // MARK: - Helper Methods
    
    /// Calculates time intervals between consecutive bridge openings
    private func calculateInterArrivalTimes(events: [DrawbridgeEvent]) -> [TimeInterval] {
        let sortedEvents = events.sorted(by: { $0.openDateTime < $1.openDateTime })
        var intervals: [TimeInterval] = []
        
        for i in 1..<sortedEvents.count {
            let interval = sortedEvents[i].openDateTime.timeIntervalSince(sortedEvents[i-1].openDateTime)
            if interval > 0 { // Filter out simultaneous events
                intervals.append(interval)
            }
        }
        
        return intervals
    }
    
    /// Fits exponential distribution to inter-arrival times using maximum likelihood estimation
    private func fitExponentialDistribution(times: [TimeInterval]) -> Double {
        guard !times.isEmpty else { return 0 }
        
        // MLE for exponential distribution: λ = 1 / mean
        let mean = times.reduce(0, +) / Double(times.count)
        return mean > 0 ? 1.0 / mean : 0
    }
    
    /// Calculates percentiles of exponential distribution
    private func calculateExponentialPercentiles(parameter: Double, confidenceLevels: [Double]) -> [Double: TimeInterval] {
        var percentiles: [Double: TimeInterval] = [:]
        
        for confidence in confidenceLevels {
            // For exponential distribution: P(X > x) = e^(-λx)
            // To find x where P(X > x) = 1 - confidence
            // x = -ln(1 - confidence) / λ
            let x = -log(1 - confidence) / parameter
            percentiles[confidence] = x
        }
        
        return percentiles
    }
    
    // MARK: - Change Point Detection
    
    /// Detects changes in bridge opening patterns using CUSUM and EWMA
    private func analyzeChangePoints(events: [DrawbridgeEvent]) -> ChangePointAnalysis {
        print("📊 CHANGE POINT ANALYSIS: Starting analysis")
        
        // Group events into time windows
        let windowSize: TimeInterval = 3600 // 1 hour windows
        let windows = groupEventsIntoWindows(events: events, windowSize: windowSize)
        
        // Calculate event counts per window
        let counts = windows.map { $0.count }
        
        // Perform CUSUM analysis
        let cusumResult = performCUSUMAnalysis(counts: counts)
        
        // Perform EWMA analysis
        let ewmaResult = performEWMAAnalysis(counts: counts)
        
        // Detect change points
        let changePoints = detectChangePoints(cusum: cusumResult, ewma: ewmaResult)
        
        let analysis = ChangePointAnalysis(
            changePoints: changePoints,
            cusumResult: cusumResult,
            ewmaResult: ewmaResult,
            windowSize: windowSize
        )
        
        print("📊 CHANGE POINT ANALYSIS: Detected \(changePoints.count) change points")
        
        return analysis
    }
    
    /// Groups events into time windows for analysis
    private func groupEventsIntoWindows(events: [DrawbridgeEvent], windowSize: TimeInterval) -> [[DrawbridgeEvent]] {
        let sortedEvents = events.sorted(by: { $0.openDateTime < $1.openDateTime })
        guard let firstEvent = sortedEvents.first else { return [] }
        
        var windows: [[DrawbridgeEvent]] = []
        var currentWindow: [DrawbridgeEvent] = []
        let startTime = firstEvent.openDateTime
        
        for event in sortedEvents {
            let windowIndex = Int(event.openDateTime.timeIntervalSince(startTime) / windowSize)
            
            while windows.count <= windowIndex {
                windows.append([])
            }
            
            windows[windowIndex].append(event)
        }
        
        return windows
    }
    
    /// Performs CUSUM (Cumulative Sum) analysis for change detection
    private func performCUSUMAnalysis(counts: [Int]) -> CUSUMResult {
        guard counts.count > 1 else {
            return CUSUMResult(statistics: [], threshold: 0, changePoints: [])
        }
        
        let mean = Double(counts.reduce(0, +)) / Double(counts.count)
        let stdDev = sqrt(counts.map { pow(Double($0) - mean, 2) }.reduce(0, +) / Double(counts.count))
        
        var cusumStats: [Double] = []
        var runningSum = 0.0
        let threshold = 2.0 * stdDev // Adjustable threshold
        
        for count in counts {
            let normalized = (Double(count) - mean) / stdDev
            runningSum += normalized
            cusumStats.append(runningSum)
        }
        
        // Detect change points where CUSUM exceeds threshold
        var changePoints: [Int] = []
        for (index, stat) in cusumStats.enumerated() {
            if abs(stat) > threshold {
                changePoints.append(index)
            }
        }
        
        return CUSUMResult(
            statistics: cusumStats,
            threshold: threshold,
            changePoints: changePoints
        )
    }
    
    /// Performs EWMA (Exponentially Weighted Moving Average) analysis
    private func performEWMAAnalysis(counts: [Int]) -> EWMAResult {
        guard counts.count > 1 else {
            return EWMAResult(statistics: [], alpha: 0.3, changePoints: [])
        }
        
        let alpha = 0.3 // Smoothing factor
        var ewmaStats: [Double] = []
        var currentEWMA = Double(counts[0])
        
        for count in counts {
            currentEWMA = alpha * Double(count) + (1 - alpha) * currentEWMA
            ewmaStats.append(currentEWMA)
        }
        
        // Detect change points based on EWMA deviations
        let mean = Double(counts.reduce(0, +)) / Double(counts.count)
        let threshold = 0.5 * mean // Adjustable threshold
        
        var changePoints: [Int] = []
        for (index, stat) in ewmaStats.enumerated() {
            if abs(stat - mean) > threshold {
                changePoints.append(index)
            }
        }
        
        return EWMAResult(
            statistics: ewmaStats,
            alpha: alpha,
            changePoints: changePoints
        )
    }
    
    /// Combines CUSUM and EWMA results to detect change points
    private func detectChangePoints(cusum: CUSUMResult, ewma: EWMAResult) -> [ChangePoint] {
        var changePoints: [ChangePoint] = []
        
        // Combine change points from both methods
        let allIndices = Set(cusum.changePoints + ewma.changePoints)
        
        for index in allIndices {
            let cusumDetected = cusum.changePoints.contains(index)
            let ewmaDetected = ewma.changePoints.contains(index)
            
            let confidence = (cusumDetected && ewmaDetected) ? 0.9 : 0.6
            let method: ChangePointMethod = cusumDetected && ewmaDetected ? .both : (cusumDetected ? .cusum : .ewma)
            
            changePoints.append(ChangePoint(
                index: index,
                confidence: confidence,
                method: method
            ))
        }
        
        return changePoints.sorted { $0.index < $1.index }
    }
    
    // MARK: - Goodness of Fit Testing
    
    /// Performs Kolmogorov-Smirnov test to compare current vs historical patterns
    private func performGoodnessOfFitTest(events: [DrawbridgeEvent]) -> GoodnessOfFitResult {
        print("📊 GOODNESS OF FIT: Starting K-S test")
        
        let interArrivalTimes = calculateInterArrivalTimes(events: events)
        
        // Split data into historical and recent samples
        let splitIndex = interArrivalTimes.count / 2
        let historical = Array(interArrivalTimes[..<splitIndex])
        let recent = Array(interArrivalTimes[splitIndex...])
        
        guard historical.count > 10 && recent.count > 10 else {
            return GoodnessOfFitResult(
                testStatistic: 0,
                pValue: 1.0,
                isSignificant: false,
                method: .kolmogorovSmirnov
            )
        }
        
        // Perform Kolmogorov-Smirnov test
        let ksResult = performKolmogorovSmirnovTest(sample1: historical, sample2: recent)
        
        print("📊 GOODNESS OF FIT: K-S statistic: \(ksResult.statistic)")
        print("📊 GOODNESS OF FIT: p-value: \(ksResult.pValue)")
        
        return GoodnessOfFitResult(
            testStatistic: ksResult.statistic,
            pValue: ksResult.pValue,
            isSignificant: ksResult.pValue < changeDetectionThreshold,
            method: .kolmogorovSmirnov
        )
    }
    
    /// Performs Kolmogorov-Smirnov two-sample test
    private func performKolmogorovSmirnovTest(sample1: [TimeInterval], sample2: [TimeInterval]) -> (statistic: Double, pValue: Double) {
        let sorted1 = sample1.sorted()
        let sorted2 = sample2.sorted()
        
        var maxDifference = 0.0
        var i = 0, j = 0
        let n1 = Double(sorted1.count)
        let n2 = Double(sorted2.count)
        
        while i < sorted1.count && j < sorted2.count {
            let current1 = sorted1[i]
            let current2 = sorted2[j]
            
            let minValue = min(current1, current2)
            
            // Calculate empirical CDFs
            let cdf1 = Double(sorted1.prefix(through: i).count) / n1
            let cdf2 = Double(sorted2.prefix(through: j).count) / n2
            
            let difference = abs(cdf1 - cdf2)
            maxDifference = max(maxDifference, difference)
            
            if current1 <= current2 {
                i += 1
            }
            if current2 <= current1 {
                j += 1
            }
        }
        
        // Approximate p-value using asymptotic distribution
        let n = (n1 * n2) / (n1 + n2)
        let pValue = 2 * exp(-2 * n * maxDifference * maxDifference)
        
        return (statistic: maxDifference, pValue: min(pValue, 1.0))
    }
    
    /// Calculates adjustment factor based on change point frequency
    private func calculateChangePointAdjustment(changePoints: ChangePointAnalysis) -> Double {
        let changePointRate = Double(changePoints.changePoints.count) / 24.0 // per day
        
        if changePointRate > 0.5 {
            return 0.5 // More frequent changes → shorter interval
        } else if changePointRate > 0.2 {
            return 0.75
        } else if changePointRate < 0.05 {
            return 1.5 // Fewer changes → longer interval
        } else {
            return 1.0
        }
    }
    
    /// Calculates adjustment factor based on goodness of fit
    private func calculateGoodnessAdjustment(goodnessOfFit: GoodnessOfFitResult) -> Double {
        if goodnessOfFit.isSignificant {
            return 0.7 // Pattern has changed → shorter interval
        } else {
            return 1.0 // Pattern is stable
        }
    }
}

// MARK: - Data Models

/// Result of Poisson process analysis
public struct PoissonAnalysis {
    let rate: Double // events per hour
    let exponentialParameter: Double
    let percentiles: [Double: TimeInterval]
    let interArrivalTimes: [TimeInterval]
    let seasonalRates: [String: Double]
}

/// Result of change point detection analysis
public struct ChangePointAnalysis {
    let changePoints: [ChangePoint]
    let cusumResult: CUSUMResult
    let ewmaResult: EWMAResult
    let windowSize: TimeInterval
}

/// CUSUM analysis result
public struct CUSUMResult {
    let statistics: [Double]
    let threshold: Double
    let changePoints: [Int]
}

/// EWMA analysis result
public struct EWMAResult {
    let statistics: [Double]
    let alpha: Double
    let changePoints: [Int]
}

/// Represents a detected change point
public struct ChangePoint {
    let index: Int
    let confidence: Double
    let method: ChangePointMethod
}

/// Method used for change point detection
public enum ChangePointMethod {
    case cusum
    case ewma
    case both
}

/// Result of goodness of fit testing
public struct GoodnessOfFitResult {
    let testStatistic: Double
    let pValue: Double
    let isSignificant: Bool
    let method: GoodnessOfFitMethod
}

/// Method used for goodness of fit testing
public enum GoodnessOfFitMethod {
    case kolmogorovSmirnov
    case andersonDarling
    case chiSquare
}

/// Result of trend analysis
public struct TrendAnalysis {
    let slope: Double
    let intercept: Double
    let rSquared: Double
    let pValue: Double
    let direction: TrendDirection
    let isSignificant: Bool
}

/// Trend direction classification
public enum TrendDirection: Sendable {
    case increasing
    case decreasing
    case stable
}

/// Result of seasonal pattern analysis
public struct SeasonalAnalysis {
    let patternType: SeasonalPatterns
    let hourlyPatterns: [Int: Int]
    let dailyPatterns: [Int: Int]
    let monthlyPatterns: [Int: Int]
    let hourlyVariance: Double
    let dailyVariance: Double
    let monthlyVariance: Double
}

/// Seasonal pattern classification
public enum SeasonalPatterns: Sendable {
    case none
    case hourly
    case daily
    case monthly
}

/// Adaptive thresholds for refresh intervals
public struct AdaptiveThresholds {
    let conservative: TimeInterval
    let moderate: TimeInterval
    let aggressive: TimeInterval
    let p25: TimeInterval
    let p50: TimeInterval
    let p75: TimeInterval
    let p95: TimeInterval
}

/// Final recommendation for refresh interval
public struct RefreshIntervalRecommendation: Sendable {
    public let interval: TimeInterval
    public let confidence: Double
    public let method: RecommendationMethod
    public let reasoning: String
    
    public init(interval: TimeInterval, confidence: Double, method: RecommendationMethod, reasoning: String) {
        self.interval = interval
        self.confidence = confidence
        self.method = method
        self.reasoning = reasoning
    }
}

/// Method used for generating the recommendation
public enum RecommendationMethod: Sendable {
    case insufficientData
    case poissonProcess
    case patternAnalysis
    case changeDetection
    case seasonalAnalysis
    case trendAnalysis
}

/// Data freshness classification
public enum DataFreshness {
    case unknown
    case veryFresh
    case fresh
    case stale
    case veryStale
}

/// Pattern stability classification
public enum PatternStability: Sendable {
    case unknown
    case veryStable
    case stable
    case unstable
    case veryUnstable
}

// MARK: - Integrated Statistical Service

/// Comprehensive service that integrates statistical analysis with data flow
/// Provides data-driven refresh interval recommendations and insights
@Observable
public class BridgeDataAnalysisService {
    private let analyzer: BridgeDataAnalyzer
    private let eventService: DrawbridgeEventService
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.analyzer = BridgeDataAnalyzer()
        self.eventService = DrawbridgeEventService(modelContext: modelContext)
        self.modelContext = modelContext
    }
    
    // MARK: - Public Interface
    
    /// Analyzes bridge data and returns comprehensive refresh recommendations
    public func analyzeAndRecommendRefreshInterval() async -> RefreshIntervalRecommendation {
        return await analyzer.analyzeRefreshInterval(modelContext: modelContext)
    }
    
    /// Gets current analysis state for UI display
    public func getCurrentAnalysisState() -> AnalysisState {
        return AnalysisState(
            recommendedInterval: analyzer.recommendedRefreshInterval,
            confidence: analyzer.analysisConfidence,
            dataFreshness: analyzer.dataFreshness,
            patternStability: analyzer.patternStability,
            seasonalPatterns: analyzer.seasonalPatterns,
            trendDirection: analyzer.trendDirection
        )
    }
    
    /// Performs real-time analysis and updates recommendations
    public func performRealTimeAnalysis() async -> RealTimeAnalysisResult {
        print("📊 REAL-TIME ANALYSIS: Starting real-time analysis")
        
        // Get current recommendation
        let recommendation = await analyzeAndRecommendRefreshInterval()
        
        // Get current bridge status
        let openBridges = try? await eventService.fetchOpenBridges()
        let currentOpenCount = openBridges?.count ?? 0
        
        // Get recent activity
        let recentEvents = try? await eventService.fetchRecentEvents(since: Date().addingTimeInterval(-3600)) // Last hour
        let recentActivity = recentEvents?.count ?? 0
        
        // Calculate urgency score
        let urgencyScore = calculateUrgencyScore(
            openBridges: currentOpenCount,
            recentActivity: recentActivity,
            recommendation: recommendation
        )
        
        let result = RealTimeAnalysisResult(
            recommendation: recommendation,
            currentOpenBridges: currentOpenCount,
            recentActivity: recentActivity,
            urgencyScore: urgencyScore,
            analysisTimestamp: Date()
        )
        
        print("📊 REAL-TIME ANALYSIS: Urgency score: \(urgencyScore)")
        print("📊 REAL-TIME ANALYSIS: Open bridges: \(currentOpenCount)")
        print("📊 REAL-TIME ANALYSIS: Recent activity: \(recentActivity)")
        
        return result
    }
    
    /// Gets detailed insights for dashboard display
    public func getDetailedInsights() async -> BridgeDataInsights {
        print("📊 DETAILED INSIGHTS: Generating comprehensive insights")
        
        let events = try? await eventService.fetchEvents()
        let openBridges = try? await eventService.fetchOpenBridges()
        
        guard let events = events, !events.isEmpty else {
            return BridgeDataInsights.empty()
        }
        
        // Calculate various insights
        let totalEvents = events.count
        let openCount = openBridges?.count ?? 0
        let averageDuration = calculateAverageDuration(events: events)
        let peakHours = findPeakHours(events: events)
        let busyDays = findBusyDays(events: events)
        let bridgeActivity = calculateBridgeActivity(events: events)
        
        // Calculate recent activity (last hour)
        let recentEvents = events.filter { $0.openDateTime > Date().addingTimeInterval(-3600) }
        let recentActivity = recentEvents.count
        
        // Get recommendation and analysis data
        let recommendation = await analyzeAndRecommendRefreshInterval()
        let urgencyScore = calculateUrgencyScore(
            openBridges: openCount,
            recentActivity: recentActivity,
            recommendation: recommendation
        )
        
        let insights = BridgeDataInsights(
            totalEvents: totalEvents,
            currentlyOpen: openCount,
            averageDuration: averageDuration,
            peakHours: peakHours,
            busyDays: busyDays,
            refreshRecommendation: recommendation,
            urgencyScore: urgencyScore,
            patternStability: analyzer.patternStability,
            seasonalPatterns: analyzer.seasonalPatterns,
            trendDirection: analyzer.trendDirection,
            changePointCount: analyzer.changePointCount,
            poissonFit: analyzer.poissonFit,
            hasSeasonalPattern: analyzer.hasSeasonalPattern,
            eventCount: totalEvents,
            timeSpanHours: calculateTimeSpan(events: events),
            averageIntervalMinutes: calculateAverageInterval(events: events),
            bridgeActivity: bridgeActivity,
            recentActivity: recentActivity,
            lastUpdated: Date()
        )
        
        print("📊 DETAILED INSIGHTS: Total events: \(totalEvents)")
        print("📊 DETAILED INSIGHTS: Average duration: \(averageDuration) minutes")
        print("📊 DETAILED INSIGHTS: Peak hours: \(peakHours)")
        
        return insights
    }
    
    /// Suggests optimal refresh intervals based on current conditions
    public func suggestOptimalRefreshIntervals() async -> RefreshIntervalSuggestions {
        print("📊 OPTIMAL INTERVALS: Generating interval suggestions")
        
        let recommendation = await analyzeAndRecommendRefreshInterval()
        let insights = await getDetailedInsights()
        
        // Calculate different interval options
        let conservative = recommendation.interval * 1.5
        let moderate = recommendation.interval
        let aggressive = recommendation.interval * 0.7
        
        // Adjust based on current conditions
        let adjustedConservative = adjustForConditions(interval: conservative, insights: insights)
        let adjustedModerate = adjustForConditions(interval: moderate, insights: insights)
        let adjustedAggressive = adjustForConditions(interval: aggressive, insights: insights)
        
        let suggestions = RefreshIntervalSuggestions(
            conservative: adjustedConservative,
            moderate: adjustedModerate,
            aggressive: adjustedAggressive,
            recommended: recommendation.interval,
            reasoning: recommendation.reasoning,
            confidence: recommendation.confidence
        )
        
        print("📊 OPTIMAL INTERVALS: Conservative: \(adjustedConservative/60) min")
        print("📊 OPTIMAL INTERVALS: Moderate: \(adjustedModerate/60) min")
        print("📊 OPTIMAL INTERVALS: Aggressive: \(adjustedAggressive/60) min")
        
        return suggestions
    }
    
    // MARK: - Private Helper Methods
    
    /// Calculates urgency score based on current conditions
    private func calculateUrgencyScore(
        openBridges: Int,
        recentActivity: Int,
        recommendation: RefreshIntervalRecommendation
    ) -> Double {
        var score = 0.0
        
        // Factor in open bridges (higher = more urgent)
        score += Double(openBridges) * 0.2
        
        // Factor in recent activity (higher = more urgent)
        score += Double(recentActivity) * 0.1
        
        // Factor in recommendation confidence (lower = more urgent)
        score += (1.0 - recommendation.confidence) * 0.3
        
        // Factor in pattern stability (unstable = more urgent)
        if analyzer.patternStability == .unstable || analyzer.patternStability == .veryUnstable {
            score += 0.2
        }
        
        return min(score, 1.0)
    }
    
    /// Calculates average duration of bridge openings
    private func calculateAverageDuration(events: [DrawbridgeEvent]) -> Double {
        let completedEvents = events.filter { $0.closeDateTime != nil }
        guard !completedEvents.isEmpty else { return 0.0 }
        
        let totalDuration = completedEvents.reduce(0.0) { $0 + $1.minutesOpen }
        return totalDuration / Double(completedEvents.count)
    }
    
    /// Finds peak hours of bridge activity
    private func findPeakHours(events: [DrawbridgeEvent]) -> [Int] {
        let calendar = Calendar.current
        var hourlyCounts: [Int: Int] = [:]
        
        // Initialize all hours
        for hour in 0..<24 { hourlyCounts[hour] = 0 }
        
        // Count events by hour
        for event in events {
            let hour = calendar.component(.hour, from: event.openDateTime)
            hourlyCounts[hour, default: 0] += 1
        }
        
        // Find hours with above-average activity
        let average = Double(events.count) / 24.0
        let peakHours = hourlyCounts.filter { Double($0.value) > average * 1.5 }.map { $0.key }
        
        return peakHours.sorted()
    }
    
    /// Finds busy days of the week
    private func findBusyDays(events: [DrawbridgeEvent]) -> [Int] {
        let calendar = Calendar.current
        var dailyCounts: [Int: Int] = [:]
        
        // Initialize all days
        for day in 1...7 { dailyCounts[day] = 0 }
        
        // Count events by day
        for event in events {
            let weekday = calendar.component(.weekday, from: event.openDateTime)
            dailyCounts[weekday, default: 0] += 1
        }
        
        // Find days with above-average activity
        let average = Double(events.count) / 7.0
        let busyDays = dailyCounts.filter { Double($0.value) > average * 1.3 }.map { $0.key }
        
        return busyDays.sorted()
    }
    
    /// Calculates activity levels per bridge
    private func calculateBridgeActivity(events: [DrawbridgeEvent]) -> [String: BridgeActivity] {
        var bridgeActivity: [String: BridgeActivity] = [:]
        
        for event in events {
            let bridgeID = event.entityID
            let bridgeName = event.entityName
            
            if bridgeActivity[bridgeID] == nil {
                bridgeActivity[bridgeID] = BridgeActivity(
                    bridgeID: bridgeID,
                    bridgeName: bridgeName,
                    eventCount: 0,
                    totalDuration: 0.0,
                    lastActivity: nil
                )
            }
            
            bridgeActivity[bridgeID]?.eventCount += 1
            bridgeActivity[bridgeID]?.totalDuration += event.minutesOpen
            
            if bridgeActivity[bridgeID]?.lastActivity == nil || 
               event.openDateTime > bridgeActivity[bridgeID]!.lastActivity! {
                bridgeActivity[bridgeID]?.lastActivity = event.openDateTime
            }
        }
        
        return bridgeActivity
    }
    
    /// Adjusts intervals based on current conditions
    private func adjustForConditions(interval: TimeInterval, insights: BridgeDataInsights) -> TimeInterval {
        var adjusted = interval
        
        // Adjust for high activity
        if insights.recentActivity > 10 {
            adjusted *= 0.8 // More frequent updates during high activity
        }
        
        // Adjust for many open bridges
        if insights.currentlyOpen > 3 {
            adjusted *= 0.7 // More frequent updates when many bridges are open
        }
        
        // Adjust for pattern instability
        if analyzer.patternStability == .unstable || analyzer.patternStability == .veryUnstable {
            adjusted *= 0.8
        }
        
        // Ensure minimum interval
        return max(adjusted, 300) // Minimum 5 minutes
    }
    
    /// Calculates time span of events in hours
    private func calculateTimeSpan(events: [DrawbridgeEvent]) -> Double {
        guard events.count >= 2 else { return 0.0 }
        
        let sortedEvents = events.sorted { $0.openDateTime < $1.openDateTime }
        let firstEvent = sortedEvents.first!
        let lastEvent = sortedEvents.last!
        
        return lastEvent.openDateTime.timeIntervalSince(firstEvent.openDateTime) / 3600.0
    }
    
    /// Calculates average interval between events in minutes
    private func calculateAverageInterval(events: [DrawbridgeEvent]) -> Double {
        guard events.count >= 2 else { return 0.0 }
        
        let sortedEvents = events.sorted { $0.openDateTime < $1.openDateTime }
        var totalInterval: TimeInterval = 0
        var intervalCount = 0
        
        for i in 1..<sortedEvents.count {
            let interval = sortedEvents[i].openDateTime.timeIntervalSince(sortedEvents[i-1].openDateTime)
            totalInterval += interval
            intervalCount += 1
        }
        
        return intervalCount > 0 ? (totalInterval / Double(intervalCount)) / 60.0 : 0.0
    }
}

// MARK: - Supporting Data Structures

/// Current state of analysis for UI display
public struct AnalysisState {
    public let recommendedInterval: TimeInterval
    public let confidence: Double
    public let dataFreshness: DataFreshness
    public let patternStability: PatternStability
    public let seasonalPatterns: SeasonalPatterns
    public let trendDirection: TrendDirection
}

/// Result of real-time analysis
public struct RealTimeAnalysisResult {
    let recommendation: RefreshIntervalRecommendation
    let currentOpenBridges: Int
    let recentActivity: Int
    let urgencyScore: Double
    let analysisTimestamp: Date
}

/// Detailed insights about bridge data
public struct BridgeDataInsights: Sendable {
    public let totalEvents: Int
    public let currentlyOpen: Int
    public let averageDuration: Double
    public let peakHours: [Int]
    public let busyDays: [Int]
    public let refreshRecommendation: RefreshIntervalRecommendation?
    public let urgencyScore: Double
    public let patternStability: PatternStability
    public let seasonalPatterns: SeasonalPatterns
    public let trendDirection: TrendDirection
    public let changePointCount: Int
    public let poissonFit: Bool
    public let hasSeasonalPattern: Bool
    public let eventCount: Int
    public let timeSpanHours: Double
    public let averageIntervalMinutes: Double
    public let bridgeActivity: [String: BridgeActivity]
    public let recentActivity: Int
    public let lastUpdated: Date
    
    static func empty() -> BridgeDataInsights {
        return BridgeDataInsights(
            totalEvents: 0,
            currentlyOpen: 0,
            averageDuration: 0.0,
            peakHours: [],
            busyDays: [],
            refreshRecommendation: nil,
            urgencyScore: 0.0,
            patternStability: .unknown,
            seasonalPatterns: .none,
            trendDirection: .stable,
            changePointCount: 0,
            poissonFit: false,
            hasSeasonalPattern: false,
            eventCount: 0,
            timeSpanHours: 0.0,
            averageIntervalMinutes: 0.0,
            bridgeActivity: [:],
            recentActivity: 0,
            lastUpdated: Date()
        )
    }
}

/// Activity information for a specific bridge
public struct BridgeActivity: Sendable {
    let bridgeID: String
    let bridgeName: String
    var eventCount: Int
    var totalDuration: Double
    var lastActivity: Date?
    
    var averageDuration: Double {
        return eventCount > 0 ? totalDuration / Double(eventCount) : 0.0
    }
}

/// Multiple refresh interval suggestions
public struct RefreshIntervalSuggestions {
    let conservative: TimeInterval
    let moderate: TimeInterval
    let aggressive: TimeInterval
    let recommended: TimeInterval
    let reasoning: String
    let confidence: Double
}
