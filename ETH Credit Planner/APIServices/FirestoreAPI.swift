//
//  FirestoreAPI.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 11.11.24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirestoreAPI: NSObject, ObservableObject {
    static let shared = FirestoreAPI()
    var authListener: AuthStateDidChangeListenerHandle?
    let db: Firestore
    
    override init() {
        db = Firestore.firestore()
    }
    
    func ensureUserIsLoggedIn() async -> Bool {
        await withCheckedContinuation { continuation in
            if Auth.auth().currentUser == nil {
                Auth.auth().signInAnonymously { authResult, error in
                    if let error = error {
                        print("Error when logging in anonymously: \(error)")
                        continuation.resume(returning: false)
                    } else {
                        continuation.resume(returning: true)
                    }
                }
            } else {
                continuation.resume(returning: true)
            }
        }
    }
}
