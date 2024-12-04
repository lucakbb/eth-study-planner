//
//  TopicOverviewViewModel.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 13.11.24.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// Amount of Semesters/Courses have to be saved since otherwise we can't filter/sort for it in Firebase
struct Template: Hashable, Decodable, Encodable {
    var id: UUID
    var title: String
    var shareCode: String
    
    var authorName: String
    var authorID: String
    
    var likes: [String]
    var amountOfLikes: Int
    
    var tags: [String]
    
    var courses: [TemplateSemester]
    var amountOfSemesters: Int
    var amountOfCourses: Int
}

struct TemplateSemester: Hashable, Decodable, Encodable {
    var courses: [String]
}

enum TemplateCategorie {
    case mostLikes
    case likedByUser
    case fewestCourses
    case mostCourses
}

class TopicOverviewViewModel: ObservableObject {
    var lastFetchedDocument: DocumentSnapshot? = nil
    
    /// Fetches templates from Firestore based on the provided topic.
    /// - Parameters:
    ///   - topic: A `TemplateLibraryTopic` value specifying the filtering criteria for templates.
    /// - Returns: A tuple containing:
    ///   - An array of `Template` objects matching the topic.
    ///   - A `Bool` indicating whether more templates are available for pagination.
    /// - Note:
    ///   - If the `topic` belongs to `AppConstants.TemplateTopics.topics`, templates are filtered by their tags using the topic's title.
    ///   - If the `topic` belongs to `AppConstants.TemplateTopics.semesters`, templates are filtered by the number of semesters, derived from the first character of the topic's title.
    ///   - Otherwise, templates are fetched based on the category `.mostLikes`.
    ///   - This function utilizes the respective `fetchTemplates` implementations to query the Firestore database.
    func fetchTemplates(topic: TemplateLibararyTopic) async -> ([Template], Bool) {
        if(AppConstants.TemplateTopics.topics.flatMap { $0 }.contains(topic)) {
            return await fetchTemplates(topicTitle: topic.title)
        } else if(AppConstants.TemplateTopics.semesters.contains(topic)) {
            return await fetchTemplates(amountOfSemesters: Int(topic.title.prefix(1)) ?? 0)
        } else {
            if(topic.title == "Most Liked") {
                return await fetchTemplates(categorie: .mostLikes)
            } else if(topic.title == "Fewest Courses") {
                return await fetchTemplates(categorie: .fewestCourses)
            } else if(topic.title == "Most Courses") {
                return await fetchTemplates(categorie: .mostCourses)
            } else {
                return await fetchTemplates(categorie: .likedByUser)
            }
        }
    }
    
