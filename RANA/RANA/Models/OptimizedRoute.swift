import CoreLocation

struct OptimizedRoute {
    let startLocation: Location
    private(set) var destinations: [Location]
    
    // Constants for unit conversion
    private let kmToMiles = 0.621371
    
    // Add function to reorder destinations
    mutating func reorderDestinations(fromIndices: IndexSet, toOffset: Int) {
        destinations.move(fromOffsets: fromIndices, toOffset: toOffset)
    }
    
    // Add function to calculate total distance (still in km internally)
    func totalDistance() -> Double {
        var total = 0.0
        let allPoints = [startLocation] + destinations
        
        for i in 0..<allPoints.count-1 {
            let from = allPoints[i].coordinate
            let to = allPoints[i+1].coordinate
            
            let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
            let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
            
            total += fromLocation.distance(from: toLocation)
        }
        
        return total
    }
    
    // Format distance for display (now in miles)
    func formattedDistance() -> String {
        let distanceInMeters = totalDistance()
        
        // For very short distances, still show in meters
        if distanceInMeters < 100 {
            return "\(Int(distanceInMeters))m"
        } else {
            // Convert km to miles for display
            let distanceInMiles = (distanceInMeters / 1000) * kmToMiles
            
            // Format based on distance
            if distanceInMiles < 0.1 {
                // For very short distances (less than 0.1 miles)
                return String(format: "%.2f mi", distanceInMiles)
            } else if distanceInMiles < 10 {
                // For medium distances (less than 10 miles)
                return String(format: "%.1f mi", distanceInMiles)
            } else {
                // For longer distances (10+ miles)
                return String(format: "%.0f mi", distanceInMiles)
            }
        }
    }
    
    // Estimate travel time (rough approximation)
    func estimatedTime() -> TimeInterval {
        // Assume average speed of 30 mph (13.4 m/s)
        // We keep the calculation in metric but adjust the speed
        return totalDistance() / 13.4
    }
    
    // Format time for display
    func formattedTime() -> String {
        let seconds = estimatedTime()
        
        if seconds < 60 {
            return "\(Int(seconds))s"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))min"
        } else {
            let hours = Int(seconds / 3600)
            let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)min"
        }
    }
}
