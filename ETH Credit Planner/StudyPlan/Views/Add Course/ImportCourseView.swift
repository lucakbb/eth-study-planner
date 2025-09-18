//
//  ImportCourseView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 16.11.24.
//

import SwiftUI
import SimpleAnalytics
import CoreData

struct ImportCourseView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) private var dismiss
    
    let viewContext = PersistenceController.shared.container.viewContext
    @ObservedObject var viewModel: ImportCourseViewModel = ImportCourseViewModel()
    
    // Fetches all courses.
    // Used to check if the maximum number of credits for a specific category has been reached.
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
    
    // Fetches all courses with the same ID that are marked as "passed".
    // Used to verify if the course can be added again to the planner.
    @FetchRequest var passedCourse: FetchedResults<Course>
    
    @State var course: FirestoreCourse?
    @State var selectedSemester: Semester?
    @State var filteredSemesters: [Semester] = []
    @State var isReviewsSheetShown: Bool = false
    @State var isVVZSheetShown: Bool = false
    @State var isAlreadyAddedAlertShown: Bool = false
    
    init(course: FirestoreCourse?, semester: Semester?) {
        self.course = course
        self.selectedSemester = semester
        
        let courseMainID = course?.id.split(separator: "&&").first.map(String.init) ?? course?.id
        self._passedCourse = FetchRequest<Course>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Course.name, ascending: true)],
            predicate: NSPredicate(format: "status == %@ AND (id == %@ OR id BEGINSWITH %@)",
                                   CourseStatus.passed.rawValue,
                                   course?.id ?? "-1",
                                   courseMainID ?? "-2")
        )
        
        if let semester = semester {
            viewModel.fetchMatchingCourses(semester: semester, courseID: course?.id ?? "-1")
        }
    }
    
    init(course: FirestoreCourse?) {
        self.course = course
        self.selectedSemester = nil
        
        let courseMainID = course?.id.split(separator: "&&").first.map(String.init) ?? course?.id
        self._passedCourse = FetchRequest<Course>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Course.name, ascending: true)],
            predicate: NSPredicate(format: "status == %@ AND (id == %@ OR id BEGINSWITH %@)",
                                   CourseStatus.passed.rawValue,
                                   course?.id ?? "-1",
                                   courseMainID ?? "-2")
        )
    }
    
    var body: some View {
        if(categories.count > 0) {
            NavigationStack {
                VStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 25) {
                            let categoryCourses = courses.filter { $0.category?.id ?? -1 == course?.category ?? -2 && $0.status != CourseStatus.failed.rawValue }
                            let credits = categoryCourses.reduce(0) { $0 + Int($1.credits)}
                            let maxCredits = categories[course?.category ?? 0].maxCredits
                            
                            if(credits >= maxCredits || passedCourse.count > 0) {
                                VStack(alignment: .leading, spacing: 5) {
                                    if(credits >= maxCredits) {
                                        maxCreditsWarning
                                    }
                                    
                                    if(passedCourse.count > 0) {
                                        alreadyPassedWarning
                                    } else if(viewModel.matchingCoursesInSelectedSemester.count > 0) {
                                        alreadyAddedToSelectedSemesterWarning
                                    }
                                }
                            }
                            
                            links
                            
                            general
                            
                        }
                        .padding(.horizontal, 16)
                    }
                    .navigationTitle("Course Overview")
                    
                    // Show Button to change semester only if a semester has already been selected
                    if(passedCourse.count == 0 && selectedSemester != nil) {
                        Menu {
                            ForEach(filteredSemesters, id: \.self) { semester in
                                Button {
                                    selectedSemester = semester
                                    
                                    if let selectedSemester = selectedSemester {
                                        viewModel.fetchMatchingCourses(semester: selectedSemester, courseID: course?.id ?? "-1")
                                    }
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
                    
                    if(passedCourse.count == 0 && viewModel.matchingCoursesInSelectedSemester.count == 0 && selectedSemester == nil) {
                        Menu {
                            ForEach(filteredSemesters, id: \.self) { semester in
                                Button {
                                    selectedSemester = semester
                                    
                                    viewModel.fetchMatchingCourses(semester: semester, courseID: course?.id ?? "-1")
                                    if(viewModel.matchingCoursesInSelectedSemester.count == 0) {
                                        if let selectedCourse = course, let semester = selectedSemester {
                                            SimpleAnalytics.shared.track(event: "added course")
                                            
                                            viewModel.importCourse(firestoreCourse: selectedCourse, semester: semester, category: categories[course?.category ?? 0])
                                            
                                            dismiss()
                                        }
                                    } else {
                                        isAlreadyAddedAlertShown = true
                                    }
                                } label: {
                                    Text("\(semester.number + 1). Semester")
                                }
                            }
                        } label: {
                            ZStack {
                                Color("Color1")
                                Text("Add Course")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(height: 54)
                            .cornerRadiusTextField()
                            .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20)
                            .padding(.bottom, 10)
                        }
                    } else {
                        ZStack {
                            if(passedCourse.count > 0) {
                                Color(UIColor.secondarySystemGroupedBackground)
                                Text("Passed in the \(((passedCourse[0].semester?.number ?? 0) + 1)). Semester")
                                    .font(.system(size: 20, weight: .semibold))
                            } else if(viewModel.matchingCoursesInSelectedSemester.count > 0) {
                                Color(UIColor.secondarySystemGroupedBackground)
                                Text("Already added to the \(((selectedSemester?.number ?? 0) + 1)). Semester")
                                    .font(.system(size: 20, weight: .semibold))
                            } else {
                                Color("Color1")
                                Text("Add to \((selectedSemester?.number ?? -1) + 1). Semester")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(height: 54)
                        .cornerRadiusTextField()
                        .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20)
                        .padding(.bottom, 10)
                        .onTapGesture {
                            if(passedCourse.count == 0 && viewModel.matchingCoursesInSelectedSemester.count == 0 && selectedSemester != nil) {
                                if let selectedCourse = course, let semester = selectedSemester {
                                    SimpleAnalytics.shared.track(event: "added course")
                                    
                                    viewModel.importCourse(firestoreCourse: selectedCourse, semester: semester, category: categories[course?.category ?? 0])
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    // Check if course is available in selected Semester, if not selectedSemester = nil
                    if let semester = selectedSemester {
                        
                        let isHSSemester = (semester.number % 2 == 0)
                        if let semestersArray = course?.semester {
                            if(isHSSemester) {
                                self.selectedSemester = semestersArray.contains{ $0 % 2 == 1 } ? semester : nil
                            } else {
                                self.selectedSemester = semestersArray.contains{ $0 % 2 == 0 } ? semester : nil
                            }
                        } else {
                            self.selectedSemester = semester
                        }
                        
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
                .alert("Error", isPresented: $isAlreadyAddedAlertShown) {
                    Button {
                        isAlreadyAddedAlertShown = false
                    } label: {
                        Text("Ok")
                    }
                } message: {
                    Text("You have already added this course to the selected semester.")
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
                    #if targetEnvironment(macCatalyst)
                    openURL(URL(string: course?.vvz ?? "")!)
                    #else
                    isVVZSheetShown = true
                    #endif
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
                    let courseMainID = course?.id.split(separator: "&&").first.map(String.init) ?? course?.id
                    #if targetEnvironment(macCatalyst)
                    openURL(URL(string: "https://n.ethz.ch/~lteufelbe/coursereview/?course=\(courseMainID ?? "")")!)
                    #else
                    isReviewsSheetShown = true
                    #endif
                }
                .sheet(isPresented: $isReviewsSheetShown) {
                    let courseMainID = course?.id.split(separator: "&&").first.map(String.init) ?? course?.id
                    if let url = URL(string: "https://n.ethz.ch/~lteufelbe/coursereview/?course=\(courseMainID ?? "")") {
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
    
    var alreadyAddedToSelectedSemesterWarning: some View {
        ZStack {
            Color("Color7")
            
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 25, weight: .semibold))
                Text("You have already added the course to the selected semester.")
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
    
    var alreadyPassedWarning: some View {
        ZStack {
            Color("Color7")
            
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 25, weight: .semibold))
                Text("You have already passed the course in the \(((passedCourse[0].semester?.number ?? 0) + 1)). Semester.")
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
            Color("Color7")
            
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 25, weight: .semibold))
                Text("You have already planned/achieved the maximum possible number of credits for the category \(categories[course?.category ?? 0].name ?? "").")
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
    
    do {
        if try context.fetch(fetchRequest).count > 0 {
            return ImportCourseView(course: nil, semester: nil)
        } else {
            return Text("No categories found")
        }
    } catch {
        return Text("Error loading categories: \(error.localizedDescription)")
    }
}

