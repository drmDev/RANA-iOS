import SwiftUI
import MapKit
import CoreLocation

struct RouteResultsView: View {
    @State private var optimizedRoute: OptimizedRoute
    @Binding var isPresented: Bool
    @State private var showFullMap: Bool = false
    @State private var isEditingRoute: Bool = false
    
    init(optimizedRoute: OptimizedRoute, isPresented: Binding<Bool>) {
        _optimizedRoute = State(initialValue: optimizedRoute)
        _isPresented = isPresented
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    mapPreviewSection
                    buttonRow
                    routeSummarySection
                    routeDetailsSection
                    navigationButtonsSection
                }
            }
            .navigationTitle("Optimized Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showFullMap) {
                FullMapView(optimizedRoute: optimizedRoute)
            }
        }
    }
    
    // MARK: - View Components
    
    private var mapPreviewSection: some View {
        RouteMapView(
            startLocation: optimizedRoute.startLocation,
            destinations: optimizedRoute.destinations
        )
        .frame(height: 200)
        .cornerRadius(12)
        .padding(.horizontal)
        .shadow(radius: 3)
    }
    
    private var buttonRow: some View {
        HStack(spacing: 12) {
            // Show Full Map button
            Button(action: {
                showFullMap = true
            }) {
                HStack {
                    Image(systemName: "map.fill")
                    Text("Full Map")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
            
            // Edit Route button
            Button(action: {
                isEditingRoute.toggle()
            }) {
                HStack {
                    Image(systemName: isEditingRoute ? "checkmark" : "pencil")
                    Text(isEditingRoute ? "Done" : "Edit Route")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isEditingRoute ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                .foregroundColor(isEditingRoute ? .green : .orange)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
    
    private var routeSummarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Route Summary")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Distance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(optimizedRoute.formattedDistance())
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Estimated Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(optimizedRoute.formattedTime())
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .padding(.horizontal)
    }
    
    private var routeDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Details")
                .font(.headline)
                .padding(.horizontal)
            
            startingPointView
            
            // Use onAppear for debug printing instead of direct print statements
            if isEditingRoute {
                if optimizedRoute.destinations.isEmpty {
                    Text("No destinations to reorder")
                        .italic()
                        .foregroundColor(.secondary)
                        .padding()
                        .onAppear {
                            print("DEBUG: No destinations to reorder")
                        }
                } else {
                    ReorderableDestinationList(
                        destinations: optimizedRoute.destinations,
                        onReorder: reorderDestinations
                    )
                    .onAppear {
                        print("DEBUG: Showing reorderable list with \(optimizedRoute.destinations.count) destinations")
                        print("DEBUG: Edit mode: \(isEditingRoute)")
                    }
                }
            } else {
                destinationsListView
                    .onAppear {
                        print("DEBUG: Showing static destination list with \(optimizedRoute.destinations.count) destinations")
                    }
            }
        }
        .padding(.vertical)
        .onAppear {
            print("DEBUG: Route details section appeared. Destinations count: \(optimizedRoute.destinations.count)")
        }
    }
    
    private var startingPointView: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                
                Text("S")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Starting Point")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(optimizedRoute.startLocation.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var destinationsListView: some View {
        ForEach(0..<optimizedRoute.destinations.count, id: \.self) { index in
            destinationView(for: index)
            
            if index < optimizedRoute.destinations.count - 1 {
                destinationSeparator(fromIndex: index)
            }
        }
    }
    
    private func destinationView(for index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 24, height: 24)
                
                Text("\(index + 1)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Stop \(index + 1)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(optimizedRoute.destinations[index].address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private func destinationSeparator(fromIndex index: Int) -> some View {
        HStack {
            Spacer()
                .frame(width: 24)
            
            VStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 2, height: 20)
                
                Text(formatDistance(
                    from: optimizedRoute.destinations[index].coordinate,
                    to: optimizedRoute.destinations[index + 1].coordinate
                ))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 2, height: 20)
            }
            
            Spacer()
        }
    }
    
    private var navigationButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                openInMaps()
            }) {
                HStack {
                    Image(systemName: "map.fill")
                    Text("Open in Maps")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Button(action: {
                shareRoute()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Route")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(10)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    
    private func reorderDestinations(fromIndices: IndexSet, toOffset: Int) {
        print("DEBUG: Before reordering - destinations count: \(optimizedRoute.destinations.count)")
        print("DEBUG: Reordering from indices \(fromIndices) to offset \(toOffset)")
        
        // Create a mutable copy of the route
        var mutableRoute = optimizedRoute
        
        // Perform the reordering
        mutableRoute.reorderDestinations(fromIndices: fromIndices, toOffset: toOffset)
        
        // Update the state
        optimizedRoute = mutableRoute
        
        print("DEBUG: After reordering - destinations count: \(optimizedRoute.destinations.count)")
    }
    
    private func formatDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> String {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        
        let distanceInMeters = fromLocation.distance(from: toLocation)
        
        if distanceInMeters < 1000 {
            return "\(Int(distanceInMeters))m"
        } else {
            let distanceInKm = distanceInMeters / 1000
            return String(format: "%.1f km", distanceInKm)
        }
    }
    
    private func openInMaps() {
        guard let firstDestination = optimizedRoute.destinations.first else { return }
        
        let placemark = MKPlacemark(coordinate: firstDestination.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "First Destination"
        
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]
        
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    private func shareRoute() {
        var routeText = "Optimized Route:\n\n"
        routeText += "Starting from: \(optimizedRoute.startLocation.address)\n\n"
        
        for (index, destination) in optimizedRoute.destinations.enumerated() {
            routeText += "Stop \(index + 1): \(destination.address)\n"
        }
        
        routeText += "\nTotal Distance: \(optimizedRoute.formattedDistance())\n"
        routeText += "Estimated Time: \(optimizedRoute.formattedTime())"
        
        let activityVC = UIActivityViewController(
            activityItems: [routeText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Views

struct FullMapView: View {
    let optimizedRoute: OptimizedRoute
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            RouteMapView(
                startLocation: optimizedRoute.startLocation,
                destinations: optimizedRoute.destinations
            )
            .edgesIgnoringSafeArea(.all)
            .navigationTitle("Route Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
