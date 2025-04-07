//
//  RouteOptimizerIntegrationTests.swift
//  RANA
//
//  Created by Derek Monturo on 4/7/25.
//
//  Integration tests for RouteOptimizer that require network access and real geocoding services.
import XCTest
import CoreLocation
@testable import RANA

final class RouteOptimizerIntegrationTests: XCTestCase {
    
    func testWithRealAddresses() {
        // This test requires geocoding which is asynchronous
        let expectation = XCTestExpectation(description: "Geocode addresses")
        
        // Addresses to test
        let addresses = [
            "1 Infinite Loop, Cupertino, CA", // Apple
            "1600 Amphitheatre Parkway, Mountain View, CA", // Google
            "1 Hacker Way, Menlo Park, CA", // Facebook
            "2800 Sand Hill Road, Menlo Park, CA" // VC Row
        ]
        
        // Increase timeout for geocoding
        let timeout: TimeInterval = 30.0
        
        // Geocode addresses to get coordinates
        let geocoder = CLGeocoder()
        var locations: [Location] = []
        let dispatchGroup = DispatchGroup()
        
        for address in addresses {
            dispatchGroup.enter()
            
            geocoder.geocodeAddressString(address) { placemarks, error in
                defer {
                    dispatchGroup.leave()
                }
                
                if let error = error {
                    print("Geocoding error for \(address): \(error.localizedDescription)")
                    return
                }
                
                guard let placemark = placemarks?.first, let location = placemark.location else {
                    print("No location found for address: \(address)")
                    return
                }
                
                let loc = Location(address: address, coordinate: location.coordinate)
                locations.append(loc)
                // print("Successfully geocoded: \(address)")
            }
            
            // Add delay between geocoding requests to avoid rate limiting
            Thread.sleep(forTimeInterval: 1.0)
        }
        
        // Wait for all geocoding to complete
        dispatchGroup.notify(queue: .main) {
            expectation.fulfill()
            
            // Only continue with optimization if we have at least 2 locations
            guard locations.count >= 2 else {
                XCTFail("Not enough locations geocoded: \(locations.count)")
                return
            }
            
            // print("Geocoded \(locations.count) of \(addresses.count) addresses")
            
            // Run optimization
            let optimizer = RouteOptimizer()
            let start = locations[0]
            let destinations = Array(locations[1...])
            
            let optimizedRoute = optimizer.optimizeRoute(start: start, destinations: destinations)
            
            // Verify results
            XCTAssertEqual(optimizedRoute.count, locations.count)
            XCTAssertEqual(optimizedRoute.first, start)
            
            // Print the optimized route for manual verification
            print("Optimized route:")
            for (index, location) in optimizedRoute.enumerated() {
                print("\(index). \(location.address)")
            }
        }
        
        wait(for: [expectation], timeout: timeout)
    }
}
