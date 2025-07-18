import SwiftUI
import SwiftData
import BridgetCore
import BridgetSharedUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var apiService: OpenSeattleAPIService
    @State private var showingDeleteAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    Section("Data Management") {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Last Updated")
                                    .font(.headline)
                                if let lastFetch = apiService.lastFetchDate {
                                    Text(Self.formattedDate(lastFetch))
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
                                Text("Delete and Refresh All Bridge Data")
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
                        VStack(alignment: .center, spacing: 16) {
                            // App Name with Laurel Decorations
                            HStack(spacing: 8) {
                                Image(systemName: "laurel.leading")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                
                                Text("Bridget")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Image(systemName: "laurel.trailing")
                                    .foregroundColor(.green)
                                    .font(.title2)
                            }
                            
                            // Catchphrase
                            Text("Ditch the spanxiety: Bridge the gap between *you* and on time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .italic()
                            
                            // Seattle Open Data API Link
                            Link(destination: URL(string: "https://data.seattle.gov/Transportation/Drawbridge-Openings/3h5e-q24y")!) {
                                HStack {
                                    Image(systemName: "info.circle")
                                    Text("Seattle Open Data API")
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
                if apiService.isLoading {
                    LoadingOverlayView(label: "Loading bridge data…")
                        .zIndex(1)
                }
            }
            .navigationTitle("Settings")
            .alert("Delete and Refresh All Bridge Data", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllBridgeData()
                }
            } message: {
                Text("This will permanently delete all bridge and event data, then immediately refresh from the API. This action cannot be undone.")
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
                    await apiService.fetchAndStoreAllData(modelContext: modelContext)
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

    private static func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 
