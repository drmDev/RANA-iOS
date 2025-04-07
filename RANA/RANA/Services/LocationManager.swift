//
//  LocationManager.swift
//  RANA
//
//  Created by Derek Monturo on 4/6/25.
//

import CoreLocation
import SwiftUI

// LocationManager handles all location services for the app
// It implements CLLocationManagerDelegate to receive location updates
// and ObservableObject to publish changes to SwiftUI views
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // Core location manager instance that provides location data
    private let locationManager = CLLocationManager()
    
    // For testing purposes only
    internal var geocoder: CLGeocoder = CLGeocoder()
    
    // @Published properties automatically notify observers (SwiftUI views) when changed
    // This enables automatic UI updates whenever these values change
    @Published var currentAddress: String = ""  // The user's current address as text
    @Published var isUpdating: Bool = false     // Whether location is currently being updated
    @Published var lastError: String? = nil     // Most recent error message, if any
    
    override init() {
        super.init()
        // Set up the location manager
        locationManager.delegate = self         // This class will receive location callbacks
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // Request highest accuracy
    }
    
    // In LocationManager.swift
    func requestLocation() {
        // Set state to updating
        isUpdating = true
        lastError = nil
        
        // Force a refresh by temporarily clearing the current address
        // This ensures that even if the same address is found again,
        // it will be treated as a new value
        DispatchQueue.main.async {
            self.currentAddress = ""
        }
        
        // Request permission if not already granted
        locationManager.requestWhenInUseAuthorization()
        
        // Request a single location update
        locationManager.requestLocation()
    }
    
    // CLLocationManagerDelegate method called when new locations are available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Ensure we have at least one location
        guard let location = locations.first else {
            isUpdating = false
            lastError = "No location data received"
            return
        }
        
        // Convert GPS coordinates to human-readable address (reverse geocoding)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            // Switch to main thread for UI updates
            DispatchQueue.main.async {
                // Mark updating as complete
                self?.isUpdating = false
                
                // Handle any errors from geocoding
                if let error = error {
                    self?.lastError = error.localizedDescription
                    print("Geocoding error: \(error.localizedDescription)")
                    return
                }
                
                // Ensure we have a valid placemark
                guard let placemark = placemarks?.first else {
                    self?.lastError = "No address found for this location"
                    return
                }
                
                // Construct a formatted address from placemark components
                // subThoroughfare: house number
                // thoroughfare: street name
                // locality: city
                // administrativeArea: state
                // postalCode: ZIP code
                let address = [
                    placemark.subThoroughfare,
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.postalCode
                ]
                    .compactMap { $0 }  // Remove nil values
                    .joined(separator: " ")  // Join with spaces
                
                // Update the published address property
                self?.currentAddress = address
            }
        }
    }
    
    // CLLocationManagerDelegate method called when location cannot be determined
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isUpdating = false
            self.lastError = error.localizedDescription
            print("Location error: \(error.localizedDescription)")
        }
    }
}
