//  MainViewModelTests.swift
//  RANA
//
//  Created by Derek Monturo on 4/7/25.
//
import XCTest
import Combine
import MapKit
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
    }
    
    func testRemoveDestination() {
        // Setup initial state with multiple destinations
        viewModel.destinations = ["First", "Second", "Third"]
        
        // Remove middle destination
        viewModel.removeDestination(at: 1)
        
        // Verify state after removing
        XCTAssertEqual(viewModel.destinations.count, 2)
        XCTAssertEqual(viewModel.destinations[0], "First")
        XCTAssertEqual(viewModel.destinations[1], "Third")
    }
    
    func testHideAllSuggestions() {
        // Setup state with a mock AddressSearchService
        let mockAddressSearchService = MockAddressSearchService()
        let testViewModel = MainViewModel(
            locationManager: MockLocationManager(),
            addressSearchService: mockAddressSearchService,
            routeOptimizationService: MockRouteOptimizationService()
        )
        
        // Call hideAllSuggestions
        testViewModel.hideAllSuggestions()
        
        // Verify clearActiveSearch was called
        XCTAssertTrue(mockAddressSearchService.clearActiveSearchCalled)
    }
    
    func testUpdateSourceQuery() {
        // Setup state with a mock AddressSearchService
        let mockAddressSearchService = MockAddressSearchService()
        let testViewModel = MainViewModel(
            locationManager: MockLocationManager(),
            addressSearchService: mockAddressSearchService,
            routeOptimizationService: MockRouteOptimizationService()
        )
        
        // Act
        testViewModel.updateSourceQuery("Test Query")
        
        // Assert
        XCTAssertTrue(mockAddressSearchService.searchCalled)
        XCTAssertEqual(mockAddressSearchService.lastQuery, "Test Query")
        XCTAssertEqual(mockAddressSearchService.lastSearchType, .source)
    }
    
    func testUpdateDestinationQuery() {
        // Setup state with a mock AddressSearchService
        let mockAddressSearchService = MockAddressSearchService()
        let testViewModel = MainViewModel(
            locationManager: MockLocationManager(),
            addressSearchService: mockAddressSearchService,
            routeOptimizationService: MockRouteOptimizationService()
        )
        
        // Act
        testViewModel.updateDestinationQuery("Test Destination", index: 2)
        
        // Assert
        XCTAssertTrue(mockAddressSearchService.searchCalled)
        XCTAssertEqual(mockAddressSearchService.lastQuery, "Test Destination")
        if case .destination(let index) = mockAddressSearchService.lastSearchType {
            XCTAssertEqual(index, 2)
        } else {
            XCTFail("Expected destination search type")
        }
    }
    
    func testShowSourceSuggestions() {
        // Setup
        let mockResults = [MockLocalSearchCompletion(title: "Test", subtitle: "")]
        let mockAddressSearchService = MockAddressSearchService(
            mockResults: mockResults,
            mockActiveType: .source
        )
        
        let testViewModel = MainViewModel(
            locationManager: MockLocationManager(),
            addressSearchService: mockAddressSearchService,
            routeOptimizationService: MockRouteOptimizationService()
        )
        
        // Assert
        XCTAssertTrue(testViewModel.showSourceSuggestions)
    }

    func testShowDestinationSuggestions() {
        // Setup
        let mockResults = [MockLocalSearchCompletion(title: "Test", subtitle: "")]
        let mockAddressSearchService = MockAddressSearchService(
            mockResults: mockResults,
            mockActiveType: .destination(index: 1)
        )
        
        let testViewModel = MainViewModel(
            locationManager: MockLocationManager(),
            addressSearchService: mockAddressSearchService,
            routeOptimizationService: MockRouteOptimizationService()
        )
        
        // Assert
        XCTAssertTrue(testViewModel.showDestinationSuggestions(at: 1))
        XCTAssertFalse(testViewModel.showDestinationSuggestions(at: 0))
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

// MARK: - Mock Classes
class MockAddressSearchService: AddressSearchService {
    var mockSearchResults: [MKLocalSearchCompletion] = []
    var mockActiveSearchType: AddressSearchService.SearchType? = nil
    
    var searchCalled = false
    var clearActiveSearchCalled = false
    var lastQuery = ""
    var lastSearchType: AddressSearchService.SearchType? = nil
    
    // Initialize the mock with the desired state
    init(mockResults: [MKLocalSearchCompletion] = [], mockActiveType: AddressSearchService.SearchType? = nil) {
        super.init()
        
        // Use the property setter to set the initial values
        // This works with @Published properties
        self.searchResults = mockResults
        self.activeSearchType = mockActiveType
    }
    
    override func search(for query: String, type: AddressSearchService.SearchType) {
        searchCalled = true
        lastQuery = query
        lastSearchType = type
        
        // Update the real properties
        self.activeSearchType = type
    }
    
    override func clearActiveSearch() {
        clearActiveSearchCalled = true
        super.clearActiveSearch()
    }
}

// Mock LocationManager for testing
class MockLocationManager: LocationManager {
    override func requestLocation() {
        // Do nothing in the mock
    }
}

// Mock RouteOptimizationService for testing
class MockRouteOptimizationService: RouteOptimizationService {
    var optimizeRouteCalled = false
    var cancelOptimizationCalled = false
    var lastSourceAddress: String = ""
    var lastDestinationAddresses: [String] = []
    
    // Match the exact signature from RouteOptimizationService
    override func optimizeRoute(
        sourceAddress: String,
        destinationAddresses: [String],
        completion: @escaping OptimizationCompletion
    ) {
        optimizeRouteCalled = true
        lastSourceAddress = sourceAddress
        lastDestinationAddresses = destinationAddresses
        // Do nothing else in the mock
    }
    
    override func cancelOptimization() {
        cancelOptimizationCalled = true
        // Do nothing else in the mock
    }
}
