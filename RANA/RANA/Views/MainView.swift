//
//  MainView.swift
//  RANA
//
//  Created by Derek Monturo on 4/6/25.
//

import SwiftUI
import CoreLocation
import UIKit

struct MainView: View {
    // @StateObject manages the lifecycle of the LocationManager
    // This ensures it persists across view refreshes
    @StateObject private var locationManager = LocationManager()
    
    // @State properties trigger view updates when changed
    @State private var sourceAddress: String = ""
    @State private var destinations: [String] = [""] // Start with one empty destination
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Icon section
                if let iconImage = UIImage(named: "AppIcon60x60") ?? UIImage(named: "AppIcon") {
                    Image(uiImage: iconImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                }
                
                // Title section
                Text("RANA - Really Awesome Navigation App")
                    .font(.largeTitle)
                    .padding(.top, 4)
                                
                // Source Address Section
                VStack(alignment: .leading) {
                    Text("Starting Point")
                        .font(.headline)
                    
                    // Text field for manual address entry
                    TextField("Enter starting address", text: $sourceAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled(true)
                        .accessibilityIdentifier("sourceAddressField")
                    
                    // Current Location Button with loading indicator
                    Button(action: {
                        // Clear the source address first to ensure UI updates
                        sourceAddress = ""
                        // Then request a new location
                        locationManager.requestLocation()
                    }) {
                        HStack {
                            // Shows different text based on loading state
                            Text(locationManager.isUpdating ? "Updating..." : "Use Current Location")
                            
                            // Shows spinner while location is being fetched
                            if locationManager.isUpdating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.7)
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    .accessibilityIdentifier("currentLocationButton")
                    
                    // Display any location errors
                    if let error = locationManager.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                
                // Destinations Section
                VStack(alignment: .leading) {
                    Text("Destinations")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Dynamic list of destination fields
                    ForEach(destinations.indices, id: \.self) { index in
                        HStack {
                            // Destination address input field
                            TextField("Enter destination address", text: $destinations[index])
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocorrectionDisabled(true)
                            
                            // Delete button (X) - removes this destination
                            Button(action: {
                                if destinations.count > 1 {
                                    destinations.remove(at: index)
                                }
                                showAlert("Delete button clicked for destination \(index + 1)")
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Add destination button (+) - adds a new empty destination
                    Button(action: {
                        destinations.append("")
                        showAlert("Add destination button clicked")
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Destination")
                        }
                        .foregroundColor(.green)
                    }
                    .padding(.horizontal)
                }
                
                // Optimize Route Button - main action button
                Button(action: {
                    optimizeRoute()
                }) {
                    Text("Optimize Route")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            } // End of VStack
        } // End of ScrollView
        
        // View lifecycle - request location when view appears
        .onAppear {
            locationManager.requestLocation()
        }
        
        // React to changes in location data
        // Updates the source address field when location is determined
        .onChange(of: locationManager.currentAddress) {
            sourceAddress = locationManager.currentAddress
        }
    }
    
    // Helper function to show alerts
    // Currently just prints to console, but could be expanded to show UI alerts
    private func showAlert(_ message: String) {
        print(message) // For now, just printing to console
    }
    
    // Function to handle route optimization
    // Currently demonstrates collecting all addresses for processing
    // Will be expanded to integrate with routing algorithms
    private func optimizeRoute() {
        var routeMessage = "Current Addresses:\n\n"
        
        if sourceAddress.isEmpty && destinations.allSatisfy({ $0.isEmpty }) {
            routeMessage = "No addresses entered yet"
        } else {
            routeMessage += "Starting Point: \(sourceAddress)\n\n"
            for (index, destination) in destinations.enumerated() {
                routeMessage += "Destination \(index + 1): \(destination)\n"
            }
        }
        
        print(routeMessage) // For now, just printing to console
    }
}

// Preview provider for SwiftUI canvas
// Enables design-time preview in Xcode
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
