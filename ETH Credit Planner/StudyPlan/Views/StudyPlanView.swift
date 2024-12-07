//
//  StudyPlanView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 11.11.24.
//

import SwiftUI
import CoreData
import SimpleAnalytics

struct StudyPlanView: View {
    @State var isCategoryViewShown = false
    @State var isCreditOverviewShown = false
    @State var isLoading = false
    @ObservedObject var onboardingViewModel: OnboardingViewModel = OnboardingViewModel()
    
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.id, ascending: true)]
    ) var categories: FetchedResults<Category>
    
    var body: some View {
        if(categories.count > 0) {
            NavigationStack {
                ZStack(alignment: .bottom) {
                    if(isCategoryViewShown) {
                        CategoryView(isCreditOverviewShown: $isCreditOverviewShown)
                            .padding(.horizontal, 16)
                    } else {
                        SemesterView(isCreditOverviewShown: $isCreditOverviewShown)
                            .padding(.horizontal, 16)
                    }
                    
                    VStack {
                        Spacer()
                        
                        ChangeViewButton(isCategoryViewShown: $isCategoryViewShown)
                    }
                    .padding(.bottom, 15)
                }
                .background(Color(UIColor.systemGroupedBackground))
                .navigationTitle("Study Plan")
                .sheet(isPresented: $isCreditOverviewShown) {
                    CreditsOverviewView(isPresented: $isCreditOverviewShown)
                }
                .toolbar {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gear")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(UIColor.label))
                            .padding(6)
                            .background {
                                Circle()
                                    .foregroundColor(Color(UIColor.secondarySystemGroupedBackground))
                            }
                    }
                }
                .onAppear {
                    SimpleAnalytics.shared.track(path: ["study-plan"])
                }
            }
        } else {
            HStack {
                Spacer()
                
                VStack(spacing: 7) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(Color(UIColor.systemGray2))
                    Text("No Data could be found.")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(Color(UIColor.systemGray2))
                    
                    Button {
                        Task {
                            if(isLoading) {
                                return
                            }
    
                            do {
                                isLoading = true
                                try await onboardingViewModel.createDefaultCourses()
                                isLoading = false
                            } catch {
                                print(error)
                            }
                        }
                    } label: {
                        Text("Reload")
                            .font(.system(size: 23, weight: .semibold))
                            .foregroundStyle(Color("Color3"))
                    }
                    .padding(.top, 60)
                }
                .padding(.vertical, 40)
                
                Spacer()
            }
        }
    }
}

