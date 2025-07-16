import SwiftUI
import SwiftData
import BridgetCore

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var apiService: OpenSeattleAPIService
    @State private var showingDeleteAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @Query(sort: \DrawbridgeEvent.openDateTime, order: .reverse) private var events: [DrawbridgeEvent]
    
    var body: some View {
        NavigationView {
            List {
                Section("Data Management") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Last Updated")
                                .font(.headline)
                            if let lastFetch = apiService.lastFetchDate {
                                Text(lastFetch, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Never")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if apiService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    Button(action: { showingDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete All Bridge Data")
                        }
                        .foregroundColor(.red)
                    }
                    .disabled(apiService.isLoading)
                }
                
                Section("App Information") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("About") {
                    Text("Bridget helps you stay informed about Seattle's drawbridges and their operations.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Developer Info") {
                    if events.isEmpty {
                        Text("No drawbridge events in database.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(events) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Event ID: \(event.id.uuidString)")
                                    .font(.caption)
                                Text("Bridge ID: \(event.entityID)")
                                    .font(.caption)
                                Text("Bridge Name: \(event.entityName)")
                                    .font(.caption)
                                Text("Type: \(event.entityType)")
                                    .font(.caption)
                                Text("Latitude: \(event.latitude)")
                                    .font(.caption)
                                Text("Longitude: \(event.longitude)")
                                    .font(.caption)
                                Text("Open: \(event.openDateTime, style: .date) \(event.openDateTime, style: .time)")
                                    .font(.caption)
                                if let close = event.closeDateTime {
                                    Text("Close: \(close, style: .date) \(close, style: .time)")
                                        .font(.caption)
                                }
                                Text("Minutes Open: \(event.minutesOpen, specifier: "%.1f")")
                                    .font(.caption)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Delete All Bridge Data", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllBridgeData()
                }
            } message: {
                Text("This will permanently delete all bridge and event data. This action cannot be undone.")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func deleteAllBridgeData() {
        Task {
            do {
                // Step 1: Delete all bridge and event data
                try await deleteAllBridgeData()
                // Step 2: Check that the store is empty
                let eventCount = try modelContext.fetchCount(FetchDescriptor<DrawbridgeEvent>())
                let bridgeCount = try modelContext.fetchCount(FetchDescriptor<DrawbridgeInfo>())
                if eventCount == 0 && bridgeCount == 0 {
                    // Step 3: Refresh data from API if deletion succeeded
                    try await apiService.fetchAndStoreAllData(modelContext: modelContext)
                } else {
                    // Step 4: Show error if deletion did not fully succeed
                    errorMessage = "Failed to erase all bridge data. Please try again."
                    showingErrorAlert = true
                }
            } catch {
                // Handle any errors during deletion or refresh
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
        }
    }
    
    private func deleteAllBridgeData() async throws {
        // PHASE 0.2: Data Architecture & Models
        // Step 1: Delete all DrawbridgeEvent objects (child objects) first to maintain referential integrity.
        // This follows SwiftData best practices: child objects must be deleted before parents.
        let eventDescriptor = FetchDescriptor<DrawbridgeEvent>()
        let events = try modelContext.fetch(eventDescriptor)
        for event in events {
            modelContext.delete(event)
        }
        try modelContext.save() // Save after deleting events to commit removals.
        
        // Step 2: Delete all DrawbridgeInfo objects (parent objects) after all children are removed.
        let bridgeDescriptor = FetchDescriptor<DrawbridgeInfo>()
        let bridges = try modelContext.fetch(bridgeDescriptor)
        for bridge in bridges {
            modelContext.delete(bridge)
        }
        try modelContext.save() // Save after deleting bridges to finalize changes.
    }
} 
