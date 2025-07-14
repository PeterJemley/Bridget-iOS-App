import SwiftUI
import SwiftData
import BridgetCore

struct TrafficFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrafficFlow.timestamp, order: .reverse) private var trafficFlows: [TrafficFlow]
    @State private var showingAddTraffic = false
    
    var body: some View {
        NavigationView {
            List {
                if trafficFlows.isEmpty {
                    ContentUnavailableView(
                        "No Traffic Data",
                        systemImage: "car.fill",
                        description: Text("Add some traffic flow data to get started")
                    )
                } else {
                    ForEach(trafficFlows) { flow in
                        TrafficFlowRowView(flow: flow)
                    }
                    .onDelete(perform: deleteTrafficFlows)
                }
            }
            .navigationTitle("Traffic Flow")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddTraffic = true
                    }
                }
            }
            .sheet(isPresented: $showingAddTraffic) {
                AddTrafficFlowView()
            }
        }
    }
    
    private func deleteTrafficFlows(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(trafficFlows[index])
            }
        }
    }
}

struct TrafficFlowRowView: View {
    let flow: TrafficFlow
    
    var congestionColor: Color {
        switch flow.congestionLevel {
        case 0.0..<0.3:
            return .green
        case 0.3..<0.7:
            return .orange
        default:
            return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Bridge: \(flow.bridgeID)")
                    .font(.headline)
                
                Spacer()
                
                Text(flow.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Congestion:")
                            .font(.caption)
                        
                        Text("\(flow.congestionLevel, specifier: "%.1f")")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(congestionColor.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Text("Volume:")
                            .font(.caption)
                        
                        Text("\(flow.trafficVolume, specifier: "%.0f")")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Correlation:")
                        .font(.caption)
                    
                    Text("\(flow.correlationScore, specifier: "%.2f")")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct AddTrafficFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var bridgeID = ""
    @State private var timestamp = Date()
    @State private var congestionLevel = 0.5
    @State private var trafficVolume = 100.0
    @State private var correlationScore = 0.7
    
    var body: some View {
        NavigationView {
            Form {
                Section("Traffic Information") {
                    TextField("Bridge ID", text: $bridgeID)
                    
                    DatePicker("Timestamp", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Flow Metrics") {
                    VStack(alignment: .leading) {
                        Text("Congestion Level: \(congestionLevel, specifier: "%.1f")")
                            .font(.caption)
                        
                        Slider(value: $congestionLevel, in: 0...1, step: 0.1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Traffic Volume: \(trafficVolume, specifier: "%.0f")")
                            .font(.caption)
                        
                        Slider(value: $trafficVolume, in: 0...1000, step: 10)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Correlation Score: \(correlationScore, specifier: "%.2f")")
                            .font(.caption)
                        
                        Slider(value: $correlationScore, in: 0...1, step: 0.01)
                    }
                }
            }
            .navigationTitle("Add Traffic Flow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTrafficFlow()
                    }
                    .disabled(bridgeID.isEmpty)
                }
            }
        }
    }
    
    private func addTrafficFlow() {
        let flow = TrafficFlow(
            bridgeID: bridgeID,
            timestamp: timestamp,
            congestionLevel: congestionLevel,
            trafficVolume: trafficVolume,
            correlationScore: correlationScore
        )
        
        modelContext.insert(flow)
        dismiss()
    }
}

#Preview {
    TrafficFlowView()
        .modelContainer(for: [TrafficFlow.self], inMemory: true)
} 