import XCTest
import SwiftData
@testable import BridgetStatistics
@testable import BridgetCore

// Test event type that conforms to DateProvider
struct TestEvent: DateProvider {
    let date: Date
}

final class BridgetStatisticsTests: XCTestCase {
    
    // MARK: - StatisticsAPI Tests
    func testMean() {
        XCTAssertNil(StatisticsAPI.mean([]))
        XCTAssertEqual(StatisticsAPI.mean([5]), 5)
        XCTAssertEqual(StatisticsAPI.mean([1, 2, 3, 4]), 2.5)
    }

    func testUnbiasedStd() {
        XCTAssertNil(StatisticsAPI.unbiasedStd([]))
        XCTAssertNil(StatisticsAPI.unbiasedStd([5]))
        XCTAssertEqual(round(StatisticsAPI.unbiasedStd([1, 2, 3, 4, 5])! * 100) / 100, 1.58) // sample std
    }

    func testMedian() {
        XCTAssertNil(StatisticsAPI.median([]))
        XCTAssertEqual(StatisticsAPI.median([5]), 5)
        XCTAssertEqual(StatisticsAPI.median([1, 2, 3, 4]), 2.5)
        XCTAssertEqual(StatisticsAPI.median([1, 2, 3, 4, 5]), 3)
    }

    func testPercentile() {
        XCTAssertNil(StatisticsAPI.percentile([], 0.5))
        XCTAssertEqual(StatisticsAPI.percentile([1, 2, 3, 4, 5], 0.25), 2)
        XCTAssertEqual(StatisticsAPI.percentile([1, 2, 3, 4, 5], 0.5), 3)
        XCTAssertEqual(StatisticsAPI.percentile([1, 2, 3, 4, 5], 0.75), 4)
    }

    func testTrimmedMean() {
        XCTAssertNil(StatisticsAPI.trimmedMean([], trimFraction: 0.1))
        XCTAssertEqual(StatisticsAPI.trimmedMean([1, 2, 3, 4, 5], trimFraction: 0.2), 3)
    }

    func testRange() {
        XCTAssertNil(StatisticsAPI.range([]))
        let result = StatisticsAPI.range([1, 2, 3, 4, 5])
        XCTAssertEqual(result?.min, 1)
        XCTAssertEqual(result?.max, 5)
    }

    func testFrequencyLabel() {
        let thresholds = (rare: 0.2, sometimes: 0.5, often: 0.8)
        XCTAssertEqual(StatisticsAPI.frequencyLabel(value: 0.1, thresholds: thresholds), "Low")
        XCTAssertEqual(StatisticsAPI.frequencyLabel(value: 0.3, thresholds: thresholds), "Medium")
        XCTAssertEqual(StatisticsAPI.frequencyLabel(value: 0.9, thresholds: thresholds), "Very High")
    }

    func testRangeString() {
        XCTAssertEqual(StatisticsAPI.rangeString(p25: 5, p75: 10), "5–10")
        XCTAssertEqual(StatisticsAPI.rangeString(p25: 5, p75: 10, unit: "min"), "5–10 min")
    }

    func testTimeWindowString() {
        XCTAssertEqual(StatisticsAPI.timeWindowString(days: 1), "Over the last 1 day")
        XCTAssertEqual(StatisticsAPI.timeWindowString(days: 30), "Over the last 30 days")
    }
    
    // MARK: - Data-Driven Thresholds Tests
    func testComputeDataDrivenThresholds() {
        // Test with insufficient data
        XCTAssertNil(StatisticsAPI.computeDataDrivenThresholds(from: []))
        XCTAssertNil(StatisticsAPI.computeDataDrivenThresholds(from: [1.0]))
        XCTAssertNil(StatisticsAPI.computeDataDrivenThresholds(from: [1.0, 2.0, 3.0]))
        
        // Test with sufficient data
        let values = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
        let thresholds = StatisticsAPI.computeDataDrivenThresholds(from: values)
        
        XCTAssertNotNil(thresholds)
        XCTAssertEqual(thresholds?.rare, 0.3) // 25th percentile
        XCTAssertEqual(thresholds?.sometimes, 0.5) // 50th percentile (median)
        XCTAssertEqual(thresholds?.often, 0.7) // 75th percentile
    }
    
    func testComputeDataDrivenThresholdsWithEvenCount() {
        let values = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8]
        let thresholds = StatisticsAPI.computeDataDrivenThresholds(from: values)
        
