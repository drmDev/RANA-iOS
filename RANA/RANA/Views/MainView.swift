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
    @StateObject private var viewModel = MainViewModel()
    
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
                    TextField("Enter starting address", text: $viewModel.sourceAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled(true)
                        .accessibilityIdentifier("sourceAddressField")
                        .onChange(of: viewModel.sourceAddress) { _, newValue in
                            viewModel.updateSourceQuery(newValue)
                        }
                    
                    // Source address suggestions
                    if viewModel.showSourceSuggestions {
                        SuggestionsList(
                            results: viewModel.searchResults,
                            onSelect: { result in viewModel.selectSourceAddress(result) }
                        )
                    }
                    
                    // Current Location Button with loading indicator
                    Button(action: viewModel.useCurrentLocation) {
                        HStack {
                            // Shows different text based on loading state
                            Text(viewModel.isLocationUpdating ? "Updating..." : "Use Current Location")
                            
                            // Shows spinner while location is being fetched
                            if viewModel.isLocationUpdating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.7)
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    .accessibilityIdentifier("currentLocationButton")
                    
                    // Display any location errors
                    if let error = viewModel.locationError {
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
                    ForEach(viewModel.destinations.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            HStack {
                                // Destination address input field
                                TextField("Enter destination address", text: $viewModel.destinations[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocorrectionDisabled(true)
                                    .onChange(of: viewModel.destinations[index]) { _, newValue in
                                        viewModel.updateDestinationQuery(newValue, index: index)
                                    }
                                
                                // Delete button (X) - removes this destination
                                Button(action: {
                                    viewModel.removeDestination(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // Destination suggestions
                            if viewModel.showDestinationSuggestions(at: index) {
                                SuggestionsList(
                                    results: viewModel.searchResults,
                                    onSelect: { result in viewModel.selectDestinationAddress(result, index: index) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Add destination button (+) - adds a new empty destination
                    Button(action: viewModel.addDestination) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Destination")
                        }
                        .foregroundColor(.green)
                    }
                    .padding(.horizontal)
                }
                
                // Optimize Route Button - main action button
                Button(action: viewModel.optimizeRoute) {
                    Text("Optimize Route")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(viewModel.sourceAddress.isEmpty ||
                         viewModel.destinations.isEmpty ||
                         viewModel.destinations[0].isEmpty)
                
                Spacer()
            } // End of VStack
        } // End of ScrollView
        .onTapGesture {
            // Hide all suggestions when tapping outside
            viewModel.hideAllSuggestions()
        }
        
        // View lifecycle - request location when view appears
        .onAppear {
            viewModel.onViewAppear()
        }
        
        .sheet(isPresented: $viewModel.showingResults) {
            if let route = viewModel.optimizedRoute {
                RouteResultsView(optimizedRoute: route, isPresented: $viewModel.showingResults)
            }
        }
        
        .overlay(
            Group {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.7)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                                .tint(Color.white)
                            
                            Text("Optimizing route...")
                                .foregroundColor(.white)
                                .font(.headline)
                                .padding(.top, 8)
                        }
                        .padding(30)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(10)
                    }
                    .onTapGesture {
                        // Allow canceling by tapping
                        viewModel.cancelOptimization()
                    }
                }
            }
        )
        
        // Alert handling
        .alert(item: $viewModel.alertItem) { alertItem in
            Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                dismissButton: alertItem.dismissButton
            )
        }
    }
}

// Reusable component for displaying address suggestions
struct SuggestionsList: View {
    let results: [MKLocalSearchCompletion]
    let onSelect: (MKLocalSearchCompletion) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(results, id: \.self) { result in
                    Button(action: { onSelect(result) }) {
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
                    
                    if result != results.last {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 5)
        }
        .frame(height: min(CGFloat(results.count * 60), 250))
    }
}
