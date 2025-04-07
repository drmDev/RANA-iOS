//
//  LocationManagerTests.swift
//  RANATests
//
//  Created by Derek Monturo on 4/6/25.
//

import XCTest
import CoreLocation
@testable import RANA

final class LocationManagerTests: XCTestCase {
    
    // Test initial state of LocationManager
    func testInitialState() {
        // Arrange & Act
        let locationManager = LocationManager()
        
        // Assert
        XCTAssertEqual(locationManager.currentAddress, "")
        XCTAssertFalse(locationManager.isUpdating)
        XCTAssertNil(locationManager.lastError)
    }
    
    // Test that error is handled correctly
    func testLocationError() {
        // Arrange
        let locationManager = LocationManager()
        let testError = NSError(domain: "LocationTest", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test location error"])
        
        // Act
        locationManager.locationManager(CLLocationManager(), didFailWithError: testError)
        
        // Wait for async operations
        let expectation = XCTestExpectation(description: "Error handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertFalse(locationManager.isUpdating)
        XCTAssertEqual(locationManager.lastError, "Test location error")
    }
    
    // Test handling of empty locations array
    func testEmptyLocationsArray() {
        // Arrange
        let locationManager = LocationManager()
        locationManager.isUpdating = true
        
        // Act
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: [])
        
        // Assert
        XCTAssertFalse(locationManager.isUpdating)
        XCTAssertEqual(locationManager.lastError, "No location data received")
    }
}
