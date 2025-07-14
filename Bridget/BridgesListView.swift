import SwiftUI
import SwiftData
import BridgetCore

struct BridgesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var bridges: [DrawbridgeInfo]
    @StateObject private var apiService = OpenSeattleAPIService()
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                if bridges.isEmpty {
                    ContentUnavailableView(
                        "No Bridges",
                        systemImage: "bridge.fill",
                        description: Text("No bridge data available. Pull to refresh.")
                    )
                } else {
                    ForEach(bridges) { bridge in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bridge Name: \(bridge.entityName)")
                                .font(.headline)
                            Text("Bridge ID: \(bridge.entityID)")
                                .font(.caption)
                            Text("Type: \(bridge.entityType)")
                                .font(.caption)
                            Text("Location: \(bridge.latitude), \(bridge.longitude)")
                                .font(.caption)
                            Text("Events: \(bridge.events.count)")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Bridges")
            .refreshable {
                await refreshData()
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .task {
                if bridges.isEmpty {
                    await loadInitialData()
                }
            }
        }
    }
    
    private func loadInitialData() async {
        do {
            try await apiService.fetchAndStoreAllData(modelContext: modelContext)
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
    
    private func refreshData() async {
        await loadInitialData()
    }
}

struct BridgeRowView: View {
    let bridge: DrawbridgeInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(bridge.entityName)
                .font(.headline)
            Text(bridge.entityID)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack {
                Text(bridge.entityType)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                Spacer()
                Text("\(bridge.latitude, specifier: "%.4f"), \(bridge.longitude, specifier: "%.4f")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    BridgesListView()
        .modelContainer(for: [DrawbridgeInfo.self], inMemory: true)
} 