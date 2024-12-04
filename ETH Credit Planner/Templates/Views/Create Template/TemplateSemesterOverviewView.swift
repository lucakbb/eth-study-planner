//
//  TemplateSemesterOverviewView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 14.11.24.
//

import SwiftUI

struct TemplateSemesterOverviewView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var courses: [[FirestoreCourse]]
    @State var semesterNumber: Int
    @State var isEditing: Bool
    @State var semesterTitle: String?
    
    @State var isAddCoursePopupShown: Bool = false
    
    @FetchRequest(
        entity: Semester.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Semester.number, ascending: true)]
    ) var semesters: FetchedResults<Semester>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Courses")
                            .font(.system(size: 23, weight: .bold))
                        
                        if(courses.count > semesterNumber && courses[semesterNumber].count > 0) {
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
            .navigationTitle(semesterTitle != nil ? semesterTitle! : "\(semesterNumber + 1). Semester")
            .toolbar {
                if(isEditing) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color(UIColor.systemRed))
                        .onTapGesture {
                            presentationMode.wrappedValue.dismiss()
                            
                            courses.remove(at: semesterNumber)
                        }
                }
            }
        }
        .sheet(isPresented: $isAddCoursePopupShown) {
            TemplateAddCourseView(isPresented: $isAddCoursePopupShown, semester: semesterNumber, templateCourses: $courses)
        }
    }
    
    var courseList: some View {
        ForEach(courses[semesterNumber], id: \.self) { course in
            if(isEditing) {
                courseRowContent(course: course)
            } else {
                NavigationLink {
                    if(semesterTitle != nil) {
                        if let firstChar = semesterTitle!.first, let semesterIndex = firstChar.wholeNumberValue {
                            if(semesters.count > (semesterIndex - 1)) {
                                ImportCourseView(course: course, semester: semesters[semesterIndex - 1])
                            }
                        }
                    } else if(semesters.count > semesterNumber) {
                        ImportCourseView(course: course, semester: semesters[semesterNumber])
                    } else {
                        ImportCourseView(course: course)
                    }
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
                            if let index = courses[semesterNumber].firstIndex(of: course) {
                                courses[semesterNumber].remove(at: index)
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
    TemplateSemesterOverviewView(courses: .constant([]), semesterNumber: 0, isEditing: true, semesterTitle: nil)
}
