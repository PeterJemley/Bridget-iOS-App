// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import SwiftData
import BridgetCore

// MARK: - Dashboard API

/// Advanced dashboard interface for bridge monitoring and analytics
public struct DashboardAPI {
    
    /// Main dashboard view with comprehensive bridge monitoring
    public struct DashboardView: View {
        @Environment(\.modelContext) private var modelContext
        @Query private var events: [DrawbridgeEvent]
        @Query private var bridges: [DrawbridgeInfo]
        @State private var selectedTimeFilter: TimeFilter = .today
        @State private var isLoading = false
        
        public init() {}
        
        public var body: some View {
            NavigationStack {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Bridge Status Overview
                        BridgeStatusOverview(bridges: bridges, events: events)
                        
                        // Recent Activity
                        RecentActivitySection(events: recentEvents)
                        
                        // Traffic Integration
                        TrafficIntegrationSection()
                        
                        // Analytics Insights
                        AnalyticsInsightsSection(events: events)
                    }
                    .padding()
                }
                .navigationTitle("Bridge Dashboard")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Refresh") {
                            Task {
                                await refreshData()
                            }
                        }
                        .disabled(isLoading)
                    }
                }
                .refreshable {
                    await refreshData()
                }
            }
        }
        
        private var recentEvents: [DrawbridgeEvent] {
            Array(events.prefix(10))
        }
        
        private func refreshData() async {
            // Runtime assertion to catch thread violations
            precondition(Thread.isMainThread, "refreshData must be called on main thread")
            
            isLoading = true
            defer { isLoading = false }
            
            // Refresh data from API
            do {
                let dataManager = DataManager(modelContext: modelContext)
                try await dataManager.refreshAllData(forceRefresh: true)
            } catch {
                print("📊 DASHBOARD: Failed to refresh data: \(error)")
            }
        }
    }
    
    /// Time filter options for dashboard data
    public enum TimeFilter: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case year = "This Year"
        
        var dateRange: (from: Date, to: Date) {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
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
            }
        }
    }
}

// MARK: - Dashboard Components

/// Bridge status overview component
struct BridgeStatusOverview: View {
    let bridges: [DrawbridgeInfo]
    let events: [DrawbridgeEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bridge Status")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(bridges) { bridge in
                    BridgeStatusCard(bridge: bridge, events: events)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

/// Individual bridge status card
struct BridgeStatusCard: View {
    let bridge: DrawbridgeInfo
    let events: [DrawbridgeEvent]
    
    private var isCurrentlyOpen: Bool {
        // Determine if bridge is currently open based on recent events
        let recentEvents = events.filter { $0.entityID == bridge.entityID }
        guard let lastEvent = recentEvents.first else { return false }
        
        // If the last event has no close time, it's still open
        return lastEvent.closeDateTime == nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(bridge.entityName)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
            
            HStack {
                Circle()
                    .fill(isCurrentlyOpen ? Color.red : Color.green)
                    .frame(width: 8, height: 8)
                
                Text(isCurrentlyOpen ? "Open" : "Closed")
                    .font(.caption)
                    .foregroundColor(isCurrentlyOpen ? .red : .green)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

/// Recent activity section
struct RecentActivitySection: View {
    let events: [DrawbridgeEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.primary)
            
            if events.isEmpty {
                Text("No recent bridge activity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(events.prefix(5)) { event in
                        ActivityRow(event: event)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

/// Individual activity row
struct ActivityRow: View {
    let event: DrawbridgeEvent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.entityName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Opened \(event.openDateTime, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let closeDateTime = event.closeDateTime {
                Text("\(Int(event.minutesOpen)) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Open")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Traffic integration section
struct TrafficIntegrationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Traffic Analysis")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Bridge status is inferred from Apple Maps traffic data")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "car.fill")
                    .foregroundColor(.blue)
                Text("Traffic data integration active")
                    .font(.caption)
                    .foregroundColor(.blue)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

/// Analytics insights section
struct AnalyticsInsightsSection: View {
    let events: [DrawbridgeEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analytics Insights")
                .font(.headline)
                .foregroundColor(.primary)
            
            if events.isEmpty {
                Text("No data available for analysis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    InsightRow(title: "Total Events", value: "\(events.count)")
                    InsightRow(title: "Active Bridges", value: "\(Set(events.map { $0.entityID }).count)")
                    InsightRow(title: "Average Duration", value: "\(Int(averageDuration)) min")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var averageDuration: Double {
        let completedEvents = events.filter { $0.closeDateTime != nil }
        guard !completedEvents.isEmpty else { return 0 }
        return completedEvents.reduce(0) { $0 + $1.minutesOpen } / Double(completedEvents.count)
    }
}

/// Individual insight row
struct InsightRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
