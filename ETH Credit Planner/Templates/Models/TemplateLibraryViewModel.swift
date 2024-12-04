//
//  TemplateLibraryViewModel.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 11.11.24.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct TemplateLibararyTopic: Hashable {
    var title: String!
    var icon: String!
    var color: Color!
}

class TemplateLibraryViewModel: ObservableObject {
    
    /// Fetches templates from Firestore where the `shareCode` matches the provided value.
    /// - Parameter shareCode: The `shareCode` to match in the Firestore query.
    /// - Returns: An array of `Template` objects with the matching `shareCode`.
    /// - Behavior:
    ///   - Ensures the user is logged in before executing the query.
    ///   - Queries the "templates" collection in Firestore to fetch documents where `shareCode` matches the provided value.
    ///   - Maps the retrieved documents to `Template` objects.
    func getTemplatesByShareCode(shareCode: String) async -> [Template] {
        // Ensure the user is logged in
        let isLoggedIn = await FirestoreAPI.shared.ensureUserIsLoggedIn()
        
        guard isLoggedIn else {
            print("User is not logged in.")
            return []
        }
        
        let collectionRef = FirestoreAPI.shared.db.collection("templates")
        
        do {
            // Query Firestore where `shareCode` matches the provided value
            let query = collectionRef.whereField("shareCode", isEqualTo: shareCode)
            let snapshot = try await query.getDocuments()
            
            // Map the documents to Template objects
            let templates: [Template] = try snapshot.documents.compactMap { document in
                try document.data(as: Template.self)
            }
            
            return templates
        } catch {
            print("Error fetching templates by shareCode: \(error)")
            return []
        }
    }
    
    /// Fetches the 10 most liked  templates from Firestore.
    /// - Returns: An array of `Template` objects sorted based on the amount of likes.
    func fetchMostLikedTemplates() async -> [Template] {
        
        let isLoggedIn = await FirestoreAPI.shared.ensureUserIsLoggedIn()
        
        guard isLoggedIn else {
            print("User could not be logged in.")
            return []
        }
        
        let collectionRef = FirestoreAPI.shared.db.collection("templates")
        
        do {
            var query: Query
            
            query = collectionRef
                .order(by: "amountOfLikes", descending: true)
                .limit(to: 10)
            
            let snapshot = try await query.getDocuments()
           
            
            let templates: [Template] = try snapshot.documents.compactMap { document in
                try document.data(as: Template.self)
            }
            
            return templates
        } catch {
            print("Error fetching templates: \(error)")
            return []
        }
    }
}
