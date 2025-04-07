//
//  RouteOptimizationService.swift
//  RANA
//
//  Created by Derek Monturo on 4/7/25.
//

import Foundation
import CoreLocation
import Combine

class RouteOptimizationService {
    // Completion handler type definition
    typealias OptimizationCompletion = (Result<OptimizedRoute, OptimizationError>) -> Void
    
    // Error types
    enum OptimizationError: Error, LocalizedError {
        case invalidAddresses
        case geocodingFailed(String)
        case notEnoughValidLocations
        case optimizationFailed
        case timeout
        
        var errorDescription: String? {
            switch self {
            case .invalidAddresses:
                return "Missing source or destination addresses."
            case .geocodingFailed(let address):
                return "Couldn't find location for: \(address)."
            case .notEnoughValidLocations:
                return "Need at least a source and one destination to optimize route."
            case .optimizationFailed:
                return "Failed to optimize the route. Please try again."
            case .timeout:
                return "The route optimization process took too long. Please try again with fewer destinations."
            }
        }
    }
    
    private let optimizer = RouteOptimizer()
    private var timeoutWorkItem: DispatchWorkItem?
    
    // Main public function to optimize a route
    func optimizeRoute(sourceAddress: String, 
                       destinationAddresses: [String], 
                       completion: @escaping OptimizationCompletion) {
        
        print("⏱️ Starting route optimization process")
        
        // Validate addresses
        let validDestinations = destinationAddresses.filter { !$0.isEmpty }
        guard !sourceAddress.isEmpty, !validDestinations.isEmpty else {
            print("❌ Missing source or destination addresses")
            completion(.failure(.invalidAddresses))
            return
        }
        
        print("📍 Source: \(sourceAddress)")
        print("📍 Destinations: \(validDestinations)")
        
        // Set up timeout
        setupTimeout(completion: completion)
        
        // Start geocoding process
        geocodeAddressesSequentially(
            sourceAddress: sourceAddress,
            destinationAddresses: validDestinations,
            completion: completion
        )
    }
    
    // Cancel any ongoing optimization
    func cancelOptimization() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
    }
    
    // MARK: - Private Methods
    
    private func setupTimeout(completion: @escaping OptimizationCompletion) {
        // Cancel any existing timeout
        timeoutWorkItem?.cancel()
        
        // Create new timeout
        let timeoutWorkItem = DispatchWorkItem {
            print("⚠️ TIMEOUT: Route optimization process took too long")
            completion(.failure(.timeout))
        }
        self.timeoutWorkItem = timeoutWorkItem
        
        // Schedule timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: timeoutWorkItem)
    }
    
    private func geocodeAddressesSequentially(
        sourceAddress: String,
        destinationAddresses: [String],
        completion: @escaping OptimizationCompletion
    ) {
        var allLocations: [Location] = []
        var currentIndex = -1 // Start with -1 to represent source address
        let allAddresses = [sourceAddress] + destinationAddresses
        
        func processNextAddress() {
            currentIndex += 1
            
            // Check if we've processed all addresses
            if currentIndex >= allAddresses.count {
                print("✅ All addresses geocoded successfully")
                completeOptimization(locations: allLocations, completion: completion)
                return
            }
            
            let address = allAddresses[currentIndex]
            print("🔍 Geocoding address \(currentIndex): \(address)")
            
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let error = error {
                    print("❌ Error geocoding address \(currentIndex): \(error.localizedDescription)")
                    
                    // If source address fails, that's a critical error
                    if currentIndex == 0 {
                        self.timeoutWorkItem?.cancel()
                        completion(.failure(.geocodingFailed(address)))
                        return
                    }
                    
                    // For destinations, we can continue with other addresses
                    DispatchQueue.main.async {
                        processNextAddress()
                    }
                    return
                }
                
                guard let placemark = placemarks?.first, let location = placemark.location else {
                    print("⚠️ No location found for address \(currentIndex)")
                    
                    // If source address fails, that's a critical error
                    if currentIndex == 0 {
                        self.timeoutWorkItem?.cancel()
                        completion(.failure(.geocodingFailed(address)))
                        return
                    }
                    
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
    
    private func completeOptimization(
        locations: [Location], 
        completion: @escaping OptimizationCompletion
    ) {
        guard locations.count >= 2 else {
            print("❌ Not enough valid locations to optimize")
            timeoutWorkItem?.cancel()
            completion(.failure(.notEnoughValidLocations))
            return
        }
        
        let source = locations[0]
        let destinations = Array(locations.dropFirst())
        
        print("🧮 Starting route optimization with \(destinations.count) destinations")
        
        // Optimize route
        let optimizedDestinations = optimizer.optimizeRoute(start: source, destinations: destinations)
        
        print("✅ Route optimization complete")
        
        // Cancel timeout since we're done
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        
        // Create route object
        let optimizedRoute = OptimizedRoute(
            startLocation: source,
            destinations: Array(optimizedDestinations.dropFirst())
        )
        
        print("📊 Optimized route: \(optimizedDestinations.map { $0.address })")
        
        // Return result
        completion(.success(optimizedRoute))
    }
}
