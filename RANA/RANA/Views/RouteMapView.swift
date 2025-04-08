//
//  RouteMapView.swift
//  RANA
//
//  Created by Derek Monturo on 4/8/25.
//

import SwiftUI
import MapKit

struct RouteMapView: UIViewRepresentable {
    var startLocation: Location
    var destinations: [Location]
    var showsUserLocation: Bool = true
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showsUserLocation
        mapView.mapType = .standard
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Remove any existing annotations and overlays
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        // Add start annotation
        let startAnnotation = createAnnotation(
            for: startLocation,
            title: "Start",
            isPrimary: true
        )
        mapView.addAnnotation(startAnnotation)
        
        // Add destination annotations
        for (index, destination) in destinations.enumerated() {
            let annotation = createAnnotation(
                for: destination,
                title: "Stop \(index + 1)",
                isPrimary: false
            )
            mapView.addAnnotation(annotation)
        }
        
        // Create a polyline to show the route
        let routePoints = [startLocation] + destinations
        let coordinates = routePoints.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        
        // Set the map region to show all points
        setRegionToShowAllPoints(mapView, coordinates: coordinates)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Custom annotation for distinguishing start vs destinations
    private func createAnnotation(for location: Location, title: String, isPrimary: Bool) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        annotation.title = title
        annotation.subtitle = location.address
        return annotation
    }
    
    // Calculate a region that shows all points with padding
    private func setRegionToShowAllPoints(_ mapView: MKMapView, coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }
        
        if coordinates.count == 1 {
            // If only one point, center on it with a default zoom level
            let region = MKCoordinateRegion(
                center: coordinates[0],
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            mapView.setRegion(region, animated: true)
            return
        }
        
        // Find the min/max latitude and longitude
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        // Calculate center point
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        // Calculate span with padding
        let latDelta = (maxLat - minLat) * 1.4 // 40% padding
        let lonDelta = (maxLon - minLon) * 1.4
        
        // Ensure minimum zoom level
        let span = MKCoordinateSpan(
            latitudeDelta: max(latDelta, 0.02),
            longitudeDelta: max(lonDelta, 0.02)
        )
        
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    // Coordinator class to handle map delegate methods
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RouteMapView
        
        init(_ parent: RouteMapView) {
            self.parent = parent
        }
        
        // Customize annotation views
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "RoutePin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Customize the pin appearance
            if let markerView = annotationView as? MKMarkerAnnotationView {
                // Start point is blue, destinations are red
                if annotation.title == "Start" {
                    markerView.markerTintColor = .blue
                    markerView.glyphImage = UIImage(systemName: "house.fill")
                } else {
                    markerView.markerTintColor = .red
                    
                    // Extract stop number from title if possible
                    if let title = annotation.title as? String, title.starts(with: "Stop "),
                       let stopNumber = Int(title.replacingOccurrences(of: "Stop ", with: "")) {
                        markerView.glyphText = "\(stopNumber)"
                    } else {
                        markerView.glyphImage = UIImage(systemName: "mappin")
                    }
                }
            }
            
            return annotationView
        }
        
        // Customize polyline appearance
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKPolyline {
                let renderer = MKPolylineRenderer(overlay: overlay)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4.0
                renderer.lineDashPattern = [1, 1] // Dashed line
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
