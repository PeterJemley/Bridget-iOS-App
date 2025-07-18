import Foundation

/// Protocol for objects that provide a date property
public protocol DateProvider {
    var date: Date { get }
}

/// StatisticsAPI provides user-focused, statistically robust helpers for all analytics in Bridget.
/// All methods use unbiased estimators where needed, fixed time windows, handle small-N, and return results suitable for user-facing metrics.
public struct StatisticsAPI {
    /// Returns the mean (average) of a non-empty array of Double.
    /// Returns nil for empty arrays.
    public static func mean(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    /// Returns the unbiased sample standard deviation (divide by N-1).
    /// Returns nil for arrays with <2 elements.
    public static func unbiasedStd(_ values: [Double]) -> Double? {
        guard values.count > 1, let mean = mean(values) else { return nil }
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }

    /// Returns the true median (average of two center values for even N).
    /// Returns nil for empty arrays.
    public static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2
        } else {
            return sorted[mid]
        }
    }

    /// Returns the value at the given percentile (0...1, e.g. 0.25 for 25th percentile), using linear interpolation.
    /// Returns nil for empty arrays.
    public static func percentile(_ values: [Double], _ percentile: Double) -> Double? {
        guard !values.isEmpty, percentile >= 0, percentile <= 1 else { return nil }
        let sorted = values.sorted()
        let pos = Double(sorted.count - 1) * percentile
        let lower = Int(floor(pos))
        let upper = Int(ceil(pos))
        if lower == upper { return sorted[lower] }
        let weight = pos - Double(lower)
        return sorted[lower] * (1 - weight) + sorted[upper] * weight
    }

    /// Returns the trimmed mean, excluding the lowest and highest trimFraction of values (e.g. 0.1 trims 10% from each end).
    /// Returns nil for empty arrays or if trimFraction is too large.
    public static func trimmedMean(_ values: [Double], trimFraction: Double) -> Double? {
        guard !values.isEmpty, trimFraction >= 0, trimFraction < 0.5 else { return nil }
        let sorted = values.sorted()
        let trimCount = Int(Double(sorted.count) * trimFraction)
        let trimmed = Array(sorted.dropFirst(trimCount).dropLast(trimCount))
        return mean(trimmed)
    }

    /// Returns the range (min, max) of a non-empty array.
    public static func range(_ values: [Double]) -> (min: Double, max: Double)? {
        guard let min = values.min(), let max = values.max() else { return nil }
        return (min, max)
    }

    /// Returns a user-facing frequency label ("Low", "Medium", "High") based on value and thresholds.
    public static func frequencyLabel(value: Double, thresholds: (rare: Double, sometimes: Double, often: Double)) -> String {
        if value < thresholds.rare { return "Low" }
        if value < thresholds.sometimes { return "Medium" }
        return "High"
    }
    
    /// Returns a user-facing frequency label with custom labels.
    public static func frequencyLabel(value: Double, thresholds: (rare: Double, sometimes: Double, often: Double), labels: (low: String, medium: String, high: String)) -> String {
        if value < thresholds.rare { return labels.low }
        if value < thresholds.sometimes { return labels.medium }
        return labels.high
    }

    /// Returns a user-facing range string (e.g. "5–10 min") for percentiles.
    public static func rangeString(p25: Double, p75: Double, unit: String = "") -> String {
        let rounded25 = Int(round(p25))
        let rounded75 = Int(round(p75))
        return unit.isEmpty ? "\(rounded25)–\(rounded75)" : "\(rounded25)–\(rounded75) \(unit)"
    }

    /// Returns a user-facing time window string (e.g. "Over the last 30 days").
    public static func timeWindowString(days: Int) -> String {
        return "Over the last \(days) day\(days == 1 ? "" : "s")"
    }
    
    /// Returns a detailed time window description for statistical context.
    public static func detailedTimeWindowString(days: Int, frequency: String = "daily") -> String {
        if days <= 7 {
            return "Based on the most recent \(days) day\(days == 1 ? "" : "s") of activity"
        } else if days <= 30 {
            return "Based on the most recent \(days) days of \(frequency) activity"
        } else if days <= 90 {
            return "Average per \(frequency) over the last \(days) days"
        } else {
            return "Average per \(frequency) over the last \(days) days"
        }
    }
    
    /// Generates sparkline data for daily activity visualization.
    /// - Parameters:
    ///   - events: Array of events with timestamps
    ///   - days: Number of days to look back
    /// - Returns: Array of daily counts for sparkline
    public static func generateSparklineData<T: DateProvider>(events: [T], days: Int = 30) -> [Int] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        var dailyCounts: [Int] = Array(repeating: 0, count: days)
        
        for event in events {
            let eventDate = event.date
            if eventDate >= startDate && eventDate <= endDate {
                let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: eventDate).day ?? 0
                if daysSinceStart >= 0 && daysSinceStart < days {
                    dailyCounts[daysSinceStart] += 1
                }
            }
        }
        
        return dailyCounts
    }
    
    /// Calculates weekday vs weekend distribution.
    /// - Parameter events: Array of events with timestamps
    /// - Returns: Tuple with weekday and weekend counts
    public static func weekdayWeekendDistribution<T: DateProvider>(events: [T]) -> (weekday: Int, weekend: Int) {
        let calendar = Calendar.current
        var weekdayCount = 0
        var weekendCount = 0
        
        for event in events {
            let weekday = calendar.component(.weekday, from: event.date)
            if weekday == 1 || weekday == 7 { // Sunday or Saturday
                weekendCount += 1
            } else {
                weekdayCount += 1
            }
        }
        
        return (weekday: weekdayCount, weekend: weekendCount)
    }
    
    /// Calculates typical wait time while bridge is open.
    /// - Parameter durations: Array of bridge opening durations in minutes
    /// - Returns: Typical wait time with confidence interval
    public static func typicalWaitTime(durations: [Double]) -> (typical: Double, confidenceInterval: (lower: Double, upper: Double)?) {
        guard let median = median(durations) else {
            return (typical: 0, confidenceInterval: nil)
        }
        
        let confidenceInterval = confidenceInterval(values: durations)
        return (typical: median, confidenceInterval: confidenceInterval)
    }
    
    // MARK: - Data-Driven Thresholds
    
    /// Computes data-driven thresholds based on percentiles for frequency labeling.
    /// Uses 25th, 50th, and 75th percentiles to create adaptive thresholds.
    /// - Parameter values: Array of values to compute thresholds from
    /// - Returns: Tuple of (rare, sometimes, often) thresholds, or nil if insufficient data
    public static func computeDataDrivenThresholds(from values: [Double]) -> (rare: Double, sometimes: Double, often: Double)? {
        guard values.count >= 4 else { return nil } // Need at least 4 values for meaningful percentiles
        
        guard let p25 = percentile(values, 0.25),
              let p50 = percentile(values, 0.50),
              let p75 = percentile(values, 0.75) else {
            return nil
        }
        
        // Use percentiles to create adaptive thresholds
        let rare = p25
        let sometimes = p50
        let often = p75
        
        return (rare: rare, sometimes: sometimes, often: often)
    }
    
    /// Computes seasonal thresholds by grouping data by time periods.
    /// - Parameters:
    ///   - values: Array of values
    ///   - timestamps: Corresponding timestamps for each value
    ///   - seasonType: Type of seasonality (monthly, weekly, daily)
    /// - Returns: Dictionary mapping season to thresholds, or nil if insufficient data
    public static func computeSeasonalThresholds(
        values: [Double], 
        timestamps: [Date], 
        seasonType: SeasonType
    ) -> [String: (rare: Double, sometimes: Double, often: Double)]? {
        guard values.count == timestamps.count, values.count >= 8 else { return nil }
        
        var seasonalData: [String: [Double]] = [:]
        
        for (index, value) in values.enumerated() {
            let timestamp = timestamps[index]
            let season = seasonType.seasonKey(from: timestamp)
            
            if seasonalData[season] == nil {
                seasonalData[season] = []
            }
            seasonalData[season]?.append(value)
        }
        
        var seasonalThresholds: [String: (rare: Double, sometimes: Double, often: Double)] = [:]
        
        for (season, seasonValues) in seasonalData {
            if let thresholds = computeDataDrivenThresholds(from: seasonValues) {
                seasonalThresholds[season] = thresholds
            }
        }
        
        return seasonalThresholds.isEmpty ? nil : seasonalThresholds
    }
    
    /// SeasonType enum for defining different types of seasonality
    public enum SeasonType {
        case monthly
        case weekly
        case daily
        
        func seasonKey(from date: Date) -> String {
            let calendar = Calendar.current
            switch self {
            case .monthly:
                let month = calendar.component(.month, from: date)
                let year = calendar.component(.year, from: date)
                return "\(year)-\(String(format: "%02d", month))"
            case .weekly:
                let weekOfYear = calendar.component(.weekOfYear, from: date)
                let year = calendar.component(.year, from: date)
                return "\(year)-W\(String(format: "%02d", weekOfYear))"
            case .daily:
                let weekday = calendar.component(.weekday, from: date)
                return "\(weekday)" // 1 = Sunday, 2 = Monday, etc.
            }
        }
    }
    
    /// Computes confidence intervals for statistical estimates.
    /// - Parameters:
    ///   - values: Array of values
    ///   - confidenceLevel: Confidence level (0.95 for 95% confidence)
    /// - Returns: Confidence interval tuple (lower, upper), or nil if insufficient data
    public static func confidenceInterval(
        values: [Double], 
        confidenceLevel: Double = 0.95
    ) -> (lower: Double, upper: Double)? {
        guard values.count >= 2,
              let mean = mean(values),
              let std = unbiasedStd(values) else {
            return nil
        }
        
        // For small samples, use t-distribution; for large samples, use normal distribution
        let criticalValue: Double
        if values.count < 30 {
            // Simplified t-distribution approximation for small samples
            criticalValue = 2.0 // Conservative estimate for 95% confidence
        } else {
            // Normal distribution approximation for large samples
            criticalValue = 1.96 // 95% confidence level
        }
        
        let marginOfError = criticalValue * std / sqrt(Double(values.count))
        let lower = mean - marginOfError
        let upper = mean + marginOfError
        
        return (lower: lower, upper: upper)
    }
    
    /// Detects outliers using the Interquartile Range (IQR) method.
    /// - Parameters:
    ///   - values: Array of values
    ///   - multiplier: IQR multiplier (default 1.5 for standard outlier detection)
    /// - Returns: Array of outlier indices, or nil if insufficient data
    public static func detectOutliers(
        values: [Double], 
        multiplier: Double = 1.5
    ) -> [Int]? {
        guard values.count >= 4,
              let q1 = percentile(values, 0.25),
              let q3 = percentile(values, 0.75) else {
            return nil
        }
        
        let iqr = q3 - q1
        let lowerBound = q1 - (multiplier * iqr)
        let upperBound = q3 + (multiplier * iqr)
        
        var outlierIndices: [Int] = []
        for (index, value) in values.enumerated() {
            if value < lowerBound || value > upperBound {
                outlierIndices.append(index)
            }
        }
        
        return outlierIndices.isEmpty ? nil : outlierIndices
    }
}

