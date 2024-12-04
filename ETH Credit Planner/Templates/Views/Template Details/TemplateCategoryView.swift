//
//  TemplateCategoryView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 13.11.24.
//

import SwiftUI
import SimpleAnalytics

struct TemplateCategoryView: View {
    @ObservedObject var viewModel: TemplateOverviewViewModel = TemplateOverviewViewModel()
    
    @Binding var isPresented: Bool
    @State var template: Template
    @State var courses: [[FirestoreCourse]] = []
    @State var isLoading: Bool = false
    
    let colors = [Color("Color1"), Color("Color2"), Color("Color3"), Color("Color4"), Color("Color6"), Color("Color7"), Color("Color8"), Color("Color9"), Color("Color6"), Color("Color7"), Color("Color8"), Color("Color9")]
    
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.id, ascending: true)]
    ) var categories: FetchedResults<Category>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if(!isLoading) {
                        categoryList
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
                .padding(.horizontal, 16)
            }
            .navigationTitle("\(template.authorName)'s Study Plan")
            .background(Color(UIColor.systemGroupedBackground))
            .toolbar {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color(UIColor.systemGray3))
                    .onTapGesture {
                        isPresented = false
                    }
            }
            .onAppear {
                SimpleAnalytics.shared.track(path: ["templates", "topic", "template-overview", "category"])
                
                Task {
                    isLoading = true
                    courses = await viewModel.fetchTemplateCourses(template: template)
                    isLoading = false
                }
            }
        }
        .accentColor(Color("Color1"))
    }
    
    var categoryList: some View {
        ScrollView {
            VStack {
                ForEach(categories, id: \.self) { category in
                  
                    let filteredCourses = courses
                        .flatMap { $0 }
                        .filter { $0.category == category.id }
                    let amount = filteredCourses.count
                    let credits = filteredCourses.map(\.credits).reduce(0, +)
                   
                    NavigationLink {
                        TemplateCategoryOverviewView(courses: $courses, category: category, isEditing: false)
                    } label: {
                        ZStack {
                            colors[Int(category.id)]
                            
                            HStack {
                                Image(systemName: category.icon ?? "questionmark")
                                    .font(.system(size: 27, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 40, height: 40)
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(category.name ?? "")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(.white)
                                    
                                    HStack(spacing: 5) {
                                        Text("\(amount) Courses | \(credits) ECTS")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.white.opacity(0.5))
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
        }
    }
}

#Preview {
    TemplateCategoryView(isPresented: .constant(true), template: Template(id: UUID(), title: "Machine Learning", shareCode: "", authorName: "Simon", authorID: "123", likes: [], amountOfLikes: 0, tags: ["Machine Learning", "Coding", "Algorithms"], courses: [], amountOfSemesters: 0, amountOfCourses: 0), isLoading: false).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
