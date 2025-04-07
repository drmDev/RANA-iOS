//
//  MainViewModel.swift
//  RANA
//
//  Created by Derek Monturo on 4/7/25.
//

import Foundation
import Combine
import SwiftUI
import CoreLocation
import MapKit

class MainViewModel: ObservableObject {
    // Services
    private let locationManager = LocationManager()
    private let addressSearchService = AddressSearchService()
    private let routeOptimizationService = RouteOptimizationService()
    
    // Published properties for UI state
    @Published var sourceAddress: String = ""
    @Published var destinations: [String] = [""] // Start with one empty destination
    @Published var showSourceSuggestions: Bool = false
    @Published var showDestinationSuggestions: [Bool] = [false]
    @Published var isLoading: Bool = false
    @Published var optimizedRoute: OptimizedRoute?
    @Published var showingResults: Bool = false
    @Published var alertItem: AlertItem?
    
    // Passthrough properties from services
    var sourceSearchResults: [MKLocalSearchCompletion] { addressSearchService.sourceSearchResults }
    var destinationSearchResults: [MKLocalSearchCompletion] { addressSearchService.destinationSearchResults }
    var activeDestinationIndex: Int { addressSearchService.activeDestinationIndex }
    var isLocationUpdating: Bool { locationManager.isUpdating }
    var locationError: String? { locationManager.lastError }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Set up subscriptions to location manager
        locationManager.$currentAddress
            .filter { !$0.isEmpty }
            .assign(to: \.sourceAddress, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func updateSourceQuery(_ query: String) {
        addressSearchService.updateSourceQuery(query)
        showSourceSuggestions = !query.isEmpty
        
        // Hide destination suggestions
        for index in 0..<showDestinationSuggestions.count {
            showDestinationSuggestions[index] = false
        }
    }
    
    func updateDestinationQuery(_ query: String, index: Int) {
        // Ensure array has enough elements
        while showDestinationSuggestions.count <= index {
            showDestinationSuggestions.append(false)
        }
        
        addressSearchService.updateDestinationQuery(query, index: index)
        showDestinationSuggestions[index] = !query.isEmpty
        
        // Hide source suggestions
        showSourceSuggestions = false
        
        // Hide other destination suggestions
        for i in 0..<showDestinationSuggestions.count where i != index {
            showDestinationSuggestions[i] = false
        }
    }
    
    // Method to call when view appears
    func onViewAppear() {
        // Request location when view first appears
        locationManager.requestLocation()
    }
    
    func useCurrentLocation() {
        // Clear the source address first
        sourceAddress = ""
        showSourceSuggestions = false
        // Request location
        locationManager.requestLocation()
    }
    
    func selectSourceAddress(_ searchResult: MKLocalSearchCompletion) {
        sourceAddress = addressSearchService.getFormattedAddress(from: searchResult)
        showSourceSuggestions = false
    }
    
    func selectDestinationAddress(_ searchResult: MKLocalSearchCompletion, index: Int) {
        destinations[index] = addressSearchService.getFormattedAddress(from: searchResult)
        showDestinationSuggestions[index] = false
    }
    
    func addDestination() {
        destinations.append("")
        showDestinationSuggestions.append(false)
    }
    
    func removeDestination(at index: Int) {
        if destinations.count > 1 {
            destinations.remove(at: index)
            if index < showDestinationSuggestions.count {
                showDestinationSuggestions.remove(at: index)
            }
        }
    }
    
    func hideAllSuggestions() {
        showSourceSuggestions = false
        for index in 0..<showDestinationSuggestions.count {
            showDestinationSuggestions[index] = false
        }
    }
    
    func optimizeRoute() {
        // Validate basic requirements
        guard !sourceAddress.isEmpty, !destinations.isEmpty, !destinations[0].isEmpty else {
            alertItem = AlertItem(
                title: "Missing Information",
                message: "Please enter a starting point and at least one destination.",
                dismissButton: .default(Text("OK"))
            )
            return
        }
        
        // Start loading
        isLoading = true
        
        // Call service to optimize route
        routeOptimizationService.optimizeRoute(
            sourceAddress: sourceAddress,
            destinationAddresses: destinations.filter { !$0.isEmpty }
        ) { [weak self] result in
            guard let self = self else { return }
            
            // Always stop loading when done
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let route):
                    self.optimizedRoute = route
                    self.showingResults = true
                    
                case .failure(let error):
                    self.alertItem = AlertItem(
                        title: "Optimization Error",
                        message: error.localizedDescription,
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }
    
    func cancelOptimization() {
        routeOptimizationService.cancelOptimization()
        isLoading = false
    }
}

// Alert model for SwiftUI
struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let dismissButton: Alert.Button
}
