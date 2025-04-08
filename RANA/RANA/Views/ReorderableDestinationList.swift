//
//  ReorderableDestinationList.swift
//  RANA
//
//  Created by Derek Monturo on 4/8/25.
//

import SwiftUICore
import SwiftUI

struct ReorderableDestinationList: View {
    let destinations: [Location]
    let onReorder: (IndexSet, Int) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(destinations.enumerated()), id: \.offset) { index, destination in
                HStack(alignment: .center, spacing: 12) {
                    // Location number
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 24, height: 24)
                        
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    // Location details
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stop \(index + 1)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(destination.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Move buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            if index > 0 {
                                onReorder(IndexSet(integer: index), index - 1)
                            }
                        }) {
                            Image(systemName: "arrow.up")
                                .foregroundColor(index > 0 ? .blue : .gray)
                        }
                        .disabled(index == 0)
                        
                        Button(action: {
                            if index < destinations.count - 1 {
                                onReorder(IndexSet(integer: index), index + 2)
                            }
                        }) {
                            Image(systemName: "arrow.down")
                                .foregroundColor(index < destinations.count - 1 ? .blue : .gray)
                        }
                        .disabled(index == destinations.count - 1)
                    }
                    .padding(.leading, 8)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 2)
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}
