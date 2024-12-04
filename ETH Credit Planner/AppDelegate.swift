//
//  AppDelegate.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 17.11.24.
//

import Foundation
import SwiftUI
import FirebaseCore
import SimpleAnalytics
import FirebaseAppCheck

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        let providerFactory = AppCheckManager()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        FirebaseApp.configure()
        
        RemoteConfigProvider.shared.fetchCloudValues()
        
        return true
    }
}

extension SimpleAnalytics {
    static let shared: SimpleAnalytics = SimpleAnalytics(hostname: "app.studyplanner.ch")
}
