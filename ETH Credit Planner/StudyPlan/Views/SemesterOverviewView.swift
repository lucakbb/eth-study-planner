//
//  SemesterOverviewView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 12.11.24.
//

import SwiftUI
import SimpleAnalytics

struct SemesterOverviewView: View {
    @FetchRequest var courses: FetchedResults<Course>
    
    @State var semester: Semester?
    @State var isAddCoursePopupShown: Bool = false
    
    init(semester: Semester?) {
        self.semester = semester
        self._courses = FetchRequest<Course>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Course.id, ascending: true)],
            predicate: semester != nil ? NSPredicate(format: "semester == %@", semester!) : nil
        )
    }
    
    var body: some View {
        NavigationStack {
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Courses")
                            .font(.system(size: 23, weight: .bold))
                        
                        if(courses.count > 0) {
                            courseList
                        } else {
                            NoCoursesFound()
                        }
                    }
                    
                    AddCourseButton(isAddCoursePopupShown: $isAddCoursePopupShown)
                }
                .padding(.horizontal, 16)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("\((semester?.number ?? 0) + 1). Semester")
        }
        .sheet(isPresented: $isAddCoursePopupShown) {
            if(semester != nil) {
                AddCourseView(isPresented: $isAddCoursePopupShown, semester: semester)
            }
        }
        .onAppear {
            SimpleAnalytics.shared.track(path: ["study-plan", "semester"])
        }
    }
    
    var courseList: some View {
        ForEach(courses, id: \.self) { course in
            NavigationLink {
                CourseOverviewView(course: course)
            } label: {
                ZStack {
                    Color(UIColor.secondarySystemGroupedBackground)
                    
                    HStack {
                        if(!course.isPassed) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 20, weight: .semibold))
                        } else {
                            Image(systemName: "medal.fill")
                                .font(.system(size: 20, weight: .semibold))
                        }
                        
                        Text(course.name ?? "")
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(Color(UIColor.label))
                            .font(.system(size: 20, weight: .semibold))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(UIColor.systemGray2))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
                .cornerRadius(10)
            }
        }
    }
}

#Preview {
    SemesterOverviewView(semester: nil)
}
