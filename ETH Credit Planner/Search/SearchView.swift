//
//  SearchView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 13.11.24.
//

import SwiftUI
import SimpleAnalytics

struct SearchView: View {
    @StateObject private var viewModel: AddCourseViewModel = AddCourseViewModel()
    @State var isLoading = true
    @State var searchText: String = ""
    @State var selectedSemester: Int? = nil
    @State var selectedCategory: Category?
    @State var courses: [FirestoreCourse] = []
    @State var filteredCourses: [FirestoreCourse] = []
    @State var semesterStrings: [String] = []
    @State var isRecommendationsPopUpShown: Bool = false
    @State var recommendationPopup: Recommendation?
    let dateformatter = DateFormatter()
    let viewContext = PersistenceController.shared.container.viewContext
    
    @State var isOnboardingIsShown: Bool = false
    
    @AppStorage("BVersionRecommendations") private var bVersion = false
    
    @FetchRequest(
        entity: Recommendation.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Recommendation.date, ascending: false)]
    ) var recommendations: FetchedResults<Recommendation>
    
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.id, ascending: true)]
    ) var categories: FetchedResults<Category>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    searchFilter
                        .padding(.horizontal, 16)
                        .padding(.top, -5)
                    
                    if(bVersion && searchText.isEmpty && selectedCategory == nil && selectedSemester == nil) {
                        recommendationsView
                            .padding(.top, 16)
                            .padding(.horizontal, 16)
                    }
                    
                    if(searchText.isEmpty && selectedCategory == nil && selectedSemester == nil) {
                        Text("All Courses")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                        Text("Course data taken from vvz.ethz.ch. No guarantee for accuracy and completeness.")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(UIColor.systemGray2))
                            .padding(.horizontal, 16)
                    }
                    
                    if(categories.count > 0) {
                        courseList
                            .padding(.horizontal, 16)
                    }
                }
            }
            .navigationTitle("Search")
            .background(Color(UIColor.systemGroupedBackground))
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
                semesterStrings = viewModel.getLastFiveSemesters()
                SimpleAnalytics.shared.track(path: ["search-view"])
                
                if(courses.count == 0) {
                    Task {
                        isLoading = true
                        
                        courses = await viewModel.getCourses()
                        courses.sort { $0.category < $1.category }
                        filteredCourses = courses
                        
                        isLoading = false
                    }
                }
            }
            .fullScreenCover(isPresented: $isOnboardingIsShown) {
                RecommendationsOnboarding(isPresented: $isOnboardingIsShown)
            }
        }
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
                                Task {
                                    selectedSemester = semester
                                    
                                    filteredCourses = courses.filterBySemesterIndex(viewModel.calculateSemesterIndex(from: semesterStrings[semester]) ?? 0)
                                    
                                    if let selectedCategoryId = selectedCategory?.id {
                                        filteredCourses = filteredCourses.filter { $0.category == selectedCategoryId }
                                    }
                                    
                                    filteredCourses = filteredCourses.filter { course in
                                        searchText.isEmpty || course.name.localizedCaseInsensitiveContains(searchText)
                                    }
                                    
                                    filteredCourses.sort { $0.category < $1.category }
                                }
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
                        if(selectedSemester != nil && (selectedSemester! + 1) <= semesterStrings.count) {
                            Text("\(semesterStrings[selectedSemester!])")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color(UIColor.label))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color(UIColor.label))
                        } else {
                            Text("All Semesters")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color(UIColor.label))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color(UIColor.label))
                        }
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
            
            Text("Unsure how you want to plan your upcoming semesters? Generate course suggestions based on your interests.")
                .font(.system(size: 17, weight: .semibold))
                .multilineTextAlignment(.leading)
                .foregroundStyle(Color(UIColor.systemGray2))
            
            ZStack {
                Color("Color1")
                
                HStack {
                    ZStack {
                        Color(.white)
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color("Color1"))
                    }
                    .frame(width: 30, height: 30)
                    .cornerRadius(10)
                    
                    Text("Generate Study Plan")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 54)
            .cornerRadius(15)
            .onTapGesture {
                isOnboardingIsShown = true
            }
            
            HStack {
                Spacer()
                Text("Previously Generated")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(UIColor.systemGray2))
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(UIColor.systemGray2))
                Spacer()
            }
            .onTapGesture {
                isRecommendationsPopUpShown = true
            }
            .sheet(isPresented: $isRecommendationsPopUpShown) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 7) {
                            ForEach(recommendations, id: \.self) { recommendation in
                                Button {
                                    if recommendationPopup != recommendation {
                                        recommendationPopup = recommendation
                                    }
                                } label: {
                                    ZStack {
                                        Color(UIColor.secondarySystemGroupedBackground)
                                        
                                        HStack(spacing: 10) {
                                            ZStack {
                                                Color(Color("Color1"))
                                                Image(systemName: "tray.full.fill")
                                                    .font(.system(size: 21, weight: .semibold))
                                                    .foregroundStyle(.white)
                                            }
                                            .frame(width: 39, height: 39)
                                            .cornerRadius(10)
                                            
                                            VStack(alignment: .leading, spacing: -1) {
                                                Text("\(recommendation.amountOfSemesters) Semesters")
                                                    .foregroundStyle(Color(UIColor.label))
                                                    .font(.system(size: 21, weight: .semibold))
                                                
                                                Text("\(dateformatter.string(from: Date()))")
                                                    .foregroundStyle(Color(UIColor.systemGray2))
                                                    .font(.system(size: 16, weight: .medium))
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundStyle(Color(UIColor.systemGray3))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                    }
                                    .cornerRadius(15)
                                }
                                .contextMenu {
                                    Button {
                                        viewContext.delete(recommendation)
                                        
                                        do {
                                            try viewContext.save()
                                        } catch {
                                            print("\(error)")
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                }
                                .sheet(item: $recommendationPopup) { recommendation in
                                    RecommendationsSemesterView(recommendation: $recommendationPopup)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .toolbar {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(UIColor.systemGray3))
                            .onTapGesture {
                                isRecommendationsPopUpShown = false
                            }
                    }
                    .navigationTitle("Recommendations")
                }
            }
            .onAppear {
                dateformatter.dateFormat = "MM/dd/YYYY"
            }
        }
    }
    
    var courseList: some View {
        LazyVStack(alignment: .leading, spacing: 5) {
            if(!isLoading) {
                ForEach(filteredCourses, id: \.self) { course in
                    NavigationLink {
                        ImportCourseView(course: course)
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
                                        Text(categories[course.category].name ?? "")
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

#Preview {
    SearchView()
}
