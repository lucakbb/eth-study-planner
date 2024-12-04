//
//  TemplateImportCourseView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 17.11.24.
//

import SwiftUI
import SafariServices

struct TemplateImportCourseView: View {
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.id, ascending: true)]
    ) var categories: FetchedResults<Category>
    
    @State var course: FirestoreCourse
    @State var selectedSemester: Int
    
    @Binding var templateCourses: [[FirestoreCourse]]
    
    @State var isReviewsSheetShown: Bool = false
    @State var isVVZSheetShown: Bool = false
    @State var filteredSemesters: [Int] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        links
                        
                        general
                        
                    }
                    .padding(.horizontal, 16)
                }
                .navigationTitle("Course Overview")
                
                if(findIndex(of: course, in: templateCourses) == nil) {
                    Menu {
                        ForEach(filteredSemesters, id: \.self) { semester in
                            Button {
                                selectedSemester = semester
                            } label: {
                                Text("\(semester + 1). Semester")
                            }
                        }
                    } label: {
                        Text("Change Semester")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color("Color3"))
                    }
                    .padding(.bottom, 5)
                }
                
                ZStack {
                    if let index = findIndex(of: course, in: templateCourses) {
                        Color(UIColor.secondarySystemGroupedBackground)
                        Text("Already added to \(index + 1). Semester")
                            .font(.system(size: 20, weight: .semibold))
                    } else {
                        Color("Color1")
                        Text("Add to \(selectedSemester + 1). Semester")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(height: 54)
                .cornerRadius(15)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .onTapGesture {
                    if(findIndex(of: course, in: templateCourses) == nil) {
                        templateCourses[selectedSemester].append(course)
                        dismiss()
                    }
                }
            }
            .onAppear {
                let hasEven = course.semester.contains { $0 % 2 == 0 }
                let hasOdd = course.semester.contains { $0 % 2 == 1 }

                if hasEven && hasOdd {
                    // HS and FS
                    filteredSemesters = Array(0..<templateCourses.count)
                } else if hasEven {
                    // Only FS course
                    filteredSemesters = Array(0..<templateCourses.count).filter { $0 % 2 == 1 }
                } else if hasOdd {
                    // Only HS course
                    filteredSemesters = Array(0..<templateCourses.count).filter { $0 % 2 == 0 }
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    var links: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Links")
                .font(.system(size: 20, weight: .bold))
            
            HStack {
                ZStack {
                    Color(UIColor.secondarySystemGroupedBackground)
                    
                    HStack {
                        ZStack {
                            Color("Color1")
                            Image(systemName: "doc.text.fill")
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .frame(width: 27, height: 27)
                        .cornerRadius(5)
                        
                        
                        Text("VVZ")
                            .fontWeight(.semibold)
                            .font(.system(size: 20))
                        
                        Spacer()
                        
                    }
                    .padding(10)
                }
                .cornerRadius(10)
                .onTapGesture {
                    isVVZSheetShown = true
                }
                .sheet(isPresented: $isVVZSheetShown) {
                    if let url = URL(string: (course.vvz)) {
                        SafariView(url: url)
                    }
                }
                
                ZStack {
                    Color(UIColor.secondarySystemGroupedBackground)
                    
                    HStack {
                        ZStack {
                            Color(UIColor.systemYellow)
                            Image(systemName: "star.fill")
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .frame(width: 27, height: 27)
                        .cornerRadius(5)
                        
                        
                        Text("Reviews")
                            .fontWeight(.semibold)
                            .font(.system(size: 20))
                        
                        Spacer()
                        
                    }
                    .padding(10)
                }
                .cornerRadius(10)
                .onTapGesture {
                    isReviewsSheetShown = true
                }
                .sheet(isPresented: $isReviewsSheetShown) {
                    if let url = URL(string: "https://n.ethz.ch/~lteufelbe/coursereview/?course=\(course.id)") {
                        SafariView(url: url)
                    }
                }
            }
        }
    }
    
    var general: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("General")
                .font(.system(size: 20, weight: .bold))
                .padding(.bottom, -5)
            
            ZStack {
                Color(UIColor.secondarySystemGroupedBackground)
                
                VStack {
                    HStack {
                        ZStack {
                            Color("Color1")
                            Image(systemName: "doc.text.fill")
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .frame(width: 27, height: 27)
                        .cornerRadius(5)
                        
                        
                        Text("Information")
                            .fontWeight(.semibold)
                            .font(.system(size: 20))
                        
                        Spacer()
                        
                    }
                    .padding(10)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(course.name)
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.vertical, 7)
                            .padding(.leading, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemGroupedBackground))
                            .cornerRadius(10)
                        
                        Text(categories[course.category].name ?? "")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.vertical, 7)
                            .padding(.leading, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemGroupedBackground))
                            .cornerRadius(10)
                        
                        Text("\(course.credits) ECTS")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.vertical, 7)
                            .padding(.leading, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemGroupedBackground))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                }
            }
            .cornerRadius(10)
        }
    }
    
    func findIndex(of course: FirestoreCourse, in arrays: [[FirestoreCourse]]) -> Int? {
        for (index, subArray) in arrays.enumerated() {
            if subArray.contains(where: { $0.id == course.id }) {
                return index
            }
        }
        return nil
    }
}
