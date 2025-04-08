//  AddressSearchService.swift
//  RANA
//
//  Created by Derek Monturo on 4/6/25.
//

import MapKit
import Combine

class AddressSearchService: NSObject, ObservableObject {
    // Published properties
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var isSearching: Bool = false
    @Published var activeSearchType: SearchType? = nil
    @Published var activeDestinationIndex: Int = 0
    
    // Single completer instance for all searches
    private var searchCompleter = MKLocalSearchCompleter()
    private var searchTimer: Timer?
    
    // Enum to track which field is being searched
    enum SearchType: Equatable {
        case source
        case destination(index: Int)
    }
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }
    
    func search(for query: String, type: SearchType) {
        // Clear results if query is empty
        guard !query.isEmpty else {
            searchResults = []
            activeSearchType = nil
            return
        }
        
        // Set active search context
        activeSearchType = type
        if case .destination(let index) = type {
            activeDestinationIndex = index
        }
        
        // Add debouncing to prevent excessive API calls
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.isSearching = true
            self?.searchCompleter.queryFragment = query
        }
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
    
    // Clear active search state
    func clearActiveSearch() {
        activeSearchType = nil
        searchResults = []
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension AddressSearchService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.isSearching = false
            self.searchResults = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isSearching = false
            print("Search completer error: \(error.localizedDescription)")
        }
    }
}