    /// Fetches templates from Firestore based on a specific topic.
    /// - Parameters:
    ///   - topic: A `String` representing the topic used to filter templates by their tags.
    ///   - lastDocument: An optional `DocumentSnapshot` to enable pagination; templates after this document will be fetched.
    /// - Returns: A tuple containing:
    ///   - An array of `Template` objects sorted by the number of likes in descending order.
    ///   - A `Bool` indicating whether more templates are available for pagination.
    /// - Note: The function fetches a maximum of 16 documents per call. If more than 15 documents are returned, pagination is possible.
    func fetchTemplates(topicTitle: String) async -> ([Template], Bool) {
        let isLoggedIn = await FirestoreAPI.shared.ensureUserIsLoggedIn()
        
        guard isLoggedIn else {
            print("User could not be logged in.")
            return ([], false)
        }
        
        let collectionRef = FirestoreAPI.shared.db.collection("templates")
        
        do {
            var query = collectionRef
                .whereField("tags", arrayContains: topicTitle)
                .order(by: "amountOfLikes", descending: true)
                .limit(to: 16)

            if let lastDoc = lastFetchedDocument {
                query = query.start(afterDocument: lastDoc)
            }
            
            let snapshot = try await query.getDocuments()
            
            let hasMore = snapshot.documents.count > 15
            
            let templates: [Template] = try snapshot.documents.prefix(15).compactMap { document in
                try document.data(as: Template.self)
            }
            
            lastFetchedDocument = hasMore ? snapshot.documents[14] : nil
            
            return (templates, hasMore)
        } catch {
            print("Error fetching templates: \(error)")
            return ([], false)
        }
    }
 
    
    /// Fetches templates from Firestore based on the given amount of semesters.
    /// - Parameters:
    ///   - amountOfSemesters: An `Int` representing the number of semesters used to filter templates.
    /// - Returns: A tuple containing:
    ///   - An array of `Template` objects sorted by the number of likes in descending order.
    ///   - A `Bool` indicating whether more templates are available for pagination.
    /// - Note: The function fetches a maximum of 16 documents per call. If more than 15 documents are returned, pagination is possible.
    func fetchTemplates(amountOfSemesters: Int) async -> ([Template], Bool) {
        let isLoggedIn = await FirestoreAPI.shared.ensureUserIsLoggedIn()
        
        guard isLoggedIn else {
            print("User could not be logged in.")
            return ([], false)
        }
        
        let collectionRef = FirestoreAPI.shared.db.collection("templates")
        
        do {
            var query: Query
            
            if(amountOfSemesters != 8) {
                query = collectionRef
                    .whereField("amountOfSemesters", isEqualTo: amountOfSemesters)
                    .order(by: "amountOfLikes", descending: true)
                    .limit(to: 16)
            } else {
                query = collectionRef
                    .whereField("amountOfSemesters", isGreaterThanOrEqualTo: amountOfSemesters)
                    .order(by: "amountOfLikes", descending: true)
                    .limit(to: 16)
            }

            if let lastDoc = lastFetchedDocument {
                query = query.start(afterDocument: lastDoc)
            }
            
            let snapshot = try await query.getDocuments()
            
            let hasMore = snapshot.documents.count > 15
            
            let templates: [Template] = try snapshot.documents.prefix(15).compactMap { document in
                try document.data(as: Template.self)
            }
            
            lastFetchedDocument = hasMore ? snapshot.documents[14] : nil
            
            return (templates, hasMore)
        } catch {
            print("Error fetching templates: \(error)")
            return ([], false)
        }
    }

    
    /// Fetches templates from Firestore based on the given category.
    /// - Parameters:
    ///   - categorie: A `TemplateCategorie` enum value to specify the filtering criteria.
    /// - Returns: An array of `Template` objects sorted based on the category.
    /// - Note: The function fetches a maximum of 16 documents per call. If more than 15 documents are returned, pagination is possible.
    func fetchTemplates(categorie: TemplateCategorie) async -> ([Template], Bool) {
        let isLoggedIn = await FirestoreAPI.shared.ensureUserIsLoggedIn()
        
        guard isLoggedIn else {
            print("User could not be logged in.")
            return ([], false)
        }
        
        let collectionRef = FirestoreAPI.shared.db.collection("templates")
        
        do {
            var query: Query
            
            // Define the query based on the category
            switch categorie {
            case .mostLikes:
                query = collectionRef
                    .order(by: "amountOfLikes", descending: true)
                    .limit(to: 16)
            case .likedByUser:
                guard let userID = Auth.auth().currentUser?.uid else {
                    print("User is not logged in.")
                    return ([], false)
                }
                            
                query = collectionRef
                    .whereField("likes", arrayContains: userID)
                    .limit(to: 16)
            case .fewestCourses:
                query = collectionRef
                    .order(by: "amountOfCourses", descending: false)
                    .limit(to: 16)
            case .mostCourses:
                query = collectionRef
                    .order(by: "amountOfCourses", descending: true)
                    .limit(to: 16)
            }
            
            // Apply pagination if a last document exists
            if let lastDoc = lastFetchedDocument {
                query = query.start(afterDocument: lastDoc)
            }
            
            let snapshot = try await query.getDocuments()
            
            let hasMore = snapshot.documents.count > 15
            
            let templates: [Template] = try snapshot.documents.prefix(15).compactMap { document in
                try document.data(as: Template.self)
            }
            
            // Update the pagination reference
            lastFetchedDocument = hasMore ? snapshot.documents[14] : nil
            
            return (templates, hasMore)
        } catch {
            print("Error fetching templates: \(error)")
            return ([], false)
        }
    }
}
