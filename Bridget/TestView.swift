//
//  TestView.swift
//  Bridget
//
//  Created by Peter Jemley on 7/16/25.
//

import SwiftUI
import SwiftData
import BridgetCore

struct TestView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var bridges: [DrawbridgeInfo]
    @EnvironmentObject private var apiService: OpenSeattleAPIService
    @State private var selectedBridge: DrawbridgeInfo?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if let bridge = selectedBridge {
                    BridgeDetailView(bridge: bridge)
                } else {
                    ContentUnavailableView(
                        "No Bridge Selected",
                        systemImage: "puzzlepiece.fill",
                        description: Text("Select a bridge to view test data.")
                    )
                }
                
                if bridges.isEmpty {
                    Button("Load Test Data") {
                        Task {
                            await loadInitialData()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                } else {
                    if selectedBridge == nil {
                        Button("Select First Bridge") {
                            selectedBridge = bridges.first
                        }
                        .buttonStyle(.bordered)
                        .padding()
                    }
                }
            }
            .navigationTitle("Test Bridge Data")
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .task {
                if bridges.isEmpty {
                    await loadInitialData()
                } else if selectedBridge == nil {
                    selectedBridge = bridges.first
                }
            }
        }
    }
    
    private func loadInitialData() async {
        do {
            try await apiService.fetchAndStoreAllData(modelContext: modelContext)
            if !bridges.isEmpty {
                selectedBridge = bridges.first
            }
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
}

struct BridgeDetailView: View {
    let bridge: DrawbridgeInfo
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List {
            Section("Bridge Info") {
                Text("Name: \(bridge.entityName)")
                Text("ID: \(bridge.entityID)")
                Text("Type: \(bridge.entityType)")
                Text("Events: \(bridge.events.count)")
            }
            
            Section("Events") {
                Button("Add Test Event") {
                    addTestEvent()
                }
                
                if bridge.events.isEmpty {
                    Text("No events")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(bridge.events.sorted(by: { $0.openDateTime > $1.openDateTime })) { event in
                        VStack(alignment: .leading) {
                            Text(event.openDateTime, style: .date)
                            Text(event.openDateTime, style: .time)
                        }
                    }
                    .onDelete { indexSet in
                        let sortedEvents = bridge.events.sorted(by: { $0.openDateTime > $1.openDateTime })
                        let eventsToDelete = indexSet.map { sortedEvents[$0] }
                        print("Deleting \(eventsToDelete.count) events")
                        for event in eventsToDelete {
                            modelContext.delete(event)
                        }
                        do {
                            try modelContext.save()
                            print("✅ Successfully saved after deletion")
                        } catch {
                            print("❌ Failed to save after deletion: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    private func deleteEvents(at offsets: IndexSet) {
        let eventsToDelete = offsets.map { bridge.events[$0] }
        for event in eventsToDelete {
            modelContext.delete(event)
        }
        try? modelContext.save()
    }
    
    private func addTestEvent() {
        let testEvent = DrawbridgeEvent(
            entityID: bridge.entityID,
            entityName: bridge.entityName,
            entityType: bridge.entityType,
            bridge: bridge,
            openDateTime: Date(),
            closeDateTime: Date().addingTimeInterval(1800),
            minutesOpen: 30,
            latitude: bridge.latitude,
            longitude: bridge.longitude
        )
        
        bridge.events.append(testEvent)
        do {
            try modelContext.save()
            print("✅ Successfully saved new test event")
        } catch {
            print("❌ Failed to save new event: \(error)")
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct TestEventRowView: View {
    let event: DrawbridgeEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(event.openDateTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(event.openDateTime, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let closeDateTime = event.closeDateTime {
                HStack {
                    Text("Closed:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(closeDateTime, style: .time)
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text(String(format: "%.1f", event.minutesOpen))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            } else {
                Text("Currently Open")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

#Preview {
    TestView()
        .modelContainer(for: [DrawbridgeInfo.self, DrawbridgeEvent.self], inMemory: true)
} 
