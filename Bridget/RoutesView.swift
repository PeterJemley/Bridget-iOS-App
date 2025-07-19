import SwiftUI
import SwiftData
import BridgetCore

struct RoutesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Route.createdAt, order: .reverse) private var routes: [Route]
    @State private var showingAddRoute = false
    
    var body: some View {
        NavigationView {
            List {
                if routes.isEmpty {
                    ContentUnavailableView(
                        "No Routes",
                        systemImage: "map.fill",
                        description: Text("Add some routes to get started")
                    )
                } else {
                    ForEach(routes) { route in
                        RouteRowView(route: route)
                    }
                    .onDelete(perform: deleteRoutes)
                }
            }
            .navigationTitle("Routes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddRoute = true
                    }
                }
            }
            .sheet(isPresented: $showingAddRoute) {
                AddRouteView()
            }
        }
    }
    
    private func deleteRoutes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(routes[index])
            }
        }
    }
}

struct RouteRowView: View {
    let route: Route
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(route.name)
                    .font(.headline)
                
                Spacer()
                
                Text(route.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("ID: \(route.id.uuidString)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Start: \(route.startLocation)")
                        .font(.caption)
                    
                    Text("End: \(route.endLocation)")
                        .font(.caption)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(route.bridges.count) bridges")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            if !route.bridges.isEmpty {
                Text("Bridges: \(route.bridges.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct AddRouteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var startLocation = ""
    @State private var endLocation = ""
    @State private var bridges = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Route Information") {
                    TextField("Route Name", text: $name)
                    TextField("Start Location", text: $startLocation)
                    TextField("End Location", text: $endLocation)
                }
                
                Section("Route Details") {
                    TextField("Bridges (comma-separated)", text: $bridges, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addRoute()
                    }
                    .disabled(name.isEmpty || startLocation.isEmpty || endLocation.isEmpty)
                }
            }
        }
    }
    
    private func addRoute() {
        let bridgeList = bridges.isEmpty ? [] : bridges.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        
        let route = Route(
            name: name,
            startLocation: startLocation,
            endLocation: endLocation,
            bridges: bridgeList
        )
        
        modelContext.insert(route)
        // Explicitly save after insert to ensure persistence (see documentation: SwiftUI context save semantics)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    RoutesView()
        // Use shared ModelContainer from BridgetApp
} 