//  RANAUITests.swift
//  RANAUITests
//
//  Created by Derek Monturo on 4/6/25.
//

import XCTest

final class RANAUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app.launch()
    }
    
    func testBasicUIElements() throws {
        // Verify main UI elements exist
        XCTAssertTrue(app.staticTexts["Starting Point"].exists)
        XCTAssertTrue(app.staticTexts["Destinations"].exists)
        
        // Verify input fields exist
        let sourceField = app.textFields.matching(identifier: "sourceAddressField").firstMatch
        XCTAssertTrue(sourceField.exists, "Source address field should exist")
        
        XCTAssertTrue(app.textFields["Enter destination address"].exists)
        
        // Verify buttons exist
        let locationButton = app.buttons.matching(identifier: "currentLocationButton").firstMatch
        XCTAssertTrue(locationButton.exists, "Current location button should exist")
        
        XCTAssertTrue(app.buttons["Add Destination"].exists)
        XCTAssertTrue(app.buttons["Optimize Route"].exists)
    }
    
    func testAddDestination() throws {
        // Count initial number of destination fields
        let initialCount = app.textFields.matching(identifier: "Enter destination address").count
        
        // Tap add destination button
        app.buttons["Add Destination"].tap()
        
        // Verify a new destination field was added
        let newCount = app.textFields.matching(identifier: "Enter destination address").count
        XCTAssertEqual(newCount, initialCount + 1)
    }
    
    override func tearDownWithError() throws {
        // Reset orientation back to portrait at the end of tests
        XCUIDevice.shared.orientation = .portrait
    }
}
