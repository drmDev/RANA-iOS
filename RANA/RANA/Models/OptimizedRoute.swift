//
//  OptimizedRoute.swift
//  RANA
//

import Foundation
import CoreLocation

struct OptimizedRoute {
    let startLocation: Location
    let destinations: [Location]
    let totalDistance: Double // in kilometers
    let estimatedTime: TimeInterval // in seconds
    
    init(startLocation: Location, destinations: [Location]) {
        self.startLocation = startLocation
        self.destinations = destinations
        
        // Calculate total distance and estimated time
        let (dist, time) = Self.calculateRouteMetrics(start: startLocation, destinations: destinations)
        self.totalDistance = dist
        self.estimatedTime = time
    }
    
    // Helper to format the estimated time nicely
    func formattedTime() -> String {
        let hours = Int(estimatedTime) / 3600
        let minutes = (Int(estimatedTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // Helper to format the distance with both units
    func formattedDistance() -> String {
        let miles = totalDistance * 0.621371 // Convert km to miles
        
        if miles < 0.1 {
            // For very short distances, show in feet
            let feet = Int(miles * 5280)
            return "\(feet) ft"
        } else if miles < 10 {
            // For shorter distances, show 1 decimal place
            return String(format: "%.1f mi (%.1f km)", miles, totalDistance)
        } else {
            // For longer distances, round to whole numbers
            return String(format: "%.0f mi (%.0f km)", miles, totalDistance)
        }
    }
    
    // Helper to format distance for US audience (miles primary)
    func formattedDistanceMiles() -> String {
        let miles = totalDistance * 0.621371
        
        if miles < 0.1 {
            let feet = Int(miles * 5280)
            return "\(feet) ft"
        } else if miles < 10 {
            return String(format: "%.1f mi", miles)
        } else {
            return String(format: "%.0f mi", miles)
        }
    }
    
    // Helper to format distance for international audience (km primary)
    func formattedDistanceKm() -> String {
        if totalDistance < 1.0 {
            return "\(Int(totalDistance * 1000))m"
        } else if totalDistance < 10 {
            return String(format: "%.1f km", totalDistance)
        } else {
            return String(format: "%.0f km", totalDistance)
        }
    }
    
    // Static method to calculate metrics to avoid initialization issues
    private static func calculateRouteMetrics(start: Location, destinations: [Location]) -> (distance: Double, time: TimeInterval) {
        var totalDist = 0.0
        var previousLocation = start
        
        for destination in destinations {
            let segmentDistance = distance(from: previousLocation.coordinate, to: destination.coordinate)
            totalDist += segmentDistance
            previousLocation = destination
        }
        
        // Rough estimate: 35 mph average speed (56 km/h or 15.6 m/s)
        // This is a reasonable estimate for mixed urban/suburban driving
        let estimatedTime = totalDist * 1000 / 15.6
        
        return (totalDist, estimatedTime)
    }
    
    // Calculate distance between two coordinates (Haversine formula)
    private static func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
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
