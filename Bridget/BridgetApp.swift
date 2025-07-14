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
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            DrawbridgeEvent.self,
            DrawbridgeInfo.self,
            TrafficFlow.self,
            Route.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(apiService)
        }
        .modelContainer(sharedModelContainer)
    }
}
