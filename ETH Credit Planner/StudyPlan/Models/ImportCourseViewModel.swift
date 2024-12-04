//
//  ImportCourseViewModel.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 16.11.24.
//

import Foundation
import SafariServices
import SwiftUI

class ImportCourseViewModel: ObservableObject {
    let viewContext = PersistenceController.shared.container.viewContext
    
    func importCourse(firestoreCourse: FirestoreCourse, semester: Semester, category: Category) {
        let course = Course(context: viewContext)
        course.id = firestoreCourse.id
        course.name = firestoreCourse.name
        course.credits = Int16(firestoreCourse.credits)
        course.category = category
        course.semester = semester
        course.isPassed = false
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
