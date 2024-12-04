//
//  OnboardingViewModel.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 12.11.24.
//

import Foundation
import CoreData
import SwiftUI

struct FirestoreCategory: Decodable {
    var id: Int
    var name: String
    var icon: String
    var maxCredits: Int
    var minCredits: Int
}

/// The `OnboardingViewModel` manages the onboarding flow.
/// It handles setting up default categories, courses, and semesters in Core Data, ensuring
/// the app is initialized with all required data when a user starts for the first time.
///
/// **Key Responsibilities:**
/// - Initializes categories, semesters, and courses based on predefined defaults.
/// - Manages the persistence of data in Core Data.
/// - Handles errors related to data fetching, saving, or invalid configurations during onboarding.
///
/// This implementation provides a seamless onboarding experience while supporting future integration
/// with Firebase for dynamic course data retrieval.
class OnboardingViewModel: ObservableObject {
    @Published var amountOfSemesters: Int = 6
    @Published var currentSemester: Int = 0
    let viewContext = PersistenceController.shared.container.viewContext
    
    enum DataError: Error {
        case fetchError(String)
        case saveError(String)
        case emptyData(String)
        case invalidIndex(String)
    }
    
    /// Sets up default categories, semesters, and courses in Core Data for onboarding.
    ///
    /// **Temporary Solution:** This method stores predefined courses locally from `AppConstants` instead of fetching them from Firebase.
    /// Firebase integration for fetching categories 0 and 1 was omitted due to issues encountered during app review.
    ///
    /// **Implementation Details:**
    /// - Deletes any pre-existing Core Data objects to reset the onboarding state.
    /// - Initializes categories and semesters from predefined constants.
    /// - Assigns courses to the appropriate categories and semesters based on their properties.
    /// - Saves all initialized data to Core Data.
    ///
    /// **Throws:**
    /// - `DataError.fetchError` if fetching existing Core Data objects fails.
    /// - `DataError.saveError` if saving initialized data to Core Data fails.
    /// - `DataError.invalidIndex` if an invalid index is encountered while assigning courses to categories or semesters.
    ///
    @MainActor
    func createDefaultCourses() async throws {
        
        // Delete all objects (for the case that the onboarding was already finished)
        let categoryFetchRequest: NSFetchRequest<NSFetchRequestResult> = Category.fetchRequest()
        var addedCategories = false
        do {
            let categories = try viewContext.fetch(categoryFetchRequest)
            if(categories.count == 8) {
                addedCategories = true
            }
        } catch {
            throw DataError.fetchError("Failed to fetch categories: \(error)")
        }
        
        
        if(!addedCategories) {
    
            var categories: [Category] = []
            for firestoreCategory in AppConstants.DefaultObjects.categories {
                let category = Category(context: viewContext)
                category.id = Int16(firestoreCategory.id)
                category.name = firestoreCategory.name
                category.icon = firestoreCategory.icon
                category.minCredits = Int16(firestoreCategory.minCredits)
                category.maxCredits = Int16(firestoreCategory.maxCredits)
                
                categories.append(category)
            }
            
            if categories.count == 0 {
                throw DataError.invalidIndex("No Categories found")
            }
            
            var semesters: [Semester] = []
            for index in 0..<amountOfSemesters {
                let semester = Semester(context: viewContext)
                semester.number = Int16(index)
                
                semesters.append(semester)
            }
            
            if semesters.count == 0 {
                throw DataError.invalidIndex("No Semesters found")
            }
            
            for firestoreCourse in AppConstants.DefaultObjects.courses {
                let course = Course(context: viewContext)
                course.name = firestoreCourse.name
                course.id = firestoreCourse.id
                course.credits = Int16(firestoreCourse.credits)
                course.isPassed = false
                course.rating = -1
                
                if firestoreCourse.category < categories.count {
                    course.category = categories[firestoreCourse.category]
                } else {
                    throw DataError.invalidIndex("Invalid index for category \(firestoreCourse.category) für Kurs \(firestoreCourse.name)")
                }
                
                course.vvz = firestoreCourse.vvz
                
                let hasOdd = firestoreCourse.semester.contains { $0 % 2 == 1 }
                if firestoreCourse.category == 0 {
                    course.semester = hasOdd ? semesters[0] : semesters[1]
                } else {
                    course.semester = hasOdd ? semesters[2] : semesters[3]
                }
            }
            
            do {
                try viewContext.save()
            } catch {
                throw DataError.saveError("Error while writing to Core Data: \(error.localizedDescription)")
            }
        }
    }
}

/// The `InterestsManager` handles the persistence of user-selected interests during the onboarding process.
/// It provides functionality to save, load, and clear interests stored in `UserDefaults`.
///
/// **Key Responsibilities:**
/// - Saves an array of interests as an encoded JSON object in `UserDefaults`.
/// - Decodes and retrieves the interests from `UserDefaults` when needed.
/// - Clears all stored interests, useful for resetting or reinitializing onboarding data.
class InterestsManager {
    private let userDefaultsKey = "interests"
    
    func saveInterests(_ interests: Interests) {
        do {
            let encoded = try JSONEncoder().encode(interests)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        } catch {
            print("Failed to save interests: \(error)")
        }
    }
    
    func loadInterests() -> Interests? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("No interests found in UserDefaults.")
            return nil
        }
        
        do {
            let interests = try JSONDecoder().decode(Interests.self, from: data)
            return interests
        } catch {
            print("Failed to decode interests: \(error)")
            return nil
        }
    }
    
    func clearInterests() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

struct Interests: Codable {
    let titles: [String]
}

