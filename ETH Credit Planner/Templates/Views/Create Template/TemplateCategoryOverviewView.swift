//
//  TemplateCategoryOverviewView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 14.11.24.
//

import SwiftUI
import CoreData

struct TemplateCategoryOverviewView: View {
    @Binding var courses: [[FirestoreCourse]]
    @State var category: Category
    @State var isAddCoursePopupShown: Bool = false
    @State var isEditing: Bool

    var filteredCourses: [FirestoreCourse] {
        let courseArray = courses.flatMap { $0 }
        return courseArray.filter { $0.category == category.id}
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Courses")
                            .font(.system(size: 20, weight: .bold))
                        
                        if(filteredCourses.count > 0) {
                            courseList
                        } else {
                            NoCoursesFound()
                        }
                    }
                    
                    if(isEditing) {
                        AddCourseButton(isAddCoursePopupShown: $isAddCoursePopupShown)
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(category.name ?? "")
        }
        .sheet(isPresented: $isAddCoursePopupShown) {
            TemplateAddCourseView(isPresented: $isAddCoursePopupShown, semester: 0, templateCourses: $courses)
        }
    }
    
    var courseList: some View {
        ForEach(filteredCourses, id: \.self) { course in
            if(isEditing) {
                courseRowContent(course: course)
            } else {
                NavigationLink {
                    ImportCourseView(course: course)
                } label: {
                    courseRowContent(course: course)
                }
            }
        }
    }
    
    func courseRowContent(course: FirestoreCourse!) -> some View {
        ZStack {
            Color(UIColor.secondarySystemGroupedBackground)
            
            HStack {
                Text(course.name)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(Color(UIColor.label))
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                if(isEditing) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(UIColor.systemRed))
                        .onTapGesture {
                            for (index, subArray) in courses.enumerated() {
                                courses[index] = subArray.filter { $0.id != course.id }
                            }
                        }
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(UIColor.systemGray2))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .cornerRadius(10)
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let viewModel = OnboardingViewModel()
    let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
    
    do {
        if try context.count(for: fetchRequest) == 0 {
            Task {
                try await viewModel.createDefaultCourses()
            }
        }
    } catch {
        print("Error checking or creating default courses: \(error)")
    }
    
    if let category = try? context.fetch(fetchRequest).first {
        return TemplateCategoryOverviewView(courses: .constant([]), category: category, isEditing: true)
            .environment(\.managedObjectContext, context)
    } else {
        return Text("No categories found")
    }
}


