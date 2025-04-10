//
//  RouteOptimizer.swift
//  RANA
//
//  Created by Derek Monturo on 4/7/25.
//
import CoreLocation

class RouteOptimizer {
    
    func optimizeRoute(start: Location, destinations: [Location]) -> [Location] {
        print("🧮 RouteOptimizer: Starting optimization with \(destinations.count) destinations")
        
        // 1. Generate initial route using Nearest Neighbor
        print("🔄 RouteOptimizer: Running Nearest Neighbor algorithm")
        var route = nearestNeighborRoute(start: start, destinations: destinations)
        print("✅ RouteOptimizer: Nearest Neighbor complete")
        
        // 2. Improve route using 2-Opt
        print("🔄 RouteOptimizer: Running 2-Opt improvement")
        route = twoOptImprovement(route: route)
        print("✅ RouteOptimizer: 2-Opt improvement complete")
        
        return route
    }
    
    func nearestNeighborRoute(start: Location, destinations: [Location]) -> [Location] {
        var route: [Location] = [start]
        var unvisited = destinations
        
        print("📊 NearestNeighbor: Starting with \(unvisited.count) unvisited locations")
        
        while !unvisited.isEmpty {
            let current = route.last!
            if let (nextIndex, distance) = findNearest(from: current, in: unvisited) {
                let distanceInMiles = distance * 0.621371
                print("📏 NearestNeighbor: Found nearest point at \(String(format: "%.2f", distanceInMiles)) mi")
                route.append(unvisited[nextIndex])
                unvisited.remove(at: nextIndex)
            } else {
                print("⚠️ NearestNeighbor: Could not find nearest location")
                break // Safety check
            }
        }
        
        print("✅ NearestNeighbor: Route completed with \(route.count) points")
        return route
    }
    
    func twoOptImprovement(route: [Location]) -> [Location] {
        var improved = route
        var improvement = true
        var iterations = 0
        let maxIterations = 100 // Prevent infinite loops
        
        print("🔄 2-Opt: Starting with route of \(route.count) points")
        
        while improvement && iterations < maxIterations {
            improvement = false
            iterations += 1
            
            var swapsMade = 0
            
            for i in 0..<improved.count-2 {
                for j in i+2..<improved.count {
                    if twoOptSwapImproves(route: improved, i: i, j: j) {
                        improved = twoOptSwap(route: improved, i: i, j: j)
                        improvement = true
                        swapsMade += 1
                    }
                }
            }
            
            print("🔄 2-Opt: Iteration \(iterations), made \(swapsMade) improvements")
            
            // Circuit breaker - if we're taking too long, just use what we have
            if iterations >= 20 && improved.count > 10 {
                print("⚠️ 2-Opt: Breaking early after \(iterations) iterations")
                break
            }
        }
        
        print("✅ 2-Opt: Completed after \(iterations) iterations")
        return improved
    }
    
    private func findNearest(from location: Location, in locations: [Location]) -> (Int, Double)? {
        guard !locations.isEmpty else { return nil }
        
        var nearestIndex = 0
        var nearestDistance = distance(from: location.coordinate, to: locations[0].coordinate)
        
        for i in 1..<locations.count {
            let dist = distance(from: location.coordinate, to: locations[i].coordinate)
            if dist < nearestDistance {
                nearestDistance = dist
                nearestIndex = i
            }
        }
        
        return (nearestIndex, nearestDistance)
    }
    
    private func twoOptSwapImproves(route: [Location], i: Int, j: Int) -> Bool {
        guard i < j && i >= 0 && j < route.count else { return false }
        
        // Calculate current distance
        let d1 = distance(from: route[i].coordinate, to: route[i+1].coordinate)
        let d2 = distance(from: route[j].coordinate, to: route[(j+1) % route.count].coordinate)
        
        // Calculate new distance if we swap
        let d3 = distance(from: route[i].coordinate, to: route[j].coordinate)
        let d4 = distance(from: route[i+1].coordinate, to: route[(j+1) % route.count].coordinate)
        
        // Return true if new distance is shorter
        return (d3 + d4) < (d1 + d2)
    }
    
    private func twoOptSwap(route: [Location], i: Int, j: Int) -> [Location] {
        guard i < j && i >= 0 && j < route.count else { return route }
        
        var newRoute = route
        
        // Reverse the segment between i+1 and j
        let segment = Array(route[i+1...j])
        for k in 0..<segment.count {
            newRoute[i+1+k] = segment[segment.count-1-k]
        }
        
        return newRoute
    }
    
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
