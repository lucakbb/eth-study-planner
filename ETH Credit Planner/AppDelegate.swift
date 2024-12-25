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

class AppDelegate: NSObject, UIApplicationDelegate, UIWindowSceneDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        let providerFactory = AppCheckManager()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        FirebaseApp.configure()
        
        RemoteConfigProvider.shared.fetchCloudValues()
        
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = Self.self
        return sceneConfig
    }
    
    func scene( _ scene: UIScene, willConnectTo session: UISceneSession,  options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
#if targetEnvironment(macCatalyst)
        if let titlebar = windowScene.titlebar {
            titlebar.titleVisibility = .hidden
            titlebar.toolbar = nil
        }
#endif
    }
}

extension SimpleAnalytics {
    static let shared: SimpleAnalytics = SimpleAnalytics(hostname: "app.studyplanner.ch")
}
