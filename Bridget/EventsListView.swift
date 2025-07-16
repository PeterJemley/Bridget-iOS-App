import SwiftUI
import SwiftData
import BridgetCore
import BridgetSharedUI

struct EventsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DrawbridgeEvent.openDateTime, order: .reverse) private var events: [DrawbridgeEvent]
    @EnvironmentObject private var apiService: OpenSeattleAPIService
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    if events.isEmpty {
                        ContentUnavailableView(
                            "No Events",
                            systemImage: "clock.fill",
                            description: Text("No event data available.")
                        )
                    } else {
                        ForEach(events) { event in
                            EventRowView(event: event)
                        }
                    }
                }
                if apiService.isLoading && events.isEmpty {
                    LoadingOverlayView(label: "Loading event data…")
                        .zIndex(1)
                }
            }
            .navigationTitle("Bridge Events")
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .task {
                if events.isEmpty {
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
}

struct EventRowView: View {
    let event: DrawbridgeEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Bridge is non-optional in our domain model, so we can access it directly
            Text("Bridge Name: \(event.bridge.entityName)")
                .font(.headline)
            Text("Bridge ID: \(event.entityID)")
                .font(.caption)
            Text("Opened: \(event.openDateTime, style: .time)")
                .font(.caption)
            if let close = event.closeDateTime {
                Text("Closed: \(close, style: .time)")
                    .font(.caption)
            }
            Text("Open Duration: \(event.minutesOpen, specifier: "%.1f") min")
                .font(.caption)
            Text("Date: \(event.openDateTime, style: .date)")
                .font(.caption)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    EventsListView()
        .modelContainer(for: [DrawbridgeEvent.self, DrawbridgeInfo.self], inMemory: true)
} 