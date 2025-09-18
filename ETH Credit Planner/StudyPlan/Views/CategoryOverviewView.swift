//
//  CategoryOverviewView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 11.11.24.
//

import SwiftUI
import SimpleAnalytics
import CoreData

struct CategoryOverviewView: View {
    @FetchRequest var courses: FetchedResults<Course>
    
    @State var category: Category?
    @State var isAddCoursePopupShown: Bool = false
    
    @State var filteredCourses: [Course] = []
    
    init(category: Category?) {
        self.category = category
        self._courses = FetchRequest<Course>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Course.name, ascending: true)],
            predicate: category != nil ? NSPredicate(format: "category == %@", category!) : nil
        )
    }
    
    var creditsEarned: Int {
        filteredCourses.filter { $0.status == CourseStatus.passed.rawValue }.reduce(0) { $0 + Int($1.credits) }
    }

    var creditsPlanned: Int {
        filteredCourses.filter { $0.status == CourseStatus.planned.rawValue }.reduce(0) { $0 + Int($1.credits) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    creditStats
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Courses")
                            .font(.system(size: 20, weight: .bold))
                        
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
            .navigationTitle(category?.name ?? "")
        }
        .sheet(isPresented: $isAddCoursePopupShown) {
            AddCourseView(isPresented: $isAddCoursePopupShown, selectedCategory: category)
        }
        .onAppear {
            filteredCourses = CourseFilter.shared.filterCourses(Array(courses))
            
            SimpleAnalytics.shared.track(path: ["study-plan", "category"])
        }
    }
    
    var creditStats: some View {
        ZStack {
            Color(UIColor.secondarySystemGroupedBackground)
            
            VStack {
                HStack {
                    Image(systemName: "gauge")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .frame(width: 30, height: 30)
                        .background {
                            Color("Color1")
                        }
                        .cornerRadiusIcon()
                    
                    
                    Text("Credits")
                        .fontWeight(.semibold)
                        .font(.system(size: 20))
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 17, weight: .semibold))
                        Text("\(creditsPlanned) Planned")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background {
                        Color(UIColor.tertiarySystemGroupedBackground)
                    }
                    .cornerRadius(35)
                }
                .padding(.bottom, 15)
                
                ZStack {
                    Circle()
                        .trim(from: 0, to: 0.5)
                        .stroke(style: StrokeStyle(lineWidth: 17, lineCap: .round))
                        .rotationEffect(.degrees(180))
                        .foregroundStyle(Color.gray.opacity(0.3))
                    
                    if let minCredits = category?.minCredits, minCredits != 0 {
                        let plannedProgress = min(Float(creditsPlanned + creditsEarned)/Float(minCredits), 1) * 0.5
                        let earnedProgress = min(Float(creditsEarned)/Float(minCredits), 1) * 0.5
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(plannedProgress))
                            .stroke(style: StrokeStyle(lineWidth: 17, lineCap: .round))
                            .rotationEffect(.degrees(180))
                            .foregroundStyle(Color("Color1"))
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(earnedProgress))
                            .stroke(style: StrokeStyle(lineWidth: 17, lineCap: .round))
                            .rotationEffect(.degrees(180))
                            .foregroundStyle(Color("Color3"))
                    }
                    
                    VStack {
                        Text("\(min(creditsPlanned + creditsEarned, Int(category?.maxCredits ?? 0)))")
                            .font(.system(size: 30, weight: .bold))
                        Text("out of \(category?.minCredits ?? 0)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.gray.opacity(0.3))
                    }
                }
                .frame(width: 140, height: 140)
                .padding(.bottom, -30)
            }
            .padding(12)
            
        }
        .cornerRadius(15)
    }
    
    var courseList: some View {
        ForEach(courses, id: \.self) { course in
            NavigationLink {
                CourseOverviewView(course: course)
            } label: {
                ZStack {
                    Color(UIColor.secondarySystemGroupedBackground)
                    
                    HStack {
                        if(course.status == CourseStatus.planned.rawValue) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 20, weight: .semibold))
                        } else if(course.status == CourseStatus.passed.rawValue) {
                            Image(systemName: "medal.fill")
                                .font(.system(size: 20, weight: .semibold))
                        } else {
                            Image(systemName: "xmark.diamond.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color("Color8"))
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

struct NoCoursesFound: View {
    var body: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(Color(UIColor.systemGray2))
                Text("No Courses Found")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(Color(UIColor.systemGray2))
            }
            .padding(.vertical, 40)
            
            Spacer()
        }
    }
}

struct AddCourseButton: View {
    @Binding var isAddCoursePopupShown: Bool
    
    var body: some View {
        HStack {
            Spacer()

            if #available(iOS 26.0, *) {
                button
                    .glassEffect()
            } else {
                button
            }
            
            Spacer()
        }
    }
    
    var button: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            isAddCoursePopupShown = true
        } label: {
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Add Course")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background {
                Color("Color1")
            }
            .cornerRadius(30)
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
    
    if let category = try? context.fetch(fetchRequest).first {
        return CategoryOverviewView(category: category)
            .environment(\.managedObjectContext, context)
    } else {
        return Text("No categories found")
    }
}