/// Provides user-facing, statistically robust cascade strength statistics for a given set of strengths and time window.
public struct CascadeStatisticsService {
    public struct Result {
        public let mean: Double?
        public let median: Double?
        public let std: Double?
        public let count: Int
        public let p25: Double?
        public let p75: Double?
        public let rangeString: String?
        public let frequencyLabel: String
        public let timeWindowString: String
        public let detailedTimeWindowString: String
        public let confidenceInterval: (lower: Double, upper: Double)?
        public let outliers: [Int]?
        public let dataDrivenThresholds: (rare: Double, sometimes: Double, often: Double)?
        public let sparklineData: [Int]
        public let weekdayWeekendDistribution: (weekday: Int, weekend: Int)
        public let typicalWaitTime: (typical: Double, confidenceInterval: (lower: Double, upper: Double)?)
    }

    /// Computes all user-facing cascade strength stats for a given array of strengths and time window (in days).
    /// Now includes data-driven thresholds, confidence intervals, outlier detection, and enhanced features.
    /// - Parameters:
    ///   - strengths: Array of cascadeStrength values (0...1)
    ///   - timeWindowDays: Number of days in the window (for labeling)
    ///   - events: Array of events for sparkline and distribution analysis
    ///   - durations: Array of durations for wait time analysis
    ///   - useDataDrivenThresholds: If true, compute thresholds from data; otherwise use defaults
    ///   - defaultThresholds: Default thresholds if data-driven computation fails (default: 0.2, 0.5, 0.8)
    /// - Returns: Result struct with all user-facing stats
    public static func compute<T: DateProvider>(
        strengths: [Double], 
        timeWindowDays: Int,
        events: [T] = [],
        durations: [Double] = [],
        useDataDrivenThresholds: Bool = true,
        defaultThresholds: (rare: Double, sometimes: Double, often: Double) = (0.2, 0.5, 0.8)
    ) -> Result {
        let mean = StatisticsAPI.mean(strengths)
        let median = StatisticsAPI.median(strengths)
        let std = StatisticsAPI.unbiasedStd(strengths)
        let count = strengths.count
        let p25 = StatisticsAPI.percentile(strengths, 0.25)
        let p75 = StatisticsAPI.percentile(strengths, 0.75)
        let rangeString = (p25 != nil && p75 != nil) ? StatisticsAPI.rangeString(p25: p25!, p75: p75!, unit: "") : nil
        
        // Compute data-driven thresholds if requested and sufficient data
        let dataDrivenThresholds = useDataDrivenThresholds ? StatisticsAPI.computeDataDrivenThresholds(from: strengths) : nil
        let thresholds = dataDrivenThresholds ?? defaultThresholds
        
        // Use mean for frequency label, or 0 if no data
        let freqValue = mean ?? 0.0
        let frequencyLabel = StatisticsAPI.frequencyLabel(value: freqValue, thresholds: thresholds)
        let timeWindowString = StatisticsAPI.timeWindowString(days: timeWindowDays)
        let detailedTimeWindowString = StatisticsAPI.detailedTimeWindowString(days: timeWindowDays)
        
        // Compute confidence interval and outliers
        let confidenceInterval = StatisticsAPI.confidenceInterval(values: strengths)
        let outliers = StatisticsAPI.detectOutliers(values: strengths)
        
        // Generate enhanced features
        let sparklineData = StatisticsAPI.generateSparklineData(events: events, days: timeWindowDays)
        let weekdayWeekendDistribution = StatisticsAPI.weekdayWeekendDistribution(events: events)
        let typicalWaitTime = StatisticsAPI.typicalWaitTime(durations: durations)
        
        return Result(
            mean: mean, 
            median: median, 
            std: std, 
            count: count, 
            p25: p25, 
            p75: p75, 
            rangeString: rangeString, 
            frequencyLabel: frequencyLabel, 
            timeWindowString: timeWindowString,
            detailedTimeWindowString: detailedTimeWindowString,
            confidenceInterval: confidenceInterval,
            outliers: outliers,
            dataDrivenThresholds: dataDrivenThresholds,
            sparklineData: sparklineData,
            weekdayWeekendDistribution: weekdayWeekendDistribution,
            typicalWaitTime: typicalWaitTime
        )
    }
}