struct ChangeViewButton: View {
    @Binding var isCategoryViewShown: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 3) {
                Image(systemName: "calendar")
                    .font(.system(size: 15, weight: .semibold))
                Text("Semester")
                    .font(.system(size: 15, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .background {
                if(!isCategoryViewShown) {
                    Color(UIColor.systemBackground)
                        .frame(height: 40)
                        .cornerRadius(40)
                }
            }
            .onTapGesture {
                isCategoryViewShown = false
                
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
            
            HStack(spacing: 3) {
                Image(systemName: "tray.2.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("Categories")
                    .font(.system(size: 15, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .background {
                if(isCategoryViewShown) {
                    Color(UIColor.systemBackground)
                        .frame(height: 40)
                        .cornerRadius(40)
                }
            }
            .onTapGesture {
                isCategoryViewShown = true
                
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
        .frame(height: 48)
        .padding(.horizontal, 5)
        .background {
            RoundedRectangle(cornerRadius: 40)
                .foregroundStyle(Color(UIColor.tertiarySystemGroupedBackground))
        }
        .cornerRadius(40)
        .overlay(
            RoundedRectangle(cornerRadius: 40)
                .stroke(Color(UIColor.systemGray3), lineWidth: 1)
        )
    }
}

struct CategoryView: View {
    @StateObject private var viewModel: StudyPlanViewModel = StudyPlanViewModel()
    @Binding var isCreditOverviewShown: Bool
    
    @FetchRequest(
        fetchRequest: Category.fetchRequestWithCourses()
    ) var categories: FetchedResults<Category>
    
    let colors = [Color("Color1"), Color("Color2"), Color("Color3"), Color("Color4"), Color("Color6"), Color("Color7"), Color("Color8"), Color("Color9")]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                CreditsOverviewBanner()
                    .onTapGesture {
                        isCreditOverviewShown = true
                    }
                
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                        
                        // get courses for category
                        let courses = category.courses as? Set<Course> ?? []
                        let courseCount = courses.count
                      
                        
                        // filter courses for status
                        let passedCourses = courses.filter { $0.isPassed }
                        
                        // calculate credits
                        let passedCredits = passedCourses.reduce(0) { $0 + $1.credits }
                        let plannedCredits = courses.reduce(0) { $0 + $1.credits }
                         
                        
                        NavigationLink {
                            CategoryOverviewView(category: category)
                        } label: {
                            ZStack {
                                colors.indices.contains(index) ? colors[index] : Color.gray
                                
                                VStack(alignment: .leading) {
                                    HStack(alignment: .top) {
                                       
                                        ZStack {
                                            Circle()
                                                .stroke(category.minCredits > 0 ? Color.white.opacity(0.5) : Color.white, lineWidth: 7)
                                                .frame(width: 65, height: 65)
                                            
                                            if category.minCredits > 0 {
                                                let progress = min(max(Float(passedCredits) / Float(category.minCredits), 0), 1)
                                                
                                                Circle()
                                                    .trim(from: 0, to: CGFloat(progress))
                                                    .stroke(style: StrokeStyle(lineWidth: 7, lineCap: .round))
                                                    .foregroundStyle(Color.white)
                                                    .rotationEffect(.degrees(-90))
                                                    .frame(width: 65, height: 65)
                                            }
                                            
                                            Image(systemName: category.icon ?? "questionmark.circle")
                                                .font(.system(size: 25, weight: .semibold))
                                                .foregroundStyle(Color.white)
                                        }
                                        .padding(3)
                                         
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.white.opacity(0.5))
                                            .font(.system(size: 20, weight: .semibold))
                                            .padding(3)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(category.name!)
                                        .multilineTextAlignment(.leading)
                                        .font(.system(size: 23, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.trailing, 10)
                                    
                                    Text("\(courseCount) Courses")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.5))
                                    
                                    Text("\(Image(systemName: "medal.fill")) \(min(passedCredits, category.maxCredits))/\(category.minCredits) Earned")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(height: 30)
                                        .padding(.horizontal, 10)
                                        .background {
                                            Color(Color(.white).opacity(0.17))
                                        }
                                        .cornerRadius(25)
                                    
                                    Text("\(Image(systemName: "clock.fill")) \(min(plannedCredits, category.maxCredits))/\(category.minCredits) Planned")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(height: 30)
                                        .padding(.horizontal, 10)
                                        .background {
                                            Color(Color(.white).opacity(0.17))
                                        }
                                        .cornerRadius(25)
                                    
                                }
                                .padding(12)
                            }
                            .frame(height: 265)
                            .cornerRadius(15)
                        }
                    }
                }
                .padding(.bottom, 100)
            }
        }
    }
}

struct SemesterView: View {
    @StateObject private var viewModel: StudyPlanViewModel = StudyPlanViewModel()
    @Binding var isCreditOverviewShown: Bool
    
    @FetchRequest(
        fetchRequest: Semester.fetchRequestWithCourses()
    ) var semesters: FetchedResults<Semester>
    
    let colors = [Color("Color1"), Color("Color2"), Color("Color3"), Color("Color4"), Color("Color6"), Color("Color7"), Color("Color8"), Color("Color9"), Color("Color6"), Color("Color7"), Color("Color8"), Color("Color9")]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                CreditsOverviewBanner()
                    .onTapGesture {
                        isCreditOverviewShown = true
                    }
                
                ForEach(Array(semesters.enumerated()), id: \.element) { index, semester in
                    let courses = semester.courses as? Set<Course> ?? []
                    let amount = courses.count
                    let credits = courses.reduce(0) { $0 + $1.credits }
                    
                    NavigationLink {
                        SemesterOverviewView(semester: semester)
                    } label: {
                        ZStack {
                            Color(UIColor.secondarySystemGroupedBackground)
                            
                            HStack {
                                Text("\(semester.number + 1)")
                                    .font(.system(size: 33, weight: .semibold, design: .rounded))
                                    .foregroundStyle(colors.indices.contains(index) ? colors[index] : Color.gray)
                                    .frame(width: 55, height: 55)
                                    .background {
                                        Color(UIColor.systemGroupedBackground)
                                    }
                                    .cornerRadius(15)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Semester")
                                        .font(.system(size: 21, weight: .semibold))
                                        .foregroundStyle(Color(UIColor.label))
                                    
                                    HStack(spacing: 5) {
                                        Text("\(amount) Courses")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(Color(UIColor.label))
                                            .padding(.vertical, 3)
                                            .padding(.horizontal, 10)
                                            .background {
                                                Color(UIColor.tertiarySystemGroupedBackground)
                                                    .cornerRadius(30)
                                            }
                                        
                                        Text("\(credits) ECTS")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(Color(UIColor.label))
                                            .padding(.vertical, 3)
                                            .padding(.horizontal, 10)
                                            .background {
                                                Color(UIColor.tertiarySystemGroupedBackground)
                                                    .cornerRadius(30)
                                            }
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color(UIColor.systemGray3))
                                    .font(.system(size: 20, weight: .semibold))
                                    .padding(.trailing, 15)
                            }
                            .padding(.leading, 12)
                        }
                        .frame(height: 75)
                        .cornerRadius(15)
                    }
                }
            }
            .padding(.bottom, 90)
        }
    }
}

extension Semester {
    static func fetchRequestWithCourses() -> NSFetchRequest<Semester> {
        let request = Semester.fetchRequest() 
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Semester.number, ascending: true)]
        request.relationshipKeyPathsForPrefetching = ["courses"]
        return request
    }
}

extension Category {
    static func fetchRequestWithCourses() -> NSFetchRequest<Category> {
        let request = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.id, ascending: true)]
        request.relationshipKeyPathsForPrefetching = ["courses"]
        return request
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
            return StudyPlanView().environment(\.managedObjectContext, context)
        } else {
            return Text("No categories found")
        }
    } catch {
        return Text("Error loading categories: \(error.localizedDescription)")
    }
}

