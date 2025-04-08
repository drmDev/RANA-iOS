import CoreLocation

struct OptimizedRoute {
    let startLocation: Location
    private(set) var destinations: [Location]
    
    // Add function to reorder destinations
    mutating func reorderDestinations(fromIndices: IndexSet, toOffset: Int) {
        destinations.move(fromOffsets: fromIndices, toOffset: toOffset)
    }
    
    // Add function to calculate total distance
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
    
    // Format distance for display
    func formattedDistance() -> String {
        let distance = totalDistance()
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            let distanceInKm = distance / 1000
            return String(format: "%.1f km", distanceInKm)
        }
    }
    
    // Estimate travel time (rough approximation)
    func estimatedTime() -> TimeInterval {
        // Assume average speed of 50 km/h (13.89 m/s)
        return totalDistance() / 13.89
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
