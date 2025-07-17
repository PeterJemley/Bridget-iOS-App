//
//  ContentView.swift
//  Bridget
//
//  Created by Peter Jemley on 7/13/25.
//

import SwiftUI
import BridgetCore

struct ContentView: View {
    var body: some View {
        TabView {
            BridgesListView()
                .tabItem {
                    Image(systemName: "puzzlepiece.fill")
                    Text("Bridges")
                }
            
            EventsListView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("Events")
                }
            
            TrafficFlowView()
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("Traffic")
                }
            
            RoutesView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Routes")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
            TestView()
                .tabItem {
                    Image(systemName: "testtube.2")
                    Text("Test")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, DrawbridgeEvent.self, DrawbridgeInfo.self, TrafficFlow.self, Route.self], inMemory: true)
}
