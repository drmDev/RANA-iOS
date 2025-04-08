//  AddressSearchServiceTests.swift
//  RANATests
//
//  Created by Derek Monturo on 4/6/25.
//

import XCTest
import MapKit
@testable import RANA

final class AddressSearchServiceTests: XCTestCase {
    
    // Test initial state
    func testInitialState() {
        // Arrange & Act
        let service = AddressSearchService()
        
        // Assert
        XCTAssertTrue(service.searchResults.isEmpty)
        XCTAssertFalse(service.isSearching)
        XCTAssertNil(service.activeSearchType)
        XCTAssertEqual(service.activeDestinationIndex, 0)
    }
    
    // Test searching with empty string
    func testSearchWithEmptyString() {
        // Arrange
        let service = AddressSearchService()
        
        // Act
        service.search(for: "", type: .source)
        
        // Assert
        XCTAssertTrue(service.searchResults.isEmpty)
        XCTAssertNil(service.activeSearchType)
        XCTAssertFalse(service.isSearching)
    }
    
    func testSearchForSourceWithNonEmptyString() {
        // Arrange
        let service = AddressSearchService()
        
        // Create expectations
        let searchStateExpectation = XCTestExpectation(description: "Search state changes to true")
        
        // Monitor the isSearching property for changes
        let cancellable = service.$isSearching
            .dropFirst() // Skip initial value
            .sink { isSearching in
                if isSearching {
                    searchStateExpectation.fulfill()
                }
            }
        
        // Act
        service.search(for: "San Francisco", type: .source)
        
        // Assert type is set immediately
        XCTAssertEqual(service.activeSearchType, .source, "Active search type should be set to source immediately")
        
        // Wait for isSearching to become true (with a longer timeout for reliability)
        wait(for: [searchStateExpectation], timeout: 2.0)
        
        // Verify final state
        XCTAssertTrue(service.isSearching, "isSearching should be true after debounce")
        
        // Clean up
        cancellable.cancel()
    }
    
    // Test searching for destination with non-empty string
    func testSearchForDestinationWithNonEmptyString() {
        // Arrange
        let service = AddressSearchService()
        
        // Act
        service.search(for: "New York", type: .destination(index: 3))
        
        // Assert
        if case .destination(let index) = service.activeSearchType {
            XCTAssertEqual(index, 3)
        } else {
            XCTFail("activeSearchType should be .destination(3)")
        }
        XCTAssertEqual(service.activeDestinationIndex, 3)
        
        // Wait for the debounce timer
        let expectation = XCTestExpectation(description: "Debounce timer")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Now isSearching should be true
        XCTAssertTrue(service.isSearching)
    }
    
    // Test getFormattedAddress with title and subtitle
    func testGetFormattedAddressWithTitleAndSubtitle() {
        // Arrange
        let service = AddressSearchService()
        let mockCompletion = MockLocalSearchCompletion(title: "Apple Park", subtitle: "Cupertino, CA")
        
        // Act
        let formattedAddress = service.getFormattedAddress(from: mockCompletion)
        
        // Assert
        XCTAssertEqual(formattedAddress, "Apple Park, Cupertino, CA")
    }
    
    // Test getFormattedAddress with only title
    func testGetFormattedAddressWithOnlyTitle() {
        // Arrange
        let service = AddressSearchService()
        let mockCompletion = MockLocalSearchCompletion(title: "San Francisco", subtitle: "")
        
        // Act
        let formattedAddress = service.getFormattedAddress(from: mockCompletion)
        
        // Assert
        XCTAssertEqual(formattedAddress, "San Francisco")
    }
    
    // Test completer delegate methods
    func testCompleterDidUpdateResults() {
        // Arrange
        let service = AddressSearchService()
        let mockCompleter = MockLocalSearchCompleter()
        let mockResults = [
            MockLocalSearchCompletion(title: "Result 1", subtitle: "Subtitle 1"),
            MockLocalSearchCompletion(title: "Result 2", subtitle: "Subtitle 2")
        ]
        mockCompleter.mockResults = mockResults
        
        // Act
        service.isSearching = true
        service.completerDidUpdateResults(mockCompleter)
        
        // Wait for async operations
        let expectation = XCTestExpectation(description: "Results updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertEqual(service.searchResults.count, 2)
        XCTAssertFalse(service.isSearching)
    }
        
    // Test error handling
    func testCompleterDidFailWithError() {
        // Arrange
        let service = AddressSearchService()
        let mockCompleter = MockLocalSearchCompleter()
        let testError = NSError(domain: "SearchTest", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test search error"])
        
        // Act
        service.completer(mockCompleter, didFailWithError: testError)
        
        // Wait for async operations
        let expectation = XCTestExpectation(description: "Error handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertFalse(service.isSearching)
    }
    
    // Test clearActiveSearch
    func testClearActiveSearch() {
        // Arrange
        let service = AddressSearchService()
        service.search(for: "Test", type: .source)
        
        // Simulate search results
        service.searchResults = [MockLocalSearchCompletion(title: "Test Result", subtitle: "")]
        
        // Act
        service.clearActiveSearch()
        
        // Assert
        XCTAssertNil(service.activeSearchType)
        XCTAssertTrue(service.searchResults.isEmpty)
    }
}

// MARK: - Mock Classes

// Mock MKLocalSearchCompletion for testing
class MockLocalSearchCompletion: MKLocalSearchCompletion {
    private let mockTitle: String
    private let mockSubtitle: String
    
    init(title: String, subtitle: String) {
        self.mockTitle = title
        self.mockSubtitle = subtitle
        super.init()
    }
    
    override var title: String {
        return mockTitle
    }
    
    override var subtitle: String {
        return mockSubtitle
    }
}

// Mock MKLocalSearchCompleter for testing
class MockLocalSearchCompleter: MKLocalSearchCompleter {
    var mockResults: [MKLocalSearchCompletion] = []
    
    override var results: [MKLocalSearchCompletion] {
        return mockResults
    }
}
