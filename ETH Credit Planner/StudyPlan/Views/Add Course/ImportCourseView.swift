//
//  ImportCourseView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 16.11.24.
//

import SwiftUI
import SimpleAnalytics

struct ImportCourseView: View {
    let viewContext = PersistenceController.shared.container.viewContext
    @ObservedObject var viewModel: ImportCourseViewModel = ImportCourseViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        entity: Course.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Course.id, ascending: true)]
    ) var courses: FetchedResults<Course>
    
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.id, ascending: true)]
    ) var categories: FetchedResults<Category>
    
    @FetchRequest(
        entity: Semester.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Semester.number, ascending: true)]
    ) var semesters: FetchedResults<Semester>
    
    @FetchRequest var fetchedCourse: FetchedResults<Course>
    
    @State var course: FirestoreCourse?
    @State var selectedSemester: Semester?
    @State var filteredSemesters: [Semester] = []
    @State var isReviewsSheetShown: Bool = false
    @State var isVVZSheetShown: Bool = false
    
    init(course: FirestoreCourse?, semester: Semester?) {
        self.course = course
        self.selectedSemester = semester
        
        self._fetchedCourse = FetchRequest<Course>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Course.name, ascending: true)],
            predicate: NSPredicate(format: "id == %@", course?.id ?? "-1")
        )
    }
    
    init(course: FirestoreCourse?) {
        self.course = course
        self.selectedSemester = nil
        
        self._fetchedCourse = FetchRequest<Course>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Course.name, ascending: true)],
            predicate: NSPredicate(format: "id == %@", course?.id ?? "-1")
        )
    }
    
    var body: some View {
        if(categories.count > 0) {
            NavigationStack {
                VStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 25) {
                            let categoryCourses = courses.filter { $0.category?.id ?? -1 == course?.category ?? -2 }
                            let credits = categoryCourses.reduce(0) { $0 + Int($1.credits)}
                            let maxCredits = categories[course?.category ?? 0].maxCredits
                            
                            if(credits >= maxCredits || fetchedCourse.count > 0) {
                                VStack(alignment: .leading, spacing: 5) {
                                    if(credits >= maxCredits) {
                                        maxCreditsWarning
                                    }
                                    
                                    if(fetchedCourse.count > 0) {
                                        alreadyAddedWarning
                                    }
                                }
                            }
                            
                            links
                            
                            general
                            
                        }
                        .padding(.horizontal, 16)
                    }
                    .navigationTitle("Course Overview")
                    
                    if(fetchedCourse.count == 0) {
                        Menu {
                            ForEach(filteredSemesters, id: \.self) { semester in
                                Button {
                                    selectedSemester = semester
                                } label: {
                                    Text("\(semester.number + 1). Semester")
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
                        if(fetchedCourse.count > 0) {
                            Color(UIColor.secondarySystemGroupedBackground)
                            Text("Already added to \(((fetchedCourse[0].semester?.number ?? 0) + 1)). Semester")
                                .font(.system(size: 20, weight: .semibold))
                        } else {
                            Color("Color1")
                            Text("Add to \((selectedSemester?.number ?? -1) + 1). Semester")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(height: 54)
                    .cornerRadius(15)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .onTapGesture {
                        if(fetchedCourse.count == 0) {
                            if let selectedCourse = course, let semester = selectedSemester {
                                SimpleAnalytics.shared.track(event: "added course")
                                
                                viewModel.importCourse(firestoreCourse: selectedCourse, semester: semester, category: categories[course?.category ?? 0])
                                dismiss()
                            }
                        }
                    }
                    .onAppear {
                        // Set Default Semester
                        if let semester = selectedSemester {
                            
                            let isHSSemester = (semester.number % 2 == 0)
                            if let semestersArray = course?.semester {
                                if(isHSSemester) {
                                    self.selectedSemester = semestersArray.contains{ $0 % 2 == 1 } ? semester : semesters[1]
                                } else {
                                    self.selectedSemester = semestersArray.contains{ $0 % 2 == 0 } ? semester : semesters[0]
                                }
                            } else {
                                self.selectedSemester = semester
                            }
                            
                        } else {
                            selectedSemester = (course?.semester.first ?? 0) % 2 == 1 ? semesters[0] : semesters[1]
                        }
                        
                        // Set the Semesters, the course can be added to
                        if let semestersArray = course?.semester {
                            let hasEven = semestersArray.contains { $0 % 2 == 0 }
                            let hasOdd = semestersArray.contains { $0 % 2 == 1 }
                            
                            if hasEven && hasOdd {
                                // HS and FS
                                filteredSemesters = Array(semesters)
                            } else if hasEven {
                                // Only HS course
                                filteredSemesters = semesters.filter { $0.number % 2 == 1 }
                            } else if hasOdd {
                                // Only FS course
                                filteredSemesters = semesters.filter { $0.number % 2 == 0 }
                            } else {
                                // Fallback
                                filteredSemesters = []
                            }
                        }
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
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
                    if let url = URL(string: (course?.vvz ?? "")) {
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
                    if let url = URL(string: "https://n.ethz.ch/~lteufelbe/coursereview/?course=\(course?.id ?? "")") {
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
                        Text(course?.name ?? "")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.vertical, 7)
                            .padding(.leading, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemGroupedBackground))
                            .cornerRadius(10)
                        
                        Text(categories[course?.category ?? 0].name ?? "")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.vertical, 7)
                            .padding(.leading, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemGroupedBackground))
                            .cornerRadius(10)
                        
                        Text("\(course?.credits ?? 0) ECTS")
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
            
            ZStack {
                Color(UIColor.secondarySystemGroupedBackground)
                
                VStack(alignment: .leading) {
                    HStack {
                        ZStack {
                            Color("Color1")
                            Image(systemName: "tag.fill")
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .frame(width: 27, height: 27)
                        .cornerRadius(5)
                        
                        
                        Text("Tags")
                            .fontWeight(.semibold)
                            .font(.system(size: 20))
                        
                        Spacer()
                        
                    }
                    .padding(10)
                    
                    TagsCloud(tags: course?.tags ?? [])
                        .padding(.horizontal, 10)
                        .padding(.bottom, 15)
                }
            }
            .cornerRadius(10)
        }
    }
    
    var alreadyAddedWarning: some View {
        ZStack {
            Color(UIColor.systemRed)
            
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 25, weight: .semibold))
                Text("You have already the course to the \(((fetchedCourse[0].semester?.number ?? 0) + 1)). Semester. Delete the course in this semester to add it to another.")
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.white)
                    .font(.system(size: 15, weight: .semibold))
                
                Spacer()
            }
            .padding(.leading, 3)
            .padding(10)
        }
        .cornerRadius(15)
    }
    
    
    var maxCreditsWarning: some View {
        ZStack {
            Color(UIColor.systemRed)
            
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 25, weight: .semibold))
                Text("You have already achieved the maximum possible number of credits for the category \(categories[course?.category ?? 0].name ?? "").")
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.white)
                    .font(.system(size: 15, weight: .semibold))
                
                Spacer()
            }
            .padding(.leading, 3)
            .padding(10)
        }
        .cornerRadius(15)
    }
    
}

struct TagsCloud: View {
    @State var tags: [String]
    
    var body: some View {
        WordCloudLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color("Color1"))
                    .foregroundColor(.white)
                    .cornerRadius(30)
                    .fixedSize()
            }
        }
    }
}

#Preview {
    ImportCourseView(course: nil, semester: nil)
}
