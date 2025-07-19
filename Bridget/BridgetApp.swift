//
//  BridgetApp.swift
//  Bridget
//
//  Created by Peter Jemley on 7/13/25.
//

import SwiftUI
import SwiftData
import BridgetCore

@main
struct BridgetApp: App {
    @StateObject private var apiService = OpenSeattleAPIService()
    @State private var hasCompletedLaunch = false
    
    // Performance measurement for app launch
    init() {
        PerformanceMeasurement.shared.startMeasurement("App Launch")
        PerformanceMeasurement.shared.logMemoryUsage("App Init")
    }
    
    var sharedModelContainer: ModelContainer = {
        PerformanceMeasurement.shared.startMeasurement("SwiftData Setup")
        
        let schema = Schema([
            Item.self,
            DrawbridgeEvent.self,
            DrawbridgeInfo.self,
            TrafficFlow.self,
            Route.self,
        ])
        
        // Use in-memory configuration for development to avoid persistent storage issues
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            PerformanceMeasurement.shared.endMeasurement("SwiftData Setup")
            PerformanceMeasurement.shared.logMemoryUsage("After SwiftData Setup")
            print("✅ SWIFTDATA: ModelContainer initialized successfully")
            return container
        } catch {
            PerformanceMeasurement.shared.endMeasurement("SwiftData Setup")
            print("❌ SWIFTDATA: Failed to create ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(apiService)
                .onAppear {
                    if !hasCompletedLaunch {
                        PerformanceMeasurement.shared.endMeasurement("App Launch")
                        PerformanceMeasurement.shared.logMemoryUsage("App Ready")
                        PerformanceMeasurement.shared.printSummary()
                        hasCompletedLaunch = true
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
