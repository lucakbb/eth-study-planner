//
//  AddCourseView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 12.11.24.
//

import SwiftUI
import SimpleAnalytics

struct AddCourseView: View {
    @StateObject var viewModel: AddCourseViewModel = AddCourseViewModel()
    @State var courses: [FirestoreCourse] = []
    @State var isLoading: Bool = false
    
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.id, ascending: true)]
    ) var categories: FetchedResults<Category>
    
    @Binding var isPresented: Bool
    @State var searchText: String = ""
    
    /// Represents the selected semester for filtering courses.
    /// - `nil`: Indicates that "All Courses" is selected in the search filter.
    /// - `0-4`: Corresponds to the semesters in `semesterStrings`, where:
    ///   - `0`: Represents the most recent semester.
    ///   - `4`: Represents the oldest semester.
    @State var selectedSemester: Int? = nil
    @State var selectedCategory: Category? = nil
    
    /// Represents the semester associated with this view.
    /// - If the user navigates here from the semester overview in the study plan, `semester` will contain the selected semester.
    /// - If the user navigates here from the category overview, `semester` will be `nil`.
    /// This is used to set the default semester to which the course will be added.
    @State var semester: Semester?
    
    @State var filteredCourses: [FirestoreCourse] = []
    @State var semesterStrings: [String] = []
    @State var isAddCustomCourseViewShown: Bool = false
    
    @State var recommendations: [FirestoreCourse] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    searchFilter
                        .padding(.horizontal, 16)
                        .padding(.top, -5)

                    if searchText.isEmpty {
                        recommendationsView
                            .padding(.horizontal, 16)
                            .padding(.top, 15)
                    }
                    
                    allCourses
                        .padding(.top, searchText.isEmpty ? 15 : 0)
                        .padding(.horizontal, 16)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Add Course")
            .sheet(isPresented: $isAddCustomCourseViewShown) {
                AddCustomCourseView(isPresented: $isAddCustomCourseViewShown, semester: semester)
            }
            .toolbar {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color(UIColor.systemGray3))
                    .onTapGesture {
                        isPresented = false
                    }
            }
            .searchable(text: $searchText)
            .onChange(of: searchText) {
                filteredCourses = courses
                
                if let semester = selectedSemester {
                    filteredCourses = courses.filterBySemesterIndex(viewModel.calculateSemesterIndex(from: semesterStrings[semester]) ?? 0)
                }
                
                if let selectedCategoryId = selectedCategory?.id {
                    filteredCourses = filteredCourses.filter { $0.category == selectedCategoryId }
                }
                
                filteredCourses = filteredCourses.filter { course in
                   searchText.isEmpty || course.name.localizedCaseInsensitiveContains(searchText)
               }
                
                filteredCourses.sort { $0.category < $1.category }
            }
            .onAppear {
                SimpleAnalytics.shared.track(path: ["study-plan", "add-course"])
                
                Task {
                    if(courses.count == 0) {
                        isLoading = true
                        
                        semesterStrings = viewModel.getLastFiveSemesters()
                       
                        courses = await viewModel.getCourses()
                        filteredCourses = courses
                        
                        filteredCourses.sort { $0.category < $1.category }
                        
                        if let category = selectedCategory {
                            filteredCourses = courses.filter { $0.category == category.id }
                        }
                        
                        isLoading = false
                    }
                }
            }
        }
        .accentColor(Color("Color3"))
    }
    
    var searchFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Menu {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            selectedCategory = category
                            filteredCourses = courses
                            
                            if let semester = selectedSemester {
                                filteredCourses = courses.filterBySemesterIndex(viewModel.calculateSemesterIndex(from: semesterStrings[semester]) ?? 0)
                            }
                            
                            if let selectedCategoryId = selectedCategory?.id {
                                filteredCourses = filteredCourses.filter { $0.category == selectedCategoryId }
                            }
                            
                            filteredCourses = filteredCourses.filter { course in
                               searchText.isEmpty || course.name.localizedCaseInsensitiveContains(searchText)
                           }
                            
                            filteredCourses.sort { $0.category < $1.category }
                        } label: {
                            Text(category.name ?? "")
                        }
                    }
                    
                    Button {
                        selectedCategory = nil
                        filteredCourses = courses
                        
                        if let semester = selectedSemester {
                            filteredCourses = courses.filterBySemesterIndex(viewModel.calculateSemesterIndex(from: semesterStrings[semester]) ?? 0)
                        }
                        
                        filteredCourses = filteredCourses.filter { course in
                           searchText.isEmpty || course.name.localizedCaseInsensitiveContains(searchText)
                       }
                        
                        filteredCourses.sort { $0.category < $1.category }
                    } label: {
                        Text("All Courses")
                    }
                } label: {
                    HStack {
                        if(selectedCategory == nil) {
                            Text("All Categories")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color(UIColor.label))
                        } else {
                            Text("\(selectedCategory!.name ?? "")")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color(UIColor.label))
                        }
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(UIColor.label))
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background {
                        Color(UIColor.secondarySystemGroupedBackground)
                    }
                    .cornerRadius(20)
                }
                
                Menu {
                    if(categories.count > 0 && semesterStrings.count == 5) {
                        ForEach(0..<5, id: \.self) { semester in
                            Button {
                                selectedSemester = semester
                                
                                filteredCourses = courses.filterBySemesterIndex(viewModel.calculateSemesterIndex(from: semesterStrings[semester]) ?? 0)
                                
                                if let selectedCategoryId = selectedCategory?.id {
                                    filteredCourses = filteredCourses.filter { $0.category == selectedCategoryId }
                                }
                                
                                filteredCourses = filteredCourses.filter { course in
                                    searchText.isEmpty || course.name.localizedCaseInsensitiveContains(searchText)
                                }
                                
                                filteredCourses.sort { $0.category < $1.category }
                                
                                // reset semester
                                self.semester = nil
                            } label: {
                                Text("\(semesterStrings[semester])")
                            }
                        }
                    }
                    
                    Button {
                        selectedSemester = nil
                        
                        filteredCourses = courses
                        
                        if let selectedCategoryId = selectedCategory?.id {
                            filteredCourses = filteredCourses.filter { $0.category == selectedCategoryId }
                        }
                        
                        filteredCourses = filteredCourses.filter { course in
                           searchText.isEmpty || course.name.localizedCaseInsensitiveContains(searchText)
                       }
                        
                        filteredCourses.sort { $0.category < $1.category }
                    } label: {
                        Text("All Semesters")
                    }
                } label: {
                    HStack {
                        if(selectedSemester == nil || (selectedSemester! == -1 || selectedSemester! > (semesterStrings.count - 1))) {
                            Text("All Semesters")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color(UIColor.label))
                        } else {
                            Text("\(semesterStrings[selectedSemester!])")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color(UIColor.label))
                        }
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(UIColor.label))
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background {
                        Color(UIColor.secondarySystemGroupedBackground)
                    }
                    .cornerRadius(20)
                }
            }
        }
    }
    
    var recommendationsView: some View {
        VStack(alignment: .leading) {
            Text("Recommendations")
                .font(.system(size: 20, weight: .semibold))
            Text("Based on your interests and ratings, we would recommend you one of the following courses.")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(UIColor.systemGray2))
            
            ZStack {
                Color(UIColor.secondarySystemGroupedBackground)
                
                if(recommendations.count > 0) {
                    VStack(spacing: 5) {
                        ForEach(recommendations, id: \.self) { course in
                            NavigationLink {
                                if(semester != nil) {
                                    ImportCourseView(course: course, semester: semester)
                                } else {
                                    ImportCourseView(course: course)
                                }
                            } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(course.name)
                                                .multilineTextAlignment(.leading)
                                                .foregroundStyle(Color(UIColor.label))
                                                .font(.system(size: 20, weight: .semibold))
                                                .padding(.trailing, 15)
                                            
                                            HStack(spacing: 5) {
                                                Text(categories[course.category].name ?? "" == "Science in Perspective" ? "GESS" : categories[course.category].name ?? "")
                                                    .font(.system(size: 17, weight: .semibold))
                                                    .foregroundStyle(.white)
                                                    .padding(.vertical, 3)
                                                    .padding(.horizontal, 9)
                                                    .background {
                                                        Color("Color1")
                                                    }
                                                    .cornerRadius(30)
                                                
                                                Text("\(course.credits) ECTS")
                                                    .font(.system(size: 17, weight: .semibold))
                                                    .foregroundStyle(.white)
                                                    .padding(.vertical, 3)
                                                    .padding(.horizontal, 9)
                                                    .background {
                                                        Color("Color1")
                                                    }
                                                    .cornerRadius(30)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(Color(UIColor.systemGray3))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                                    .cornerRadius(15)
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(UIColor.systemGray2))
                        Text("No Recommended \nCourses")
                            .multilineTextAlignment(.center)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(UIColor.systemGray2))
                    }
                    .padding(.vertical, 40)
                }
            }
            .cornerRadius(15)
        }
        .onAppear {
            if(semesterStrings.count == 0) {
                semesterStrings = viewModel.getLastFiveSemesters()
            }
            
            var currentSemester = 0
            if let semester = selectedSemester {
                currentSemester = semester
            } else {
                if let semester = semester {
                    let semesterType = Int(semester.number) % 2 == 0 ? "H" : "F"
                    currentSemester = semesterStrings.firstIndex(where: { $0.hasPrefix(semesterType) } ) ?? 0
                }
            }
            
            if let category = selectedCategory {
                recommendations = viewModel.getCategoryRecommendations(semester: viewModel.calculateSemesterIndex(from: semesterStrings[currentSemester]) ?? 0, category: category)
            } else {
                recommendations = viewModel.getSemesterRecommendations(semester: viewModel.calculateSemesterIndex(from: semesterStrings[currentSemester]) ?? 0)
            }
        }
        .onChange(of: selectedCategory) {
            var currentSemester = 0
            if let semester = selectedSemester {
                currentSemester = semester
            } else {
                if let semester = semester {
                    let semesterType = Int(semester.number) % 2 == 0 ? "H" : "F"
                    currentSemester = semesterStrings.firstIndex(where: { $0.hasPrefix(semesterType) } ) ?? 0
                }
            }
            
            if let category = selectedCategory {
                recommendations = viewModel.getCategoryRecommendations(semester: viewModel.calculateSemesterIndex(from: semesterStrings[currentSemester]) ?? 0, category: category)
            } else {
                recommendations = viewModel.getSemesterRecommendations(semester: viewModel.calculateSemesterIndex(from: semesterStrings[currentSemester]) ?? 0)
            }
        }
        .onChange(of: selectedSemester) {
            var currentSemester = 0
            
            if let semester = selectedSemester {
                currentSemester = semester
            } else {
                if let semester = semester {
                    let semesterType = Int(semester.number) % 2 == 0 ? "H" : "F"
                    currentSemester = semesterStrings.firstIndex(where: { $0.hasPrefix(semesterType) } ) ?? 0
                }
            }
            
            if let category = selectedCategory {
                recommendations = viewModel.getCategoryRecommendations(semester: viewModel.calculateSemesterIndex(from: semesterStrings[currentSemester]) ?? 0, category: category)
            } else {
                recommendations = viewModel.getSemesterRecommendations(semester: viewModel.calculateSemesterIndex(from: semesterStrings[currentSemester]) ?? 0)
            }
        }
    }
    
    var allCourses: some View {
        VStack(alignment: .leading) {
            if searchText.isEmpty {
                HStack {
                    Text("All Courses")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Spacer()
                    
                    Text("Add Custom Course")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color("Color3"))
                        .onTapGesture {
                            isAddCustomCourseViewShown = true
                        }
                }
                Text("Course data taken from vvz.ethz.ch. No guarantee for accuracy and completeness.")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(UIColor.systemGray2))
            }
            
            LazyVStack(spacing: 5) {
                if(!isLoading) {
                    ForEach(filteredCourses, id: \.self) { course in
                        NavigationLink {
                            if(semester != nil) {
                                ImportCourseView(course: course, semester: semester)
                            } else {
                                ImportCourseView(course: course)
                            }
                        } label: {
                            ZStack {
                                Color(UIColor.secondarySystemGroupedBackground)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(course.name)
                                            .foregroundStyle(Color(UIColor.label))
                                            .multilineTextAlignment(.leading)
                                            .font(.system(size: 20, weight: .semibold))
                                            .padding(.trailing, 15)
                                        
                                        HStack(spacing: 5) {
                                            Text(categories[course.category].name ?? "" == "Science in Perspective" ? "GESS" : categories[course.category].name ?? "")
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundStyle(.white)
                                                .padding(.vertical, 3)
                                                .padding(.horizontal, 9)
                                                .background {
                                                    Color("Color1")
                                                }
                                                .cornerRadius(30)
                                            
                                            Text("\(course.credits) ECTS")
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundStyle(.white)
                                                .padding(.vertical, 3)
                                                .padding(.horizontal, 9)
                                                .background {
                                                    Color("Color1")
                                                }
                                                .cornerRadius(30)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(Color(UIColor.systemGray3))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                            .cornerRadius(15)
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 10) {
                            ProgressView()
                                .padding(.top, 80)
                            Text("Loading Courses")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color(UIColor.systemGray2))
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    Text("")
        .sheet(isPresented: .constant(true)) {
            AddCourseView(isPresented: .constant(true)).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
}
