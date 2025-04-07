//  MainView.swift
//  RANA
//
//  Created by Derek Monturo on 4/6/25.
//

import SwiftUI
import CoreLocation
import UIKit
import MapKit

struct MainView: View {
    // @StateObject manages the lifecycle of the managers
    @StateObject private var locationManager = LocationManager()
    @StateObject private var addressSearchService = AddressSearchService()
    
    // @State properties trigger view updates when changed
    @State private var sourceAddress: String = ""
    @State private var destinations: [String] = [""] // Start with one empty destination
    @State private var showSourceSuggestions: Bool = false
    @State private var showDestinationSuggestions: [Bool] = [false] // Track for each destination
    
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
                        .onChange(of: sourceAddress) { _, newValue in
                            addressSearchService.updateSourceQuery(newValue)
                            showSourceSuggestions = !newValue.isEmpty
                            
                            // Hide destination suggestions when typing in source
                            for index in 0..<showDestinationSuggestions.count {
                                showDestinationSuggestions[index] = false
                            }
                        }
                    
                    // Source address suggestions
                    if showSourceSuggestions && !addressSearchService.sourceSearchResults.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(addressSearchService.sourceSearchResults, id: \.self) { result in
                                    Button(action: {
                                        // Set the selected address with full details
                                        sourceAddress = addressSearchService.getFormattedAddress(from: result)
                                        showSourceSuggestions = false
                                    }) {
                                        VStack(alignment: .leading) {
                                            Text(result.title)
                                                .font(.headline)
                                            if !result.subtitle.isEmpty {
                                                Text(result.subtitle)
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 5)
                                    .foregroundColor(.primary)
                                    
                                    if result != addressSearchService.sourceSearchResults.last {
                                        Divider()
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                        .frame(height: min(CGFloat(addressSearchService.sourceSearchResults.count * 60), 250))
                    }
                    
                    // Current Location Button with loading indicator
                    Button(action: {
                        // Clear the source address first to ensure UI updates
                        sourceAddress = ""
                        showSourceSuggestions = false
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
                        VStack(alignment: .leading) {
                            HStack {
                                // Destination address input field
                                TextField("Enter destination address", text: $destinations[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocorrectionDisabled(true)
                                    .onChange(of: destinations[index]) { _, newValue in
                                        // Ensure array has enough elements
                                        while showDestinationSuggestions.count <= index {
                                            showDestinationSuggestions.append(false)
                                        }
                                        
                                        addressSearchService.updateDestinationQuery(newValue, index: index)
                                        showDestinationSuggestions[index] = !newValue.isEmpty
                                        
                                        // Hide source suggestions when typing in destination
                                        showSourceSuggestions = false
                                        
                                        // Hide other destination suggestions
                                        for i in 0..<showDestinationSuggestions.count where i != index {
                                            showDestinationSuggestions[i] = false
                                        }
                                    }
                                
                                // Delete button (X) - removes this destination
                                Button(action: {
                                    if destinations.count > 1 {
                                        destinations.remove(at: index)
                                        showDestinationSuggestions.remove(at: index)
                                    }
                                    showAlert("Delete button clicked for destination \(index + 1)")
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // Destination suggestions
                            if index < showDestinationSuggestions.count &&
                               showDestinationSuggestions[index] &&
                               !addressSearchService.destinationSearchResults.isEmpty &&
                               addressSearchService.activeDestinationIndex == index {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 10) {
                                        ForEach(addressSearchService.destinationSearchResults, id: \.self) { result in
                                            Button(action: {
                                                // Set the selected address with full details
                                                destinations[index] = addressSearchService.getFormattedAddress(from: result)
                                                showDestinationSuggestions[index] = false
                                            }) {
                                                VStack(alignment: .leading) {
                                                    Text(result.title)
                                                        .font(.headline)
                                                    if !result.subtitle.isEmpty {
                                                        Text(result.subtitle)
                                                            .font(.subheadline)
                                                            .foregroundColor(.gray)
                                                    }
                                                }
                                            }
                                            .padding(.vertical, 5)
                                            .foregroundColor(.primary)
                                            
                                            if result != addressSearchService.destinationSearchResults.last {
                                                Divider()
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                }
                                .frame(height: min(CGFloat(addressSearchService.destinationSearchResults.count * 60), 250))
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Add destination button (+) - adds a new empty destination
                    Button(action: {
                        destinations.append("")
                        showDestinationSuggestions.append(false)
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
        .onTapGesture {
            // Hide all suggestions when tapping outside
            showSourceSuggestions = false
            for index in 0..<showDestinationSuggestions.count {
                showDestinationSuggestions[index] = false
            }
        }
        
        // View lifecycle - request location when view appears
        .onAppear {
            locationManager.requestLocation()
        }
        
        // React to changes in location data
        // Updates the source address field when location is determined
        .onChange(of: locationManager.currentAddress) { _, newAddress in
            sourceAddress = newAddress
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
