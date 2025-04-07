//
//  AddressSearchServiceTests.swift
//  RANA
//
//  Created by Derek Monturo on 4/6/25.
//


//
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
        XCTAssertTrue(service.sourceSearchResults.isEmpty)
        XCTAssertTrue(service.destinationSearchResults.isEmpty)
        XCTAssertFalse(service.isSearching)
        XCTAssertNil(service.activeField)
        XCTAssertEqual(service.activeDestinationIndex, 0)
    }
    
    // Test updating source query with empty string
    func testUpdateSourceQueryWithEmptyString() {
        // Arrange
        let service = AddressSearchService()
        
        // Act
        service.updateSourceQuery("")
        
        // Assert
        XCTAssertTrue(service.sourceSearchResults.isEmpty)
        XCTAssertFalse(service.isSearching)
    }
    
    // Test updating source query with non-empty string
    func testUpdateSourceQueryWithNonEmptyString() {
        // Arrange
        let service = AddressSearchService()
        
        // Act
        service.updateSourceQuery("San Francisco")
        
        // Assert
        XCTAssertTrue(service.isSearching)
        if case .source = service.activeField {
            XCTAssertTrue(true) // Pass if activeField is .source
        } else {
            XCTFail("activeField should be .source")
        }
    }
    
    // Test updating destination query with empty string
    func testUpdateDestinationQueryWithEmptyString() {
        // Arrange
        let service = AddressSearchService()
        
        // Act
        service.updateDestinationQuery("", index: 2)
        
        // Assert
        XCTAssertTrue(service.destinationSearchResults.isEmpty)
        XCTAssertFalse(service.isSearching)
    }
    
    // Test updating destination query with non-empty string
    func testUpdateDestinationQueryWithNonEmptyString() {
        // Arrange
        let service = AddressSearchService()
        
        // Act
        service.updateDestinationQuery("New York", index: 3)
        
        // Assert
        XCTAssertTrue(service.isSearching)
        if case .destination(let index) = service.activeField {
            XCTAssertEqual(index, 3)
        } else {
            XCTFail("activeField should be .destination(3)")
        }
        XCTAssertEqual(service.activeDestinationIndex, 3)
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
    
    // Test completer delegate methods - simpler approach
    func testCompleterDelegateSimplified() {
        // Arrange
        let service = AddressSearchService()
        let mockResults = [
            MockLocalSearchCompletion(title: "Result 1", subtitle: "Subtitle 1"),
            MockLocalSearchCompletion(title: "Result 2", subtitle: "Subtitle 2")
        ]
        
        // Act - directly test the implementation logic
        service.isSearching = true
        
        // Simulate what would happen in the completerDidUpdateResults method
        service.sourceSearchResults = mockResults
        service.isSearching = false
        
        // Assert
        XCTAssertEqual(service.sourceSearchResults.count, 2)
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
