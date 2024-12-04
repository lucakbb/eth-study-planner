//
//  UploadedTemplateViewModel.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 13.11.24.
//

import Foundation
import FirebaseAuth
import CoreData

class UploadedTemplateViewModel: ObservableObject {
    let viewContext = PersistenceController.shared.container.viewContext
    
    /// Fetches all templates created by the current user.
    /// - Returns: An array of `Template` objects authored by the logged-in user.
    /// - Behavior:
    ///   - Ensures the user is logged in and retrieves their UID.
    ///   - Queries the "templates" collection in Firestore to fetch documents where `authorID` matches the user's UID.
    ///   - Maps the retrieved documents to `Template` objects.
    func getUserTemplates() async -> [Template] {
        
        let isLoggedIn = await FirestoreAPI.shared.ensureUserIsLoggedIn()
        
        guard isLoggedIn, let userID = Auth.auth().currentUser?.uid else {
            print("User is not logged in or UID could not be retrieved.")
            return []
        }
        
        let collectionRef = FirestoreAPI.shared.db.collection("templates")
        
        do {
            let query = collectionRef.whereField("authorID", isEqualTo: userID)
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

    /// Deletes the given template from Firestore.
    /// - Parameter template: The `Template` object to be deleted.
    /// - Behavior:
    ///   - Identifies the document in the "templates" collection using the template's ID.
    ///   - Attempts to delete the document from Firestore.
    func deleteTemplate(template: Template) async {
        let isLoggedIn = await FirestoreAPI.shared.ensureUserIsLoggedIn()
        
        guard isLoggedIn else {
            print("User could not be logged in.")
            return
        }
        
        let collectionRef = FirestoreAPI.shared.db.collection("templates")
        let documentRef = collectionRef.document(template.id.uuidString)
        
        do {
            try await documentRef.delete()
        } catch {
            print("Error deleting template: \(error)")
        }
    }
    
    /// Fetches all Course entities from Core Data with a non-empty ID, converts them to FirestoreCourse models,
    /// and organizes them into a nested array.
    /// Each subarray corresponds to a specific semester, where the first subarray contains courses
    /// from the first semester, the second subarray contains courses from the second semester, and so on.
    ///
    /// - Parameter context: The managed object context used to fetch the data.
    /// - Returns: A nested array of FirestoreCourse objects, grouped by their associated Semester.
    ///            Each subarray represents one semester, sorted by the semester's number.
    func fetchCoursesOrganizedBySemester() -> [[FirestoreCourse]] {
        // Fetch all courses from Core Data
        let fetchRequest: NSFetchRequest<Course> = Course.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id != ''")
        
        do {
            let courses = try viewContext.fetch(fetchRequest)
            
            // Group courses by semester
            var semesterDict: [Int: [FirestoreCourse]] = [:]
            var maxSemester = 0 // Track the highest semester number
            
            for course in courses {
                guard let id = course.id,
                      let name = course.name,
                      let vvz = course.vvz,
                      let semester = course.semester?.number else {
                    continue
                }
                
                let firestoreCourse = FirestoreCourse(
                    id: id,
                    category: Int(course.category?.id ?? 0),
                    credits: Int(course.credits),
                    name: name,
                    semester: [Int(semester)],
                    tags: [],
                    vvz: vvz
                )
                
                let semesterInt = Int(semester)
                maxSemester = max(maxSemester, semesterInt)
                
                if semesterDict[semesterInt] == nil {
                    semesterDict[semesterInt] = []
                }
                
                semesterDict[semesterInt]?.append(firestoreCourse)
            }
            
            // Create a result array with empty arrays for all semesters up to maxSemester
            var result: [[FirestoreCourse]] = Array(repeating: [], count: maxSemester + 1)
            
            for (semester, coursesInSemester) in semesterDict {
                result[semester] = coursesInSemester
            }
            
            return result
        } catch {
            print("Error fetching courses: \(error)")
            return []
        }
    }

}
