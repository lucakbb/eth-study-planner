//
//  AppCheckManager.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 23.11.24.
//

import Foundation
import Firebase
import FirebaseAppCheck

class AppCheckManager: NSObject, AppCheckProviderFactory {
  func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
    return AppAttestProvider(app: app)
  }
}
