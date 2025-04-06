//
//  MainView.swift
//  RANA
//
//  Created by Derek Monturo on 4/6/25.
//


import SwiftUI
import CoreLocation

struct MainView: View {
    @State private var sourceAddress: String = ""
    @State private var destinations: [String] = [""] // Start with one empty destination
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title
                Text("Route Optimizer")
                    .font(.largeTitle)
                    .padding(.top)
                
                // Source Address Field
                VStack(alignment: .leading) {
                    Text("Starting Point")
                        .font(.headline)
                    TextField("Enter starting address", text: $sourceAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Destinations
                VStack(alignment: .leading) {
                    Text("Destinations")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(destinations.indices, id: \.self) { index in
                        HStack {
                            TextField("Enter destination address", text: $destinations[index])
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            // Delete button (X)
                            Button(action: {
                                if destinations.count > 1 {
                                    destinations.remove(at: index)
                                }
                                showAlert("Delete button clicked for destination \(index + 1)")
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Add destination button (+)
                    Button(action: {
                        destinations.append("")
                        showAlert("Add destination button clicked")
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Destination")
                        }
                        .foregroundColor(.green)
                    }
                    .padding(.horizontal)
                }
                
                // Optimize Route Button
                Button(action: {
                    optimizeRoute()
                }) {
                    Text("Optimize Route")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
    
    // Helper function to show alerts
    private func showAlert(_ message: String) {
        print(message) // For now, just printing to console
    }
    
    // Function to handle route optimization
    private func optimizeRoute() {
        var routeMessage = "Current Addresses:\n\n"
        
        if sourceAddress.isEmpty && destinations.allSatisfy({ $0.isEmpty }) {
            routeMessage = "No addresses entered yet"
        } else {
            routeMessage += "Starting Point: \(sourceAddress)\n\n"
            for (index, destination) in destinations.enumerated() {
                routeMessage += "Destination \(index + 1): \(destination)\n"
            }
        }
        
        print(routeMessage) // For now, just printing to console
    }
}

// Preview provider for SwiftUI canvas
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
