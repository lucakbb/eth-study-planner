//
//  CreateTemplateViewModel.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 13.11.24.
//

import Foundation
import FirebaseAuth
import CoreData

class CreateTemplateViewModel: ObservableObject {
    let viewContext = PersistenceController.shared.container.viewContext
    
    @Published var courses: [[FirestoreCourse]]
    
    init(courses: [[FirestoreCourse]]) {
        if(courses.count == 0) {
            self.courses = [[], [], [], [], [], []]
        } else {
            self.courses = courses
        }
    }
  
    var checkGraduationRequirements: (Bool, IdentifiableString) {
        let courseArray = courses.flatMap({$0})
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Category.id, ascending: true)]
        
        do {
            let categories = try viewContext.fetch(fetchRequest)
            var creditsByCategory = Dictionary(uniqueKeysWithValues: categories.map { ($0, 0) })
            
            courseArray.forEach { course in
                creditsByCategory[categories[course.category], default: 0] += Int(course.credits)
            }
            
            // Condition 1: fulfil the minimum number of credits in each category
            for (category, credits) in creditsByCategory {
                if credits < category.minCredits {
                    return (false, IdentifiableString(value: "Your are missing credits in the category \(category.name ?? "")"))
                }
            }
            
            let basicAndCoreCredits = courseArray.filter { $0.category == 1 || $0.category == 2 }
                                             .reduce(0) { $0 + Int($1.credits) }
            let electiveCredits = courseArray.filter { $0.category == 4 }
                                         .reduce(0) { $0 + Int($1.credits) }
            
            
            // Condition 2: Basic + Core at least 84 credits
            if basicAndCoreCredits < 84 {
                return (false, IdentifiableString(value: "Your currently have \(basicAndCoreCredits) credits for the categories Grundlagenfächer & Kernfächer. However, you need at least 84."))
            }
            
            // Condition 3: Fundamentals + Core + Elective at least 96 credits
            if (basicAndCoreCredits + electiveCredits) < 96 {
                return (false, IdentifiableString(value: "Your currently have \(basicAndCoreCredits + electiveCredits) credits for the categories Grundlagenfächer, Kernfächer & Wahlfächer. However, you need at least 96."))
            }
            
            // Condition 4: A total of at least 180 credits
            var totalCredits = 0
            categories.forEach { category in
                totalCredits += min(creditsByCategory[category] ?? 0, Int(category.maxCredits))
            }
            
            if totalCredits < 180 {
                return (false, IdentifiableString(value: "Your currently have \(totalCredits) credits in total. However, you need at least 180."))
            }
            
            return (true, IdentifiableString(value: nil))
        } catch {
            print("Failed to fetch courses: \(error.localizedDescription)")
            return (false, IdentifiableString(value: ""))
        }
    }
    
    /// Uploads a new template to Firestore.
    /// - Parameters:
    ///   - title: A `String` representing the title of the template.
    ///   - selectedTags: An array of `String` containing tags associated with the template.
    /// - Note: The function constructs a `Template` object using the provided title, selected tags, and user-related information such as username and user ID.
    ///         The template also includes a list of course IDs organized into semesters.
    func uploadTemplate(title: String, selectedTags: [String]) async {
        let templateSemesters = courses.map { row in
            TemplateSemester(courses: row.map { course in
                course.id
            })
        }
        
        let isLoggedIn = await FirestoreAPI.shared.ensureUserIsLoggedIn()
           
        guard isLoggedIn else {
            print("User could not be logged in.")
            return
        }
        
        let template = Template(id: UUID(), title: title, shareCode: createShareCode(), authorName: UserDefaults.standard.string(forKey: "userName") ?? "", authorID: Auth.auth().currentUser?.uid ?? "", likes: [], amountOfLikes: 0, tags: Array(selectedTags), courses: templateSemesters, amountOfSemesters: templateSemesters.count, amountOfCourses: courses.flatMap { $0 }.count)
        
        let collectionRef = FirestoreAPI.shared.db.collection("templates")
        
        do {
            try collectionRef.document(template.id.uuidString).setData(from: template)
            print("Template uploaded successfully.")
        } catch {
            print("Failed to upload template: \(error.localizedDescription)")
        }
    }
    
    func createShareCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomCode = ""

        for _ in 0..<5 {
            if let randomCharacter = characters.randomElement() {
                randomCode.append(randomCharacter)
            }
        }
        
        return randomCode
    }
}
