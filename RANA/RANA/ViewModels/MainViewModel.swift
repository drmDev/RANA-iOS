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
    private var locationManager: LocationManager
    private var addressSearchService: AddressSearchService
    private var routeOptimizationService: RouteOptimizationService
    private var cancellables = Set<AnyCancellable>()
    
    // Published properties for UI state
    @Published var sourceAddress: String = ""
    @Published var destinations: [String] = [""] // Start with one empty destination
    @Published var isLoading: Bool = false
    @Published var optimizedRoute: OptimizedRoute?
    @Published var showingResults: Bool = false
    @Published var alertItem: AlertItem?
    
    // Computed properties for UI state
    var showSourceSuggestions: Bool {
        if case .source = addressSearchService.activeSearchType, !addressSearchService.searchResults.isEmpty {
            return true
        }
        return false
    }
    
    func showDestinationSuggestions(at index: Int) -> Bool {
        if case .destination(let activeIndex) = addressSearchService.activeSearchType,
           activeIndex == index,
           !addressSearchService.searchResults.isEmpty {
            return true
        }
        return false
    }
    
    // Passthrough properties from services
    var searchResults: [MKLocalSearchCompletion] { addressSearchService.searchResults }
    var isLocationUpdating: Bool { locationManager.isUpdating }
    var locationError: String? { locationManager.lastError }
        
    // Replace the existing init() function with this one
    init(locationManager: LocationManager = LocationManager(),
         addressSearchService: AddressSearchService = AddressSearchService(),
         routeOptimizationService: RouteOptimizationService = RouteOptimizationService()) {
        self.locationManager = locationManager
        self.addressSearchService = addressSearchService
        self.routeOptimizationService = routeOptimizationService
        
        // Set up subscriptions to location manager
        self.locationManager.$currentAddress
            .filter { !$0.isEmpty }
            .assign(to: \.sourceAddress, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func updateSourceQuery(_ query: String) {
        addressSearchService.search(for: query, type: .source)
    }
    
    func updateDestinationQuery(_ query: String, index: Int) {
        addressSearchService.search(for: query, type: .destination(index: index))
    }
    
    // Method to call when view appears
    func onViewAppear() {
        // Request location when view first appears
        locationManager.requestLocation()
    }
    
    func useCurrentLocation() {
        // Clear the source address first
        sourceAddress = ""
        // Request location
        locationManager.requestLocation()
    }
    
    func selectSourceAddress(_ searchResult: MKLocalSearchCompletion) {
        sourceAddress = addressSearchService.getFormattedAddress(from: searchResult)
        // Explicitly clear active search to fix the double-tap issue
        addressSearchService.clearActiveSearch()
    }
    
    func selectDestinationAddress(_ searchResult: MKLocalSearchCompletion, index: Int) {
        destinations[index] = addressSearchService.getFormattedAddress(from: searchResult)
        // Explicitly clear active search to fix the double-tap issue
        addressSearchService.clearActiveSearch()
    }
    
    func addDestination() {
        destinations.append("")
    }
    
    func removeDestination(at index: Int) {
        if destinations.count > 1 {
            destinations.remove(at: index)
        }
    }
    
    func hideAllSuggestions() {
        addressSearchService.clearActiveSearch()
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
