// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import SwiftData
import BridgetCore

// MARK: - History API

/// Advanced history interface for comprehensive data management and exploration
public struct HistoryAPI {
    
    /// Main history view with comprehensive data exploration
    public struct HistoryView: View {
        @Environment(\.modelContext) private var modelContext
        @Query private var events: [DrawbridgeEvent]
        @State private var selectedTimeFilter: TimeFilter = .all
        @State private var selectedBridge: String? = nil
        @State private var searchText = ""
        @State private var showingFilters = false
        
        public init() {}
        
        public var body: some View {
            NavigationStack {
                VStack(spacing: 0) {
                    // Filter Bar
                    FilterBar(
                        selectedTimeFilter: $selectedTimeFilter,
                        selectedBridge: $selectedBridge,
                        searchText: $searchText,
                        bridges: bridges
                    )
                    
                    // Timeline View
                    TimelineView(events: filteredEvents)
                }
                .navigationTitle("History")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Export") {
                            exportData()
                        }
                    }
                }
            }
        }
        
        private var bridges: [DrawbridgeInfo] {
            // Get unique bridges from events
            let bridgeIDs = Set(events.map { $0.entityID })
            return bridgeIDs.compactMap { bridgeID in
                events.first { $0.entityID == bridgeID }
            }.map { event in
                DrawbridgeInfo(
                    entityID: event.entityID,
                    entityName: event.entityName,
                    entityType: event.entityType,
                    latitude: event.latitude,
                    longitude: event.longitude
                )
            }
        }
        
        private var filteredEvents: [DrawbridgeEvent] {
            var filtered = events
            
            // Apply time filter
            if selectedTimeFilter != .all {
                let dateRange = selectedTimeFilter.dateRange
                filtered = filtered.filter { event in
                    event.openDateTime >= dateRange.from && event.openDateTime <= dateRange.to
                }
            }
            
            // Apply bridge filter
            if let selectedBridge = selectedBridge {
                filtered = filtered.filter { $0.entityID == selectedBridge }
            }
            
            // Apply search filter
            if !searchText.isEmpty {
                filtered = filtered.filter { event in
                    event.entityName.localizedCaseInsensitiveContains(searchText)
                }
            }
            
            return filtered.sorted { $0.openDateTime > $1.openDateTime }
        }
        
        private func exportData() {
            // Export filtered data
            let exportData = filteredEvents.map { event in
                [
                    "Bridge": event.entityName,
                    "Open Time": event.openDateTime.formatted(),
                    "Close Time": event.closeDateTime?.formatted() ?? "Still Open",
                    "Duration": "\(Int(event.minutesOpen)) minutes"
                ]
            }
            
            // Create CSV export
            let csvString = createCSV(from: exportData)
            
            // Share the CSV data
            let activityVC = UIActivityViewController(
                activityItems: [csvString],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityVC, animated: true)
            }
        }
        
        private func createCSV(from data: [[String: String]]) -> String {
            guard !data.isEmpty else { return "" }
            
            let headers = Array(data[0].keys)
            var csv = headers.joined(separator: ",") + "\n"
            
            for row in data {
                let values = headers.map { header in
                    row[header] ?? ""
                }
                csv += values.joined(separator: ",") + "\n"
            }
            
            return csv
        }
    }
    
    /// Time filter options for history data
    public enum TimeFilter: String, CaseIterable {
        case all = "All Time"
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case year = "This Year"
        case custom = "Custom Range"
        
        var dateRange: (from: Date, to: Date) {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .all:
                return (from: Date.distantPast, to: now)
            case .today:
                let startOfDay = calendar.startOfDay(for: now)
                return (from: startOfDay, to: now)
            case .week:
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
                return (from: startOfWeek, to: now)
            case .month:
                let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
                return (from: startOfMonth, to: now)
            case .year:
                let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
                return (from: startOfYear, to: now)
            case .custom:
                return (from: Date.distantPast, to: now)
            }
        }
    }
}

// MARK: - History Components

/// Filter bar for history view
struct FilterBar: View {
    @Binding var selectedTimeFilter: HistoryAPI.TimeFilter
    @Binding var selectedBridge: String?
    @Binding var searchText: String
    let bridges: [DrawbridgeInfo]
    
    var body: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search bridges...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Filter controls
            HStack {
                // Time filter
                Menu {
                    ForEach(HistoryAPI.TimeFilter.allCases, id: \.self) { filter in
                        Button(filter.rawValue) {
                            selectedTimeFilter = filter
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedTimeFilter.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
                
                // Bridge filter
                Menu {
                    Button("All Bridges") {
                        selectedBridge = nil
                    }
                    
                    ForEach(bridges, id: \.entityID) { bridge in
                        Button(bridge.entityName) {
                            selectedBridge = bridge.entityID
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedBridge == nil ? "All Bridges" : bridges.first { $0.entityID == selectedBridge }?.entityName ?? "Unknown")
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

/// Timeline view for historical events
struct TimelineView: View {
    let events: [DrawbridgeEvent]
    
    var body: some View {
        if events.isEmpty {
            EmptyStateView()
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(groupedEvents.keys.sorted(by: >), id: \.self) { date in
                        TimelineSection(date: date, events: groupedEvents[date] ?? [])
                    }
                }
                .padding()
            }
        }
    }
    
    private var groupedEvents: [Date: [DrawbridgeEvent]] {
        let calendar = Calendar.current
        var grouped: [Date: [DrawbridgeEvent]] = [:]
        
        for event in events {
            let dayStart = calendar.startOfDay(for: event.openDateTime)
            grouped[dayStart, default: []].append(event)
        }
        
        return grouped
    }
}

/// Timeline section for a specific date
struct TimelineSection: View {
    let date: Date
    let events: [DrawbridgeEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(date, style: .date)
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 8) {
                ForEach(events.sorted { $0.openDateTime > $1.openDateTime }) { event in
                    TimelineEventRow(event: event)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

/// Individual timeline event row
struct TimelineEventRow: View {
    let event: DrawbridgeEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(event.closeDateTime == nil ? Color.red : Color.blue)
                    .frame(width: 12, height: 12)
                
                if event.closeDateTime != nil {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
            }
            
            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.entityName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text(event.openDateTime, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let closeDateTime = event.closeDateTime {
                        Text("→")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(closeDateTime, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Duration
            if let closeDateTime = event.closeDateTime {
                Text("\(Int(event.minutesOpen)) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(4)
            } else {
                Text("Open")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Empty state view
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Events Found")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Try adjusting your filters or search terms")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
