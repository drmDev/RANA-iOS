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
    @State private var isLoading = false
    @State private var sourceAddress: String = ""
    @State private var destinations: [String] = [""] // Start with one empty destination
    @State private var showSourceSuggestions: Bool = false
    @State private var showDestinationSuggestions: [Bool] = [false] // Track for each destination
    @State private var optimizedRoute: OptimizedRoute?
    @State private var showingResults = false
    
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
                Button(action: optimizeRoute) {
                    Text("Optimize Route")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(sourceAddress.isEmpty || destinations.isEmpty || destinations[0].isEmpty)
                
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
        
        .sheet(isPresented: $showingResults) {
            if let route = optimizedRoute {
                RouteResultsView(optimizedRoute: route, isPresented: $showingResults)
            }
        }
        
        .overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.7)  // Darker background for better contrast
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                                .tint(Color.white)  // Ensure spinner is white
                            
                            Text("Optimizing route...")
                                .foregroundColor(.white)
                                .font(.headline)
                                .padding(.top, 8)
                        }
                        .padding(30)
                        .background(Color.blue.opacity(0.8))  // Blue background for the loading box
                        .cornerRadius(10)
                    }
                }
            }
        )
    }
    
    func optimizeRoute() {
        print("⏱️ Starting route optimization process")
        
        // Validate we have source and at least one destination
        guard !sourceAddress.isEmpty, !destinations.isEmpty, !destinations[0].isEmpty else {
            print("❌ Missing source or destination addresses")
            return
        }
        
        print("📍 Source: \(sourceAddress)")
        print("📍 Destinations: \(destinations.filter { !$0.isEmpty })")
        
        // Show loading indicator
        isLoading = true
        
        // Add timeout
        let timeoutSeconds: Double = 30
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutSeconds) {
            if self.isLoading {
                print("⚠️ TIMEOUT: Route optimization process took too long")
                self.isLoading = false
                self.showAlert(title: "Timeout Error",
                              message: "The route optimization process took too long. Please try again with fewer destinations or check your internet connection.")
            }
        }
        
        // SIMPLIFIED APPROACH: Process one address at a time
        geocodeAddressSequentially()
    }

    // New function to handle sequential geocoding
    func geocodeAddressSequentially() {
        var allLocations: [Location] = []
        var currentIndex = -1 // Start with -1 to represent source address
        let allAddresses = [sourceAddress] + destinations.filter { !$0.isEmpty }
        
        func processNextAddress() {
            currentIndex += 1
            
            // Check if we've processed all addresses
            if currentIndex >= allAddresses.count {
                print("✅ All addresses geocoded successfully")
                completeOptimization(locations: allLocations)
                return
            }
            
            let address = allAddresses[currentIndex]
            print("🔍 Geocoding address \(currentIndex): \(address)")
            
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let error = error {
                    print("❌ Error geocoding address \(currentIndex): \(error.localizedDescription)")
                    // Continue with next address instead of failing completely
                    DispatchQueue.main.async {
                        self.showAlert(title: "Geocoding Warning",
                                      message: "Couldn't find location for: \(address). Skipping this address.")
                        processNextAddress()
                    }
                    return
                }
                
                guard let placemark = placemarks?.first, let location = placemark.location else {
                    print("⚠️ No location found for address \(currentIndex)")
                    DispatchQueue.main.async {
                        processNextAddress()
                    }
                    return
                }
                
                let loc = Location(address: address, coordinate: location.coordinate)
                print("📌 Address \(currentIndex) geocoded: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                allLocations.append(loc)
                
                // Wait a moment before processing next address to avoid rate limiting
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    processNextAddress()
                }
            }
        }
        
        // Start the sequential processing
        processNextAddress()
    }

    // Function to complete the optimization once geocoding is done
    func completeOptimization(locations: [Location]) {
        guard locations.count >= 2 else {
            print("❌ Not enough valid locations to optimize")
            isLoading = false
            showAlert(title: "Error", message: "Need at least a source and one destination to optimize route.")
            return
        }
        
        let source = locations[0]
        let destinations = Array(locations.dropFirst())
        
        print("🧮 Starting route optimization with \(destinations.count) destinations")
        
        // Optimize route
        let optimizer = RouteOptimizer()
        let optimizedDestinations = optimizer.optimizeRoute(start: source, destinations: destinations)
        
        print("✅ Route optimization complete")
        print("📊 Optimized route: \(optimizedDestinations.map { $0.address })")
        
        // Create route object
        self.optimizedRoute = OptimizedRoute(
            startLocation: source,
            destinations: Array(optimizedDestinations.dropFirst())
        )
        
        print("🎯 Showing results view")
        self.isLoading = false
        self.showingResults = true
    }

    // Add this helper function for showing alerts
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // Get the current window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    // Helper function to show alerts
    // Currently just prints to console, but could be expanded to show UI alerts
    private func showAlert(_ message: String) {
        print(message) // For now, just printing to console
    }
}

// Preview provider for SwiftUI canvas
// Enables design-time preview in Xcode
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
