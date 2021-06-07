//
//  PrivateDatabaseApp.swift
//  (cloudkit-samples) private-database
//

import SwiftUI

@main
struct PrivateDatabaseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ViewModel())
        }
    }
}

