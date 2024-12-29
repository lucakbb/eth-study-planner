//
//  ChangelogViewModel.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 29.12.24.
//

import Foundation
import CoreData

enum CourseStatus: String {
    case planned = "planned"
    case passed = "passed"
    case failed = "failed"
}

class ChangelogViewModel: ObservableObject {
    let context = PersistenceController.shared.container.viewContext
    @Published var isLoading = false
    
    @MainActor
    func migrateCourseStatus() {
        isLoading = true
        let fetchRequest: NSFetchRequest<Course> = Course.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "status == nil OR status == ''")
        
        do {
            let courses = try context.fetch(fetchRequest)
            for course in courses {
                if course.isPassed {
                    course.status = CourseStatus.passed.rawValue
                } else {
                    course.status = CourseStatus.planned.rawValue
                }
            }
            try context.save()
            isLoading = false
        } catch {
            print("Migration failed: \(error)")
            isLoading = false
        }
    }
    
    @MainActor
    func updateErgaenzungMaxCredits() {
        let viewContext = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == 3")
        
        do {
            let categories = try viewContext.fetch(fetchRequest)
            
            if(categories.count == 1) {
                let category = categories[0]
                category.maxCredits = 10
                
                try viewContext.save()
            }
        } catch {
            print("error: \(error)")
        }
    }
}
