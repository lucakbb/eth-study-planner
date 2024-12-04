//
//  AddCustomCourseViewModel.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 20.11.24.
//

import Foundation

class AddCustomCourseViewModel: ObservableObject {
    let viewContext = PersistenceController.shared.container.viewContext
    
    @Published var title: String = ""
    @Published var credits: Int = 1
    @Published var selectedCategory: Category? = nil
    @Published var selectedSemester: Semester? = nil
    
    func saveCourse() {
        let course = Course(context: viewContext)
        course.name = title
        course.credits = Int16(credits)
        course.category = selectedCategory
        course.semester = selectedSemester
        course.rating = -1
        course.vvz = ""
        course.id = ""
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save custom course: \(error)")
        }
    }
}
