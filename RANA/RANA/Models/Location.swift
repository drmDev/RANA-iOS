//
//  Location.swift
//  RANA
//
//  Created by Derek Monturo on 4/7/25.
//

import CoreLocation

struct Location: Equatable {
    let address: String
    let coordinate: CLLocationCoordinate2D
    
    static func == (lhs: Location, rhs: Location) -> Bool {
        return lhs.address == rhs.address &&
               lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}
