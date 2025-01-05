//
//  CreditsOverviewView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 12.11.24.
//

import SwiftUI
import SimpleAnalytics
import CoreData

struct CreditsOverviewView: View {
    @Binding var isPresented: Bool
    
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.id, ascending: true)]
    ) var categories: FetchedResults<Category>
    
    @FetchRequest(
        entity: Course.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Course.id, ascending: true)],
        predicate: NSPredicate(format: "status != %@", CourseStatus.failed.rawValue)
    ) var courses: FetchedResults<Course>
    
    @State var filteredCourses: [Course] = []
    @State var isCreditCalculationShown: Bool = false
    
    var earnedCreditsByCategory: [Category: Int] {
        var result = Dictionary(uniqueKeysWithValues: categories.map { ($0, 0) })
        
        filteredCourses.forEach { course in
            if let category = course.category {
                if(course.status == CourseStatus.passed.rawValue) {
                    result[category, default: 0] += Int(course.credits)
                }
            }
        }
        
        return result
    }
    
    var plannedCreditsByCategory: [Category: Int] {
        var result = Dictionary(uniqueKeysWithValues: categories.map { ($0, 0) })
        
        filteredCourses.forEach { course in
            if let category = course.category {
                if(course.status == CourseStatus.planned.rawValue) {
                    result[category, default: 0] += Int(course.credits)
                }
            }
        }
        
        return result
    }
    
    var creditsEarned: Int {
        var totalCredits = 0
        categories.forEach { category in
            totalCredits += min(earnedCreditsByCategory[category] ?? 0, Int(category.maxCredits))
        }
        
        return totalCredits
    }
    
    var creditsPlanned: Int {
        var totalCredits = 0
        categories.forEach { category in
            totalCredits += min(plannedCreditsByCategory[category] ?? 0, Int(category.maxCredits))
        }
        
        return totalCredits
    }
    
    var basicAndCoreCredits: Int {
        filteredCourses
            .filter { course in
                if let category = course.category {
                    return category.id == 1 || category.id == 2
                }
                return false
            }
            .reduce(0) { $0 + Int($1.credits) }
    }
    
    var electivesCredits: Int {
        filteredCourses
            .filter { course in
                if let category = course.category {
                    return category.id == 1 || category.id == 2 || category.id == 4
                }
                return false
            }
            .reduce(0) { $0 + Int($1.credits) }
    }
    
    var creditsByCategory: [Category: Int] {
        var result = Dictionary(uniqueKeysWithValues: categories.map { ($0, 0) })
        
        filteredCourses.forEach { course in
            if let category = course.category {
                result[category, default: 0] += Int(course.credits)
            }
        }
        
        return result
    }
    
    var categoriesWithMissingCredits: [Category] {
        var result: [Category] = []
        
        categories.forEach { category in
            if(creditsByCategory[category] ?? 0 < category.minCredits) {
                result.append(category)
            }
        }
        
        return result
    }
    
    var categoriesToEarnCredits: [Category] {
        var result: [Category] = []
        
        categories.forEach { category in
            if(creditsByCategory[category] ?? 0 < category.maxCredits) {
                result.append(category)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    
                    Text("The following statistics take earned and planned credits into account.")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(UIColor.systemGray2))
                        .padding(.top, -5)
                        .padding(.bottom, 10)
                    
                    creditStats
                    
                    basicAndCoreView
                    
                    electivesView
                    
                    if(!categoriesWithMissingCredits.isEmpty) {
                        missingCreditsView
                            .padding(.top, 25)
                    }
                    
                    if(!categoriesToEarnCredits.isEmpty && (creditsEarned + creditsPlanned) < 180) {
                        categoriesToEarnCreditsView
                            .padding(.top, 25)
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("All Courses")
            .toolbar {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color(UIColor.systemGray3))
                    .onTapGesture {
                        isPresented = false
                    }
            }
            .onAppear {
                filteredCourses = CourseFilter.shared.filterCourses(Array(courses))
                
                SimpleAnalytics.shared.track(path: ["study-plan", "credit-overview"])
            }
            .sheet(isPresented: $isCreditCalculationShown) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text("Courses can have one of three statuses: Planned, Passed, or Failed. \n\nThe overall credit count is calculated by adding the credits of all Planned and Passed courses, while ignoring those of Failed courses. Additionally, if a course is entered multiple times in the study plan, only one instance is considered. The credits from the course with the highest priority status will be used.")
                                .font(.system(size: 18, weight: .medium))
                                .padding(.bottom, 15)
                            Text("Examples")
                                .font(.system(size: 18, weight: .bold))
                            Text("\u{2022} If a course is marked Failed in the 1st semester but Planned in the 3rd semester, it will be treated as Planned and the credits for the course will be counted only once.")
                                .font(.system(size: 18, weight: .medium))
                            Text("\u{2022} If a course is marked Planned in the 3st and 5st semester, it will be treated as Planned. Again, the credits for the course are added only once.")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                    }
                    .navigationTitle("Credit Calculation")
                    .toolbar {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(UIColor.systemGray3))
                            .onTapGesture {
                                isCreditCalculationShown = false
                            }
                    }
                }
            }
        }
    }
    
    var creditStats: some View {
        ZStack {
            Color(UIColor.secondarySystemGroupedBackground)
            
            VStack {
                HStack {
                    ZStack {
                        Color("Color1")
                        Image(systemName: "gauge")
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .frame(width: 27, height: 27)
                    .cornerRadius(5)
                    
                    
                    Text("Overall Credits")
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
                    
                    let plannedProgress = min(Float(creditsEarned + creditsPlanned)/Float(180), 1) * 0.5
                    let earnedProgress = min(Float(creditsEarned)/Float(180), 1) * 0.5
                    
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
                    
                    VStack {
                        Text("\(creditsEarned + creditsPlanned)")
                            .font(.system(size: 30, weight: .bold))
                        Text("out of 180")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.gray.opacity(0.3))
                    }
                }
                .frame(width: 140, height: 140)
                .padding(.bottom, -30)
                
                ZStack {
                    Color("Color1")
                    
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 20, weight: .semibold))
                        Text("How is this number calculated?")
                            .foregroundStyle(.white)
                            .font(.system(size: 17, weight: .semibold))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white)
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.trailing, 5)
                    }
                    .padding(10)
                    .onTapGesture {
                        isCreditCalculationShown = true
                    }
                }
                .cornerRadius(15)
            }
            .padding(12)
            
        }
        .cornerRadius(15)
    }
    
    var basicAndCoreView: some View {
        ZStack {
            Color(UIColor.secondarySystemGroupedBackground)
            
            HStack {
                ZStack {
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(180))
                        .foregroundStyle(Color.gray.opacity(0.3))
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(basicAndCoreCredits) / 84)
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .foregroundStyle(Color("Color1"))
                }
                .frame(width: 60, height: 60)
                .padding(.leading, 20)
                .padding(.trailing, 10)
                .padding(.vertical, 15)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Basic & Core Courses")
                        .font(.system(size: 20, weight: .semibold))
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 17, weight: .semibold))
                        Text("\(basicAndCoreCredits)/84 Planned")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background {
                        Color(UIColor.tertiarySystemGroupedBackground)
                    }
                    .cornerRadius(35)
                }
                
                Spacer()
            }
            
        }
        .cornerRadius(15)
    }
    
    var electivesView: some View {
        ZStack {
            Color(UIColor.secondarySystemGroupedBackground)
            
            HStack {
                ZStack {
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(180))
                        .foregroundStyle(Color.gray.opacity(0.3))
                    Circle()
                        .trim(from: 0, to: CGFloat(electivesCredits) / 96)
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .foregroundStyle(Color("Color1"))
                }
                .frame(width: 60, height: 60)
                .padding(.leading, 20)
                .padding(.trailing, 10)
                .padding(.vertical, 15)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Basic, Core & Electives")
                        .font(.system(size: 20, weight: .semibold))
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 17, weight: .semibold))
                        Text("\(electivesCredits)/96 Planned")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background {
                        Color(UIColor.tertiarySystemGroupedBackground)
                    }
                    .cornerRadius(35)
                }
                
                Spacer()
            }
            
        }
        .cornerRadius(15)
    }
    
    var missingCreditsView: some View {
        VStack(alignment: .leading) {
            Text("Missing Credits")
                .font(.system(size: 20, weight: .semibold))
            Text("You are missing planned credits in the following categories.")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(UIColor.systemGray2))

            
            ForEach(Array(categoriesWithMissingCredits).sorted { $0.id < $1.id }, id: \.self) { category in
                ZStack(alignment: .leading) {
                    Color(UIColor.secondarySystemGroupedBackground)
                    Text(category.name ?? "")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.vertical, 9)
                        .padding(.leading, 10)
                }
                .cornerRadius(10)
            }
        }
    }
    
    var categoriesToEarnCreditsView: some View {
        VStack(alignment: .leading) {
            Text("Available Credits")
                .font(.system(size: 20, weight: .semibold))
            Text("You can still plan credits in the following categories.")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(UIColor.systemGray2))

            
            ForEach(Array(categoriesToEarnCredits).sorted { $0.id < $1.id }, id: \.self) { category in
                ZStack(alignment: .leading) {
                    Color(UIColor.secondarySystemGroupedBackground)
                    Text(category.name ?? "")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.vertical, 9)
                        .padding(.leading, 10)
                }
                .cornerRadius(10)
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
            return Text("Test")
                .sheet(isPresented: .constant(true)) {
                    CreditsOverviewView(isPresented: .constant(true)).environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                }
        } else {
            return Text("No categories found")
        }
    } catch {
        return Text("Error loading categories: \(error.localizedDescription)")
    }
}
