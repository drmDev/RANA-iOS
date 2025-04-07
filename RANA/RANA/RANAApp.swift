//
//  RANAApp.swift
//  RANA
//
//  Created by Derek Monturo on 4/6/25.
//

import SwiftUI

@main
struct RANAApp: App {
    init() {
        // Set environment variable to show backtrace for CoreGraphics errors
        // setenv("CG_NUMERICS_SHOW_BACKTRACE", "1", 1)
    }
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
