//
//  SubTrackerApp.swift
//  SubTracker
//
//  Created by AI Agent on 2026-03-27.
//

import SwiftUI

@main
struct SubTrackerApp: App {
    @StateObject private var dataController = DataController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
}
