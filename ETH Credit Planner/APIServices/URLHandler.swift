//
//  URLHandler.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 28.12.24.
//

import Foundation

class URLHandler {
    static let shared = URLHandler()
    
    /// Handles an incoming URL to extract and fetch a template based on its ID.
    /// 
    /// This method supports both Universal Links (with the `https` scheme) and custom Deep Links (with the `eth-studyplanner` scheme).
    /// It validates the URL's scheme and host, extracts the query parameters to identify the template ID, and fetches the template asynchronously.
    ///
    /// - Parameter url: The incoming URL to handle, which may represent a Universal Link or a Deep Link.
    /// - Returns: A `Template` object if the template is successfully fetched; otherwise, `nil`.
    ///
    /// ### Supported URL formats:
    /// 1. **Universal Links**:
    ///    - Example: `https://share.studyplanner.ch?template-id=1234`
    ///    - Host must be `share.studyplanner.ch`.
    /// 2. **Deep Links**:
    ///    - Example: `eth-studyplanner://open-template?id=1234`
    ///    - No specific host validation is performed for Deep Links.
    ///
    /// ### Behavior:
    /// - Validates the scheme (`https` or `eth-studyplanner`) and ensures the host is valid for Universal Links.
    /// - Extracts the `template-id` or `id` query parameter from the URL.
    /// - Fetches the corresponding template asynchronously if the ID is successfully resolved.
    ///
    /// ### Notes:
    /// - This method uses asynchronous operations to fetch the template.
    /// - If the template ID is missing or invalid, the method logs an error and returns `nil`.
    func handleIncomingURL(_ url: URL) async -> Template? {
        var templateID: String?
        
        // Check the scheme and host
        if url.scheme == "https" {
            // Handle Universal Links
            guard url.host == "share.studyplanner.ch" else {
                print("Invalid host for Universal Link")
                return nil
            }
        } else if url.scheme == "eth-studyplanner" {
            // Handle Deep Links
            // No specific host validation for eth-studyplanner
        } else {
            print("Unsupported URL scheme")
            return nil
        }
        
        // Extract URL components
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("Invalid URL components")
            return nil
        }
        
        // Check query parameters for the template ID
        if let id = components.queryItems?.first(where: { $0.name == "id" })?.value {
            templateID = id
        } else if let id = components.queryItems?.first(where: { $0.name == "template-id" })?.value {
            templateID = id
        } else {
            print("Template ID not found")
            return nil
        }
        
        guard let id = templateID else {
            print("Template ID could not be resolved")
            return nil
        }
        
        // Fetch the template with the resolved template ID
        print("Fetching template with id: \(id)")
        if let template = await fetchTemplate(id: id) {
            print("Successfully fetched template: \(template)")
            return template
        }
        
        return nil
    }

    /// Fetches a `Template` object from Firestore using the provided ID.
    ///
    /// This method ensures that the user is logged in before querying the Firestore database.
    /// It searches the "templates" collection for a document matching the given `id` (mapped to the `shareCode` field)
    /// and decodes the resulting document into a `Template` object.
    ///
    /// - Parameter id: The identifier used to query the `shareCode` field in Firestore.
    /// - Returns: A `Template` object if a matching document is found and successfully decoded; otherwise, `nil`.
    ///
    /// ### Behavior:
    /// - Ensures the user is authenticated via Firestore's `ensureUserIsLoggedIn` method.
    /// - Queries Firestore for a document in the "templates" collection where the `shareCode` matches the provided ID.
    /// - Decodes the document into a `Template` object if it exists and is valid.
    func fetchTemplate(id: String) async -> Template? {
        let isLoggedIn = await FirestoreAPI.shared.ensureUserIsLoggedIn()
        
        guard isLoggedIn else {
            print("User could not be logged in.")
            return nil
        }
        
        let collectionRef = FirestoreAPI.shared.db.collection("templates")
        
        do {
            let query = collectionRef.whereField("shareCode", isEqualTo: id)
            let snapshot = try await query.getDocuments()
            
            guard let document = snapshot.documents.first else {
                print("No template found with the given ID.")
                return nil
            }
            
            if let template = try? document.data(as: Template.self) {
                return template
            } else {
                print("Failed to decode template.")
                return nil
            }
        } catch {
            print("Error fetching templates: \(error)")
        }
        
        return nil
    }
}
