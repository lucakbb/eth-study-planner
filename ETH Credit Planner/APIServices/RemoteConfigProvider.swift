//
//  RemoteConfigProvider.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 30.11.24.
//

import Foundation
import FirebaseRemoteConfig

/// A  class responsible for managing Firebase Remote Config settings in the ETH Credit Planner app.
/// It enables toggling the visibility of the Recommendations tab.
/// The class provides methods to load default values, fetch and activate remote configurations,
/// and store retrieved values in UserDefaults for app-wide access.
class RemoteConfigProvider {
    static let shared = RemoteConfigProvider()
    private var remoteConfig = RemoteConfig.remoteConfig()
    
    enum RemoteConfigValueKey: String {
        case recommendationsEnabled
    }
    
    init() {
        setupConfigs()
        loadDefaultValues()
        
    }
    
    func loadDefaultValues() {
        let appDefaults: [String: Any?] = [
            RemoteConfigValueKey.recommendationsEnabled.rawValue: true
        ]
        remoteConfig.setDefaults(appDefaults as? [String: NSObject])
    }
    
    func setupConfigs() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = (12 * 60 * 60) // 12 hours
        remoteConfig.configSettings = settings
    }
    
    func fetchCloudValues() {
        remoteConfig.fetchAndActivate { [weak self] status, error in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching remote config values: \(error.localizedDescription)")
                return
            }
            
            switch status {
            case .successFetchedFromRemote, .successUsingPreFetchedData:
                let recommendationsEnabled = self.remoteConfig.configValue(forKey: RemoteConfigValueKey.recommendationsEnabled.rawValue).boolValue
                UserDefaults.standard.set(recommendationsEnabled, forKey: "recommendationsEnabled")
                print("Fetched and saved 'recommendationsEnabled': \(recommendationsEnabled)")
            case .error:
                print("Failed to fetch remote config values.")
            @unknown default:
                print("Unknown fetch status.")
            }
        }
    }
    
}
