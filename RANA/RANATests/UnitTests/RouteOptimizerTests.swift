//
//  RouteOptimizerTests.swift
//  RANA
//
//  Created by Derek Monturo on 4/7/25.
//


import XCTest
import CoreLocation
@testable import RANA

final class RouteOptimizerTests: XCTestCase {
    
    // Test locations for consistent testing
    let testLocations = [
        Location(address: "Start", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)), // San Francisco
        Location(address: "Dest A", coordinate: CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863)), // San Jose
        Location(address: "Dest B", coordinate: CLLocationCoordinate2D(latitude: 37.8715, longitude: -122.2730)), // Berkeley
        Location(address: "Dest C", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.2341)), // Oakland
        Location(address: "Dest D", coordinate: CLLocationCoordinate2D(latitude: 38.4404, longitude: -122.7141))  // Santa Rosa
    ]
    
    // Test that optimizer returns correct number of locations
    func testOptimizerReturnsAllLocations() {
        // Arrange
        let optimizer = RouteOptimizer()
        let start = testLocations[0]
        let destinations = Array(testLocations[1...4])
        
        // Act
        let optimizedRoute = optimizer.optimizeRoute(start: start, destinations: destinations)
        
        // Assert
        XCTAssertEqual(optimizedRoute.count, destinations.count + 1) // +1 for start location
        XCTAssertEqual(optimizedRoute.first, start, "First location should be the start point")
        
        // Check that all destinations are included (order doesn't matter for this test)
        for destination in destinations {
            XCTAssertTrue(optimizedRoute.contains(destination), "All destinations should be included")
        }
    }
    
    // Test nearest neighbor algorithm directly
    func testNearestNeighborAlgorithm() {
        // Arrange
        let optimizer = RouteOptimizer()
        let start = testLocations[0] // San Francisco
        
        // We'll use a specific set of destinations with known "nearest" ordering
        // San Francisco -> Oakland -> Berkeley -> San Jose -> Santa Rosa
        let destinations = [
            testLocations[3], // Oakland (closest to SF)
            testLocations[2], // Berkeley (closest to Oakland)
            testLocations[1], // San Jose (closer to Berkeley than Santa Rosa)
            testLocations[4]  // Santa Rosa (furthest)
        ]
        
        // Act
        let route = optimizer.nearestNeighborRoute(start: start, destinations: destinations)
        
        // Assert
        XCTAssertEqual(route.count, 5) // Start + 4 destinations
        XCTAssertEqual(route[0], start)
        XCTAssertEqual(route[1], testLocations[3]) // Oakland should be first destination
        XCTAssertEqual(route[2], testLocations[2]) // Berkeley should be second
        // The exact order of the rest might depend on precise distances
    }
    
    // Test 2-opt improvement with a known suboptimal route
    func test2OptImprovement() {
        // Arrange
        let optimizer = RouteOptimizer()
        
        // Create a deliberately suboptimal route with a crossover
        // San Francisco -> Santa Rosa -> San Jose -> Berkeley -> Oakland
        let suboptimalRoute = [
            testLocations[0], // San Francisco
            testLocations[4], // Santa Rosa (far north)
            testLocations[1], // San Jose (far south) - creates crossover
            testLocations[2], // Berkeley (back north) - creates crossover
            testLocations[3]  // Oakland (east bay)
        ]
        
        // Act
        let improvedRoute = optimizer.twoOptImprovement(route: suboptimalRoute)
        
        // Assert
        XCTAssertEqual(improvedRoute.count, suboptimalRoute.count, "Should have same number of locations")
        XCTAssertEqual(improvedRoute.first, suboptimalRoute.first, "Start point should remain the same")
        
        // Calculate total distances to verify improvement
        let originalDistance = routeDistance(suboptimalRoute)
        let improvedDistance = routeDistance(improvedRoute)
        
        XCTAssertLessThan(improvedDistance, originalDistance, "Improved route should be shorter")
    }
    
    // Test with known optimal route
    func testKnownOptimalRoute() {
        // Arrange
        let optimizer = RouteOptimizer()
        
        // Simple square where optimal route is obvious
        let squareLocations = [
            Location(address: "Center", coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)),
            Location(address: "North", coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 0)),
            Location(address: "East", coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 1)),
            Location(address: "South", coordinate: CLLocationCoordinate2D(latitude: -1, longitude: 0)),
            Location(address: "West", coordinate: CLLocationCoordinate2D(latitude: 0, longitude: -1))
        ]
        
        let start = squareLocations[0]
        let destinations = Array(squareLocations[1...4])
        
        // Optimal route would be clockwise or counter-clockwise
        let clockwiseRoute = [
            squareLocations[0], // Center
            squareLocations[1], // North
            squareLocations[2], // East
            squareLocations[3], // South
            squareLocations[4]  // West
        ]
        
        let counterClockwiseRoute = [
            squareLocations[0], // Center
            squareLocations[1], // North
            squareLocations[4], // West
            squareLocations[3], // South
            squareLocations[2]  // East
        ]
        
        // Act
        let optimizedRoute = optimizer.optimizeRoute(start: start, destinations: destinations)
        
        // Assert
        let optimizedDistance = routeDistance(optimizedRoute)
        let clockwiseDistance = routeDistance(clockwiseRoute)
        let counterClockwiseDistance = routeDistance(counterClockwiseRoute)
        
        // The optimized route should be close to one of the optimal routes
        let minOptimalDistance = min(clockwiseDistance, counterClockwiseDistance)
        
        // Allow small margin of error due to floating point calculations
        XCTAssertEqual(optimizedDistance, minOptimalDistance, accuracy: 0.001, 
                      "Optimized route should match one of the optimal routes")
    }
    
    // Helper function to calculate total route distance
    private func routeDistance(_ route: [Location]) -> Double {
        var totalDistance = 0.0
        
        for i in 0..<route.count-1 {
            let from = route[i].coordinate
            let to = route[i+1].coordinate
            
            totalDistance += distance(from: from, to: to)
        }
        
        return totalDistance
    }
    
    // Calculate distance between two coordinates
    private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let earthRadius = 6371.0 // Earth radius in kilometers
        
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180
        
        let dLat = lat2 - lat1
        let dLon = lon2 - lon1
        
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1) * cos(lat2) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadius * c
    }
}