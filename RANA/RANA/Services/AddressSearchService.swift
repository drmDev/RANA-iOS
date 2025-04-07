//
//  AddressSearchService.swift
//  RANA
//
//  Created by Derek Monturo on 4/6/25.
//

import MapKit
import SwiftUI

class AddressSearchService: NSObject, ObservableObject {
    @Published var sourceSearchResults: [MKLocalSearchCompletion] = []
    @Published var destinationSearchResults: [MKLocalSearchCompletion] = []
    @Published var isSearching: Bool = false
    @Published var activeField: SearchField? = nil
    @Published var activeDestinationIndex: Int = 0
    
    private var sourceCompleter = MKLocalSearchCompleter()
    private var destinationCompleter = MKLocalSearchCompleter()
    
    enum SearchField {
        case source
        case destination(Int)
    }
    
    override init() {
        super.init()
        
        // Set up source completer
        sourceCompleter.delegate = self
        sourceCompleter.resultTypes = [.address, .pointOfInterest]
        
        // Set up destination completer
        destinationCompleter.delegate = self
        destinationCompleter.resultTypes = [.address, .pointOfInterest]
    }
    
    func updateSourceQuery(_ query: String) {
        if query.isEmpty {
            sourceSearchResults = []
            return
        }
        
        isSearching = true
        sourceCompleter.queryFragment = query
        activeField = .source
    }
    
    func updateDestinationQuery(_ query: String, index: Int) {
        if query.isEmpty {
            destinationSearchResults = []
            return
        }
        
        isSearching = true
        destinationCompleter.queryFragment = query
        activeField = .destination(index)
        activeDestinationIndex = index
    }
    
    // Helper to get a formatted address string from a search result
    func getFormattedAddress(from result: MKLocalSearchCompletion) -> String {
        // For address results with a subtitle, combine them for a complete address
        if !result.subtitle.isEmpty {
            return "\(result.title), \(result.subtitle)"
        }
        return result.title
    }
    
    func getPlacemark(for completion: MKLocalSearchCompletion, completionHandler: @escaping (CLPlacemark?) -> Void) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            guard error == nil, let mapItem = response?.mapItems.first else {
                completionHandler(nil)
                return
            }
            
            completionHandler(mapItem.placemark)
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension AddressSearchService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.isSearching = false
            
            // Update the appropriate results array based on which completer is reporting
            if completer === self.sourceCompleter {
                self.sourceSearchResults = completer.results
            } else if completer === self.destinationCompleter {
                self.destinationSearchResults = completer.results
            }
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isSearching = false
            print("Search completer error: \(error.localizedDescription)")
        }
    }
}
