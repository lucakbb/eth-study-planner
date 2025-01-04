//
//  ImportCourseViewModel.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 16.11.24.
//

import Foundation
import SafariServices
import SwiftUI
import CoreData

class ImportCourseViewModel: ObservableObject {
    let viewContext = PersistenceController.shared.container.viewContext
    
    // Stores all courses associated with the currently selected semester that have the same ID as the specified course.
    // Used to check if the course is already part of the selected semester.
    @Published var matchingCoursesInSelectedSemester: [Course] = []
    
    func fetchMatchingCourses(semester: Semester, courseID: String) {
        let context = PersistenceController.shared.container.viewContext
        
        let mainID = courseID.split(separator: "&&").first.map(String.init) ?? courseID
        
        let fetchRequest: NSFetchRequest<Course> = Course.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Course.name, ascending: true)]
        fetchRequest.predicate = NSPredicate(
            format: "(semester.number == %d) AND (id == %@ OR id BEGINSWITH %@)",
            semester.number,
            mainID as CVarArg,
            mainID as CVarArg
        )
        
        do {
            matchingCoursesInSelectedSemester = try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch courses: \(error)")
            matchingCoursesInSelectedSemester = []
        }
    }
    
    func importCourse(firestoreCourse: FirestoreCourse, semester: Semester, category: Category) {
        let course = Course(context: viewContext)
        course.id = firestoreCourse.id
        course.name = firestoreCourse.name
        course.credits = Int16(firestoreCourse.credits)
        course.category = category
        course.semester = semester
        course.status = CourseStatus.planned.rawValue
        course.rating = -1
        course.vvz = firestoreCourse.vvz
        
        do {
            try viewContext.save()
        } catch {
            print(error)
        }
    }
    
    
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = .pageSheet
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
