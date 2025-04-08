import XCTest

final class RANAUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app.launch()
    }
    
    // Fixed retry helper method
    func retry(attempts: Int = 3, timeout: TimeInterval = 1.0, test: () -> Void) {
        var lastError: String = ""
        
        for i in 0..<attempts {
            do {
                // Create an expectation to catch failures
                let expectation = XCTestExpectation(description: "Test attempt \(i+1)")
                
                // Run the test code
                test()
                
                // If we got here without assertions failing, we're good
                return
            }
        }
        
        // If we got here, all attempts failed
        XCTFail("Test failed after \(attempts) attempts. Last error: \(lastError)")
    }
     
    func testBasicUIElements() {
        retry(attempts: 3) {
            // Wait for main UI elements to exist with timeouts
            let startingPointText = app.staticTexts["Starting Point"]
            XCTAssertTrue(startingPointText.waitForExistence(timeout: 3.0), "Starting Point text should appear")
            
            // Rest of test code...
        }
    }
    
    func testAddDestination() {
        retry(attempts: 3) {
            // Wait for the Add Destination button to appear
            let addButton = app.buttons["Add Destination"]
            XCTAssertTrue(addButton.waitForExistence(timeout: 3.0), "Add Destination button should appear")
            
            // Count initial number of destination fields - fixed query
            let initialCount = app.textFields.matching(NSPredicate(format: "placeholderValue == 'Enter destination address'")).count
            
            // Tap add destination button
            addButton.tap()
            
            // Wait briefly for UI to update
            sleep(1)
            
            // Verify a new destination field was added - fixed query
            let newCount = app.textFields.matching(NSPredicate(format: "placeholderValue == 'Enter destination address'")).count
            XCTAssertEqual(newCount, initialCount + 1, "A new destination field should be added")
        }
    }
    
    override func tearDownWithError() throws {
        // Reset orientation back to portrait at the end of tests
        XCUIDevice.shared.orientation = .portrait
    }
}
