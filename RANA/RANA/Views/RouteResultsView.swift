//
//  RouteResultsView.swift
//  RANA
//
//  Created by Derek Monturo on 4/7/25.
//

import SwiftUI
import CoreLocation

struct RouteResultsView: View {
    let optimizedRoute: OptimizedRoute
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                // Route summary header
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "map")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Optimized Route")
                            .font(.headline)
                        
                        Spacer()
                        
                        // Total stats
                        VStack(alignment: .trailing) {
                            Text(optimizedRoute.formattedDistance())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(optimizedRoute.formattedTime())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                
                // Route list
                List {
                    // Starting point
                    HStack(alignment: .top, spacing: 15) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 28, height: 28)
                            
                            Text("S")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Starting Point")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(optimizedRoute.startLocation.address)
                                .font(.body)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Destinations
                    ForEach(0..<optimizedRoute.destinations.count, id: \.self) { index in
                        HStack(alignment: .top, spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 28, height: 28)
                                
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                if index == 0 {
                                    Text("First Stop")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if index == optimizedRoute.destinations.count - 1 {
                                    Text("Final Destination")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Stop \(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(optimizedRoute.destinations[index].address)
                                    .font(.body)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: {
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Edit Route")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // We'll implement this in the next step
                        openInMaps()
                    }) {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("Open in Maps")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationBarTitle("Route Results", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
    
    func openInMaps() {
        // We'll implement this in the next step
        print("Open in Maps tapped")
    }
}

struct RouteResultsView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample route for preview
        let start = Location(address: "1 Infinite Loop, Cupertino, CA", 
                            coordinate: CLLocationCoordinate2D(latitude: 37.3346, longitude: -122.0090))
        
        let destinations = [
            Location(address: "1600 Amphitheatre Parkway, Mountain View, CA", 
                    coordinate: CLLocationCoordinate2D(latitude: 37.4220, longitude: -122.0841)),
            Location(address: "1 Hacker Way, Menlo Park, CA", 
                    coordinate: CLLocationCoordinate2D(latitude: 37.4852, longitude: -122.1484)),
            Location(address: "2800 Sand Hill Road, Menlo Park, CA", 
                    coordinate: CLLocationCoordinate2D(latitude: 37.4211, longitude: -122.2040))
        ]
        
        let route = OptimizedRoute(startLocation: start, destinations: destinations)
        
        return RouteResultsView(optimizedRoute: route, isPresented: .constant(true))
    }
}
