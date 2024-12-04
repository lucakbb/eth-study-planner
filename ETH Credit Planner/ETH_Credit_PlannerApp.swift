//
//  ETH_Credit_PlannerApp.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 03.11.24.
//

import SwiftUI
import FirebaseCore

@main
struct ETH_Credit_PlannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