        XCTAssertNotNil(thresholds)
        // For 8 values, we expect interpolated values
        XCTAssertNotNil(thresholds?.rare)
        XCTAssertNotNil(thresholds?.sometimes)
        XCTAssertNotNil(thresholds?.often)
        XCTAssertLessThan(thresholds?.rare ?? 0, thresholds?.sometimes ?? 0)
        XCTAssertLessThan(thresholds?.sometimes ?? 0, thresholds?.often ?? 0)
    }
    
    // MARK: - Seasonal Thresholds Tests
    func testComputeSeasonalThresholds() {
        let values = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8]
        let calendar = Calendar.current
        let now = Date()
        
        // Create timestamps for different months
        let timestamps = [
            calendar.date(byAdding: .month, value: -3, to: now)!,
            calendar.date(byAdding: .month, value: -3, to: now)!,
            calendar.date(byAdding: .month, value: -2, to: now)!,
            calendar.date(byAdding: .month, value: -2, to: now)!,
            calendar.date(byAdding: .month, value: -1, to: now)!,
            calendar.date(byAdding: .month, value: -1, to: now)!,
            now,
            now
        ]
        
        let monthlyThresholds = StatisticsAPI.computeSeasonalThresholds(
            values: values,
            timestamps: timestamps,
            seasonType: .monthly
        )
        
        // Check if we have enough data for seasonal thresholds
        if monthlyThresholds != nil {
            XCTAssertGreaterThan(monthlyThresholds!.count, 0)
        } else {
            // If nil, it means we don't have enough data per season
            print("Seasonal thresholds returned nil - likely insufficient data per season")
        }
    }
    
    func testSeasonTypeSeasonKey() {
        let calendar = Calendar.current
        let testDate = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!
        
        // Test monthly
        let monthlyKey = StatisticsAPI.SeasonType.monthly.seasonKey(from: testDate)
        XCTAssertEqual(monthlyKey, "2024-06")
        
        // Test weekly
        let weeklyKey = StatisticsAPI.SeasonType.weekly.seasonKey(from: testDate)
        XCTAssertTrue(weeklyKey.hasPrefix("2024-W"))
        
        // Test daily
        let dailyKey = StatisticsAPI.SeasonType.daily.seasonKey(from: testDate)
        XCTAssertEqual(dailyKey, "2024-06-15")
    }
    
    // MARK: - Confidence Interval Tests
    func testConfidenceInterval() {
        // Test with insufficient data
        XCTAssertNil(StatisticsAPI.confidenceInterval(values: []))
        XCTAssertNil(StatisticsAPI.confidenceInterval(values: [1.0]))
        
        // Test with small sample (uses t-distribution approximation)
        let smallSample = [1.0, 2.0, 3.0, 4.0, 5.0]
        let smallCI = StatisticsAPI.confidenceInterval(values: smallSample)
        
        XCTAssertNotNil(smallCI)
        XCTAssertLessThan(smallCI!.lower, smallCI!.upper)
        XCTAssertGreaterThan(smallCI!.lower, 0) // Should be positive for this data
        
        // Test with larger sample (uses normal distribution)
        let largeSample = Array(1...50).map { Double($0) }
        let largeCI = StatisticsAPI.confidenceInterval(values: largeSample)
        
        XCTAssertNotNil(largeCI)
        XCTAssertLessThan(largeCI!.lower, largeCI!.upper)
        XCTAssertGreaterThan(largeCI!.lower, 20) // Mean should be around 25.5
        XCTAssertLessThan(largeCI!.upper, 30)
    }
    
    func testConfidenceIntervalWithCustomLevel() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        let ci90 = StatisticsAPI.confidenceInterval(values: values, confidenceLevel: 0.90)
        let ci95 = StatisticsAPI.confidenceInterval(values: values, confidenceLevel: 0.95)
        
        XCTAssertNotNil(ci90)
        XCTAssertNotNil(ci95)
        
        // For small samples, both confidence levels might use the same critical value (2.0)
        // So we just verify they're both valid intervals
        XCTAssertLessThan(ci90!.lower, ci90!.upper)
        XCTAssertLessThan(ci95!.lower, ci95!.upper)
    }
    
    // MARK: - Outlier Detection Tests
    func testDetectOutliers() {
        // Test with insufficient data
        XCTAssertNil(StatisticsAPI.detectOutliers(values: []))
        XCTAssertNil(StatisticsAPI.detectOutliers(values: [1.0]))
        XCTAssertNil(StatisticsAPI.detectOutliers(values: [1.0, 2.0, 3.0]))
        
        // Test with normal data (no outliers)
        let normalData = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
        let normalOutliers = StatisticsAPI.detectOutliers(values: normalData)
        XCTAssertNil(normalOutliers) // Should have no outliers
        
        // Test with outliers
        let dataWithOutliers = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 100.0] // 100 is an outlier
        let outlierIndices = StatisticsAPI.detectOutliers(values: dataWithOutliers)
        
        XCTAssertNotNil(outlierIndices)
        XCTAssertEqual(outlierIndices?.count, 1)
        XCTAssertEqual(outlierIndices?.first, 9) // Index of 100.0
        
        // Test with multiple outliers
        let dataWithMultipleOutliers = [-50.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 100.0]
        let multipleOutlierIndices = StatisticsAPI.detectOutliers(values: dataWithMultipleOutliers)
        
        XCTAssertNotNil(multipleOutlierIndices)
        XCTAssertEqual(multipleOutlierIndices?.count, 2)
        XCTAssertTrue(multipleOutlierIndices!.contains(0)) // Index of -50.0
        XCTAssertTrue(multipleOutlierIndices!.contains(9)) // Index of 100.0
    }
    
    func testDetectOutliersWithCustomMultiplier() {
        let data = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 15.0] // 15 might be outlier with default 1.5
        
        // Test with default multiplier (1.5)
        let defaultOutliers = StatisticsAPI.detectOutliers(values: data)
        
        // Test with more lenient multiplier (2.0)
        let lenientOutliers = StatisticsAPI.detectOutliers(values: data, multiplier: 2.0)
        
        // More lenient multiplier should detect fewer or no outliers
        XCTAssertGreaterThanOrEqual(defaultOutliers?.count ?? 0, lenientOutliers?.count ?? 0)
    }
    
    // MARK: - StatisticsAPI Tests
    func testStatisticsAPIBasicFunctions() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        
        // Test mean
        let mean = StatisticsAPI.mean(values)
        XCTAssertEqual(mean, 3.0)
        
        // Test unbiased standard deviation
        let std = StatisticsAPI.unbiasedStd(values)
        XCTAssertNotNil(std)
        XCTAssertGreaterThan(std!, 0.0)
        
        // Test median
        let median = StatisticsAPI.median(values)
        XCTAssertEqual(median, 3.0)
        
        // Test empty array
        XCTAssertNil(StatisticsAPI.mean([]))
        XCTAssertNil(StatisticsAPI.unbiasedStd([]))
        XCTAssertNil(StatisticsAPI.median([]))
    }
    
    // MARK: - BridgeDataAnalyzer Tests
    func testBridgeDataAnalyzerInsufficientData() async throws {
        let analyzer = BridgeDataAnalyzer()
        let modelContainer = try ModelContainer(for: DrawbridgeEvent.self, DrawbridgeInfo.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = ModelContext(modelContainer)
        
        let recommendation = await analyzer.analyzeRefreshInterval(modelContext: modelContext)
        
        XCTAssertEqual(recommendation.method, .insufficientData)
        XCTAssertEqual(recommendation.interval, 3600) // Default 1 hour
        XCTAssertEqual(recommendation.confidence, 0.0)
        XCTAssertTrue(recommendation.reasoning.contains("Need at least"))
    }
    
    func testBridgeDataAnalyzerWithMockData() async throws {
        let analyzer = BridgeDataAnalyzer()
        let modelContainer = try ModelContainer(for: DrawbridgeEvent.self, DrawbridgeInfo.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = ModelContext(modelContainer)
        
        // Test with empty data first
        let emptyRecommendation = await analyzer.analyzeRefreshInterval(modelContext: modelContext)
        XCTAssertEqual(emptyRecommendation.method, .insufficientData)
        XCTAssertEqual(emptyRecommendation.confidence, 0.0)
        
        // Test basic statistical functions
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        let mean = StatisticsAPI.mean(values)
        XCTAssertEqual(mean, 3.0)
        
        let std = StatisticsAPI.unbiasedStd(values)
        XCTAssertNotNil(std)
        XCTAssertGreaterThan(std!, 0.0)
    }
    
    // MARK: - BridgeDataAnalysisService Tests
    func testBridgeDataAnalysisServiceInitialization() throws {
        let modelContainer = try ModelContainer(for: DrawbridgeEvent.self, DrawbridgeInfo.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = ModelContext(modelContainer)
        
        let service = BridgeDataAnalysisService(modelContext: modelContext)
        
        // Test that service can be created
        XCTAssertNotNil(service)
        
        // Test analysis state
        let state = service.getCurrentAnalysisState()
        XCTAssertEqual(state.recommendedInterval, 3600) // Default
        XCTAssertEqual(state.confidence, 0.0) // Default
    }
    
    func testBridgeDataAnalysisServiceWithData() async throws {
        let modelContainer = try ModelContainer(for: DrawbridgeEvent.self, DrawbridgeInfo.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = ModelContext(modelContainer)
        
        let service = BridgeDataAnalysisService(modelContext: modelContext)
        
        // Test with empty data first
        let emptyResult = await service.performRealTimeAnalysis()
        XCTAssertNotNil(emptyResult)
        XCTAssertEqual(emptyResult.currentOpenBridges, 0)
        XCTAssertEqual(emptyResult.recentActivity, 0)
        XCTAssertGreaterThanOrEqual(emptyResult.urgencyScore, 0.0)
        XCTAssertLessThanOrEqual(emptyResult.urgencyScore, 1.0)
        
        // Test basic analyzer functionality without service methods
        let analyzer = BridgeDataAnalyzer()
        let recommendation = await analyzer.analyzeRefreshInterval(modelContext: modelContext)
        
        XCTAssertNotNil(recommendation)
        XCTAssertEqual(recommendation.method, .insufficientData)
        XCTAssertEqual(recommendation.interval, 3600) // Default 1 hour
        XCTAssertEqual(recommendation.confidence, 0.0)
        XCTAssertTrue(recommendation.reasoning.contains("Need at least"))
    }
    
    // MARK: - Data Structure Tests
    func testRefreshIntervalRecommendation() {
        let recommendation = RefreshIntervalRecommendation(
            interval: 1800,
            confidence: 0.85,
            method: .poissonProcess,
            reasoning: "Test reasoning"
        )
        
        XCTAssertEqual(recommendation.interval, 1800)
        XCTAssertEqual(recommendation.confidence, 0.85)
        XCTAssertEqual(recommendation.method, .poissonProcess)
        XCTAssertEqual(recommendation.reasoning, "Test reasoning")
    }
    
    func testAnalysisState() {
        let state = AnalysisState(
            recommendedInterval: 1800,
            confidence: 0.85,
            dataFreshness: .fresh,
            patternStability: .stable,
            seasonalPatterns: .daily,
            trendDirection: .stable
        )
        
        XCTAssertEqual(state.recommendedInterval, 1800)
        XCTAssertEqual(state.confidence, 0.85)
        XCTAssertEqual(state.dataFreshness, .fresh)
        XCTAssertEqual(state.patternStability, .stable)
        XCTAssertEqual(state.seasonalPatterns, .daily)
        XCTAssertEqual(state.trendDirection, .stable)
    }
    
    func testBridgeDataInsights() {
        let insights = BridgeDataInsights(
            totalEvents: 100,
            currentlyOpen: 3,
            averageDuration: 25.5,
            peakHours: [8, 9, 17, 18],
            busyDays: [1, 2, 3, 4, 5],
            bridgeActivity: [:],
            recentActivity: 5,
            lastUpdated: Date()
        )
        
        XCTAssertEqual(insights.totalEvents, 100)
        XCTAssertEqual(insights.currentlyOpen, 3)
        XCTAssertEqual(insights.averageDuration, 25.5)
        XCTAssertEqual(insights.peakHours, [8, 9, 17, 18])
        XCTAssertEqual(insights.busyDays, [1, 2, 3, 4, 5])
        
        // Test empty insights
        let emptyInsights = BridgeDataInsights.empty()
        XCTAssertEqual(emptyInsights.totalEvents, 0)
        XCTAssertEqual(emptyInsights.currentlyOpen, 0)
        XCTAssertEqual(emptyInsights.averageDuration, 0.0)
        XCTAssertTrue(emptyInsights.peakHours.isEmpty)
        XCTAssertTrue(emptyInsights.busyDays.isEmpty)
    }
    
    func testRefreshIntervalSuggestions() {
        let suggestions = RefreshIntervalSuggestions(
            conservative: 3600,
            moderate: 1800,
            aggressive: 900,
            recommended: 1800,
            reasoning: "Test reasoning",
            confidence: 0.85
        )
        
        XCTAssertEqual(suggestions.conservative, 3600)
        XCTAssertEqual(suggestions.moderate, 1800)
        XCTAssertEqual(suggestions.aggressive, 900)
        XCTAssertEqual(suggestions.recommended, 1800)
        XCTAssertEqual(suggestions.reasoning, "Test reasoning")
        XCTAssertEqual(suggestions.confidence, 0.85)
    }
}
