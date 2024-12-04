//
//  TemplateOverviewViewModel.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 13.11.24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class TemplateOverviewViewModel: ObservableObject {
    let cacheManager = FirestoreCacheManager()
    
    /// A set that stores liked templates locally to reduce the number of Firestore calls.
    /// - Purpose: This cache ensures that the app doesn't repeatedly fetch the same data when navigating
    ///   between `TemplateOverviewView` and `TemplateTopicOverviewView`, improving performance and reducing latency.
    /// - Note: Templates added to or removed from this set reflect the user's likes locally, minimizing the need for frequent Firestore queries.
    var likedTemplates: Set<Template> = Set<Template>()
    
    /// Checks if the current user has already liked the given template.
    /// - Parameter template: The `Template` object to check for a like.
    /// - Returns: A `Bool` indicating whether the user has liked the template.
    func hasLiked(template: Template) -> Bool {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User is not logged in.")
            return false
        }
        
        return (template.likes.contains(userID) || likedTemplates.contains(template))
    }
    
    /// Adds a like to the given template for the current user.
    /// - Parameter template: The `Template` object to add a like to.
    func addLike(template: Template) async -> Template? {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User is not logged in.")
            return nil
        }
        
        if(!template.likes.contains(userID)) {
            var modifiedTemplate = template
            let collectionRef = FirestoreAPI.shared.db.collection("templates")
            let documentRef = collectionRef.document(template.id.uuidString)
            
            do {
                try await documentRef.updateData([
                    "likes": FieldValue.arrayUnion([userID]),
                    "amountOfLikes": FieldValue.increment(Int64(1))
                ])
                
                likedTemplates.insert(template)
            } catch {
                print("Failed to add like: \(error.localizedDescription)")
            }
            
            modifiedTemplate.amountOfLikes += 1
            modifiedTemplate.likes.append(userID)
            
            return modifiedTemplate
        }
        
        return nil
    }
    
    /// Removes a like from the given template for the current user.
    /// - Parameter template: The `Template` object to remove a like from.
    func removeLike(template: Template) async -> Template? {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User is not logged in.")
            return nil
        }
        
        if(template.likes.contains(userID)) {
            var modifiedTemplate = template
            let collectionRef = FirestoreAPI.shared.db.collection("templates")
            let documentRef = collectionRef.document(template.id.uuidString)
            
            do {
                try await documentRef.updateData([
                    "likes": FieldValue.arrayRemove([userID]),
                    "amountOfLikes": FieldValue.increment(Int64(-1))
                ])
                
                likedTemplates.remove(template)
            } catch {
                print("Failed to remove like: \(error.localizedDescription)")
            }
            
            modifiedTemplate.amountOfLikes -= 1
            modifiedTemplate.likes.removeAll(where: { $0 == userID } )
            
            return modifiedTemplate
        }
        
        return nil
    }


    
    //// Fetches the courses corresponding to the course IDs stored in a template.
    /// - Parameter template: The `Template` containing course IDs organized by semester.
    /// - Returns: A nested array of `FirestoreCourse` objects, where each index corresponds to a semester.
    func fetchTemplateCourses(template: Template) async -> [[FirestoreCourse]] {
        let cachedCourses = cacheManager.loadCourses(with: template.courses.map { $0.courses.compactMap { $0 } })
        
        if(!cachedCourses.isEmpty) {
            if(cachedCourses.flatMap { $0 }.count == template.amountOfCourses) {
                print("Fetched Courses from Cache")
                return cachedCourses
            }
        }
        
        let addCourseViewModel = AddCourseViewModel()
        let courses = await addCourseViewModel.getCourses()
       
        let coursesDict = Dictionary(uniqueKeysWithValues: courses.map { ($0.id, $0) })
        
        let mappedCourses: [[FirestoreCourse]] = template.courses.map { semester in
            semester.courses.compactMap { coursesDict[$0] }
        }
        
        return mappedCourses
    }
}

