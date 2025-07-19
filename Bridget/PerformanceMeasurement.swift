import Foundation
import SwiftData
import BridgetCore

/**
 * Performance Measurement Utility
 * 
 * This utility provides comprehensive performance measurement capabilities for the Bridget app.
 * It tracks timing, memory usage, and provides detailed analysis for optimization efforts.
 * 
 * USAGE EXAMPLES:
 * 
 * 1. Basic Timing:
 *    PerformanceMeasurement.shared.startMeasurement("App Launch")
 *    // ... your code ...
 *    PerformanceMeasurement.shared.endMeasurement("App Launch")
 * 
 * 2. SwiftData Query Measurement:
 *    let bridges = try PerformanceMeasurement.shared.measureQuery("Bridge List") {
 *        try modelContext.fetch(FetchDescriptor<DrawbridgeInfo>())
 *    }
 * 
 * 3. Network Request Measurement:
 *    try await PerformanceMeasurement.shared.measureNetwork("API Fetch") {
 *        await apiService.fetchAndStoreAllData(modelContext: modelContext)
 *    }
 * 
 * 4. Memory Usage Tracking:
 *    PerformanceMeasurement.shared.logMemoryUsage("After data load")
 * 
 * 5. View Loading Measurement:
 *    PerformanceMeasurement.shared.measureViewLoad("BridgesListView") {
 *        // view loading code
 *    }
 * 
 * 6. Print Summary:
 *    PerformanceMeasurement.shared.printSummary()
 * 
 * PERFORMANCE TARGETS:
 * - App Launch: < 2.0s cold, < 1.0s warm, < 0.5s hot
 * - SwiftData: < 100ms bridge query, < 200ms event query, < 50MB memory
 * - Network: < 1.0s API response, > 80% cache hit ratio
 * - UI: > 55 FPS scrolling, < 30MB UI memory
 */
@MainActor
class PerformanceMeasurement {
    static let shared = PerformanceMeasurement()
    
    private var measurements: [String: [TimeInterval]] = [:]
    private var startTimes: [String: TimeInterval] = [:]
    
    private init() {}
    
    // MARK: - Timing Methods
    
    /// Start timing a performance measurement
    func startMeasurement(_ name: String) {
        startTimes[name] = CFAbsoluteTimeGetCurrent()
        print("[PERF] Started measurement: \(name)")
    }
    
    /// End timing a performance measurement and record the result
    func endMeasurement(_ name: String) {
        guard let startTime = startTimes[name] else {
            print("[PERF] ERROR: No start time found for measurement: \(name)")
            return
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        if measurements[name] == nil {
            measurements[name] = []
        }
        measurements[name]?.append(duration)
        
        startTimes.removeValue(forKey: name)
        
        print("[PERF] Completed '\(name)': \(String(format: "%.3f", duration * 1000))ms")
    }
    
    /// Get average time for a measurement
    func averageTime(for name: String) -> TimeInterval? {
        guard let times = measurements[name], !times.isEmpty else { return nil }
        return times.reduce(0, +) / Double(times.count)
    }
    
    /// Get all measurements for a specific name
    func allTimes(for name: String) -> [TimeInterval] {
        return measurements[name] ?? []
    }
    
    /// Clear all measurements
    func clearMeasurements() {
        measurements.removeAll()
        startTimes.removeAll()
        print("[PERF] Cleared all performance measurements")
    }
    
    /// Print summary of all measurements
    func printSummary() {
        print("\n[PERF] Performance Measurement Summary:")
        print("======================================")
        
        for (name, times) in measurements {
            let average = times.reduce(0, +) / Double(times.count)
            let min = times.min() ?? 0
            let max = times.max() ?? 0
            let count = times.count
            
            print("\(name):")
            print("  Count: \(count)")
            print("  Average: \(String(format: "%.3f", average * 1000))ms")
            print("  Min: \(String(format: "%.3f", min * 1000))ms")
            print("  Max: \(String(format: "%.3f", max * 1000))ms")
            print("")
        }
    }
}

// MARK: - SwiftData Performance Extensions

extension PerformanceMeasurement {
    
    /// Measure SwiftData query performance
    func measureQuery<T>(_ name: String, operation: () throws -> T) rethrows -> T {
        startMeasurement("Query: \(name)")
        defer { endMeasurement("Query: \(name)") }
        return try operation()
    }
    
    /// Measure SwiftData save performance
    func measureSave(_ name: String, operation: () throws -> Void) rethrows {
        startMeasurement("Save: \(name)")
        defer { endMeasurement("Save: \(name)") }
        try operation()
    }
    
    /// Measure relationship loading performance
    func measureRelationship<T>(_ name: String, operation: () throws -> T) rethrows -> T {
        startMeasurement("Relationship: \(name)")
        defer { endMeasurement("Relationship: \(name)") }
        return try operation()
    }
}

// MARK: - Network Performance Extensions

extension PerformanceMeasurement {
    
    /// Measure network request performance
    func measureNetwork(_ name: String, operation: () async throws -> Void) async rethrows {
        startMeasurement("Network: \(name)")
        defer { endMeasurement("Network: \(name)") }
        try await operation()
    }
    
    /// Measure data processing performance
    func measureProcessing<T>(_ name: String, operation: () throws -> T) rethrows -> T {
        startMeasurement("Processing: \(name)")
        defer { endMeasurement("Processing: \(name)") }
        return try operation()
    }
}

// MARK: - UI Performance Extensions

extension PerformanceMeasurement {
    
    /// Measure UI rendering performance
    func measureRendering(_ name: String, operation: () -> Void) {
        startMeasurement("Rendering: \(name)")
        defer { endMeasurement("Rendering: \(name)") }
        operation()
    }
    
    /// Measure view loading performance
    func measureViewLoad(_ name: String, operation: () -> Void) {
        startMeasurement("ViewLoad: \(name)")
        defer { endMeasurement("ViewLoad: \(name)") }
        operation()
    }
}

// MARK: - Memory Usage Tracking

extension PerformanceMeasurement {
    
    /// Get current memory usage in MB
    func currentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0
        } else {
            return 0.0
        }
    }
    
    /// Log current memory usage
    func logMemoryUsage(_ context: String = "") {
        let usage = currentMemoryUsage()
        print("[PERF] Memory usage\(context.isEmpty ? "" : " (\(context))"): \(String(format: "%.1f", usage))MB")
    }
}

// MARK: - Convenience Methods for Common Operations

extension PerformanceMeasurement {
    
    /// Measure app launch performance
    func measureAppLaunch() {
        startMeasurement("App Launch")
    }
    
    /// Measure bridge list loading
    func measureBridgeListLoad() {
        startMeasurement("Bridge List Load")
    }
    
    /// Measure event list loading
    func measureEventListLoad() {
        startMeasurement("Event List Load")
    }
    
    /// Measure API data fetch
    func measureAPIFetch() {
        startMeasurement("API Data Fetch")
    }
    
    /// Measure SwiftData container setup
    func measureSwiftDataSetup() {
        startMeasurement("SwiftData Setup")
    }
} 