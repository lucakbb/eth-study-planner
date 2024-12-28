//
//  CloudKitPreferencesManager.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 23.12.24.
//

import Foundation

/// A simple manager class that stores three settings (oldUser, userName, interests)
/// both locally via UserDefaults and in iCloud Key-Value-Store. It also listens
/// for changes coming from iCloud and updates local values accordingly.
class CloudKitPreferencesManager {
    
    // MARK: - Singleton
        static let shared = CloudKitPreferencesManager()
        
        // MARK: - Keys
        private enum Keys {
            static let oldUser    = "oldUser"
            static let userName   = "userName"
            static let interests  = "interests"
            static let iCloudSync = "icloud_sync"
        }
        
        // MARK: - Stores
        private let localStore  = UserDefaults.standard
        private let iCloudStore = NSUbiquitousKeyValueStore.default
        
        // MARK: - Initialization & Deinitialization
        private init() {
            // Add observer for changes in iCloud KVS
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(iCloudStoreDidChange(_:)),
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: iCloudStore
            )
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        // MARK: - Writing Values
        
        /// Sets the value for `oldUser` (Bool) in both local and iCloud stores.
        func setOldUser(_ value: Bool) {
            localStore.set(value, forKey: Keys.oldUser)
            if(localStore.bool(forKey: Keys.iCloudSync)) {
                iCloudStore.set(value, forKey: Keys.oldUser)
                iCloudStore.synchronize()
            }
        }
        
        /// Sets the value for `userName` (String) in both local and iCloud stores.
        func setUserName(_ value: String) {
            localStore.set(value, forKey: Keys.userName)
            if(localStore.bool(forKey: Keys.iCloudSync)) {
                iCloudStore.set(value, forKey: Keys.userName)
                iCloudStore.synchronize()
            }
        }
        
        /// Encodes and sets the `Interests` in both local and iCloud stores.
        func setInterests(_ interests: Interests) {
            do {
                let encoded = try JSONEncoder().encode(interests)
                localStore.set(encoded, forKey: Keys.interests)
                if(localStore.bool(forKey: Keys.iCloudSync)) {
                    iCloudStore.set(encoded, forKey: Keys.interests)
                    iCloudStore.synchronize()
                }
            } catch {
                print("Failed to encode and save interests: \(error)")
            }
        }
        
        /// Sets the value for `icloud_sync` (Bool) in both local and iCloud stores.
        func setICloudSync(_ value: Bool) {
            localStore.set(value, forKey: Keys.iCloudSync)
            iCloudStore.set(value, forKey: Keys.iCloudSync)
            iCloudStore.synchronize()
        }
        
        // MARK: - Reading Values
        
        /// Returns the Bool value for `oldUser`, with a fallback to local storage if iCloud does not have it.
        func getOldUser() -> Bool {
            if localStore.bool(forKey: Keys.iCloudSync) {
                return true
            } else if let iCloudValue = iCloudStore.object(forKey: Keys.oldUser) as? Bool {
                return iCloudValue
            } else {
                return false
            }
        }
        
        /// Returns the String value for `userName`, with a fallback to local storage if iCloud does not have it.
        func getUserName() -> String {
            if localStore.bool(forKey: Keys.iCloudSync), let iCloudValue = iCloudStore.object(forKey: Keys.userName) as? String {
                localStore.set(iCloudValue, forKey: Keys.userName)
                return iCloudValue
            }
            return localStore.string(forKey: Keys.userName) ?? ""
        }
        
        /// Decodes and returns the `Interests` struct, with a fallback to local storage if iCloud does not have it.
        func getInterests() -> Interests? {
            // Try iCloud first
            if localStore.bool(forKey: Keys.iCloudSync), let iCloudData = iCloudStore.object(forKey: Keys.interests) as? Data {
                do {
                    return try JSONDecoder().decode(Interests.self, from: iCloudData)
                } catch {
                    print("Failed to decode iCloud interests: \(error)")
                }
            }
            
            // Fallback: local
            if let localData = localStore.data(forKey: Keys.interests) {
                do {
                    return try JSONDecoder().decode(Interests.self, from: localData)
                } catch {
                    print("Failed to decode local interests: \(error)")
                }
            }
            
            return nil
        }
        
        /// Returns the Bool value for `icloud_sync`, with a fallback to local storage if iCloud does not have it.
        func getICloudSync() -> Bool {
            if let iCloudValue = iCloudStore.object(forKey: Keys.iCloudSync) as? Bool {
                return iCloudValue
            }
            return localStore.bool(forKey: Keys.iCloudSync)
        }
        
        // MARK: - Handling iCloud Changes
        
        /// Reacts to external changes coming from iCloud KVS and updates
        /// the local UserDefaults accordingly, ensuring both stores stay in sync.
        @objc private func iCloudStoreDidChange(_ notification: Notification) {
            guard let userInfo = notification.userInfo else { return }
            
            if let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] {
                for key in changedKeys {
                    switch key {
                    case Keys.oldUser:
                        let newValue = iCloudStore.object(forKey: key) as? Bool
                        localStore.set(newValue, forKey: key)
                        
                    case Keys.userName:
                        let newValue = iCloudStore.object(forKey: key) as? String
                        localStore.set(newValue, forKey: key)
                        
                    case Keys.interests:
                        if let newValue = iCloudStore.object(forKey: key) as? Data {
                            // Decode the data and store it locally
                            localStore.set(newValue, forKey: key)
                        } else {
                            // In case the key was removed, remove it locally as well
                            localStore.removeObject(forKey: key)
                        }
                        
                    case Keys.iCloudSync:
                        let newValue = iCloudStore.object(forKey: key) as? Bool
                        localStore.set(newValue, forKey: key)
                        
                    default:
                        break
                    }
                }
            }
        }
}
