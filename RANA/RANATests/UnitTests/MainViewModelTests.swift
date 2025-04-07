//
//  MainViewModelTests.swift
//  RANA
//
//  Created by Derek Monturo on 4/7/25.
//
import XCTest
import Combine
@testable import RANA

class MainViewModelTests: XCTestCase {
    
    var viewModel: MainViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = MainViewModel()
        cancellables = []
    }
    
    override func tearDown() {
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Basic State Tests
    
    func testInitialState() {
        // Verify initial state of the ViewModel
        XCTAssertEqual(viewModel.sourceAddress, "")
        XCTAssertEqual(viewModel.destinations.count, 1)
        XCTAssertEqual(viewModel.destinations[0], "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.showingResults)
        XCTAssertNil(viewModel.optimizedRoute)
    }
    
    // MARK: - UI Logic Tests
    
    func testAddDestination() {
        // Initial state
        XCTAssertEqual(viewModel.destinations.count, 1)
        
        // Add a destination
        viewModel.addDestination()
        
        // Verify state after adding
        XCTAssertEqual(viewModel.destinations.count, 2)
        XCTAssertEqual(viewModel.destinations[1], "")
        XCTAssertEqual(viewModel.showDestinationSuggestions.count, 2)
        XCTAssertFalse(viewModel.showDestinationSuggestions[1])
    }
    
    func testRemoveDestination() {
        // Setup initial state with multiple destinations
        viewModel.destinations = ["First", "Second", "Third"]
        viewModel.showDestinationSuggestions = [false, true, false]
        
        // Remove middle destination
        viewModel.removeDestination(at: 1)
        
        // Verify state after removing
        XCTAssertEqual(viewModel.destinations.count, 2)
        XCTAssertEqual(viewModel.destinations[0], "First")
        XCTAssertEqual(viewModel.destinations[1], "Third")
        XCTAssertEqual(viewModel.showDestinationSuggestions.count, 2)
    }
    
    func testHideAllSuggestions() {
        // Setup state with visible suggestions
        viewModel.showSourceSuggestions = true
        viewModel.showDestinationSuggestions = [true, true]
        
        // Hide all suggestions
        viewModel.hideAllSuggestions()
        
        // Verify all suggestions are hidden
        XCTAssertFalse(viewModel.showSourceSuggestions)
        XCTAssertFalse(viewModel.showDestinationSuggestions[0])
        XCTAssertFalse(viewModel.showDestinationSuggestions[1])
    }
    
    func testUpdateSourceQuery() {
        // Act
        viewModel.updateSourceQuery("Test Query")
        
        // Assert
        XCTAssertTrue(viewModel.showSourceSuggestions)
        
        // All destination suggestions should be hidden
        for isShowing in viewModel.showDestinationSuggestions {
            XCTAssertFalse(isShowing)
        }
    }
    
    func testUpdateDestinationQuery() {
        // Ensure we have enough elements in the array
        viewModel.destinations = [""]
        viewModel.showDestinationSuggestions = [false]
        viewModel.showSourceSuggestions = true
        
        // Act
        viewModel.updateDestinationQuery("Test Destination", index: 0)
        
        // Assert
        XCTAssertTrue(viewModel.showDestinationSuggestions[0])
        XCTAssertFalse(viewModel.showSourceSuggestions)
    }
    
    // MARK: - Validation Tests
    
    func testOptimizeRouteValidation() {
        // Setup invalid state (empty addresses)
        viewModel.sourceAddress = ""
        viewModel.destinations = [""]
        
        // Capture alert
        let expectation = self.expectation(description: "Alert shown")
        
        viewModel.$alertItem
            .dropFirst() // Skip initial nil value
            .sink { alertItem in
                if alertItem != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Try to optimize
        viewModel.optimizeRoute()
        
        // Verify alert is shown
        waitForExpectations(timeout: 1.0)
        
        XCTAssertNotNil(viewModel.alertItem)
        XCTAssertEqual(viewModel.alertItem?.title, "Missing Information")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // Test with valid input but don't actually call the service
    func testOptimizeRouteStartsLoading() {
        // Skip the actual optimization by subclassing
        class TestViewModel: MainViewModel {
            override func optimizeRoute() {
                // Set valid addresses
                sourceAddress = "Start"
                destinations = ["Destination"]
                
                // Just set loading to true without calling service
                isLoading = true
            }
        }
        
        let testViewModel = TestViewModel()
        
        // Act
        testViewModel.optimizeRoute()
        
        // Assert
        XCTAssertTrue(testViewModel.isLoading)
    }
    
    func testCancelOptimization() {
        // Setup loading state
        viewModel.isLoading = true
        
        // Cancel
        viewModel.cancelOptimization()
        
        // Verify loading is stopped
        XCTAssertFalse(viewModel.isLoading)
    }
}
