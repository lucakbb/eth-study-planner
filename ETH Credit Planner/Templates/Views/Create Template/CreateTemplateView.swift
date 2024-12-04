//
//  CreateTemplateView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 13.11.24.
//

import SwiftUI
import SimpleAnalytics

struct CreateTemplateView: View {
    @StateObject var viewModel: CreateTemplateViewModel
    @State var isCategoryViewShown = false
    @State var alertMessage: IdentifiableString? = nil
    @State var isPublishViewShown: Bool = false
    @Binding var isPresented: Bool
    
    init(courses: [[FirestoreCourse]], isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: CreateTemplateViewModel(courses: courses))
        self._isPresented = isPresented
    }
    
    var body: some View {
        if(!isPublishViewShown) {
            createTemplate
        } else {
            PublishTemplateView(viewModel: viewModel, isPresented: $isPresented, isPublishViewShown: $isPublishViewShown)
                .onAppear {
                    alertMessage = nil
                }
        }
    }
    
    var createTemplate: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if(isCategoryViewShown) {
                    CreateTemplateCategoryView(viewModel: viewModel)
                        .padding(.horizontal, 16)
                } else {
                    CreateTemplateSemesterView(viewModel: viewModel)
                        .padding(.horizontal, 16)
                }
                
                VStack {
                    Spacer()
                    
                    ChangeViewButton(isCategoryViewShown: $isCategoryViewShown)
                }
                .padding(.bottom, 15)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Create Template")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isPresented = false
                    } label: {
                        Text("Cancel")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        (isPublishViewShown, alertMessage) = viewModel.checkGraduationRequirements
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("Publish")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background {
                            Color("Color1")
                        }
                        .cornerRadius(30)
                    }
                }
            }
            .onAppear {
                SimpleAnalytics.shared.track(path: ["templates", "published-templates", "create-template"])
            }
            .alert(item: $alertMessage) { value in
                Alert(
                    title: Text("Invalid template"),
                    message: Text("Your template does not yet fulfil all the requirements for a study plan. \n\n\(value.value ?? "")"),
                    dismissButton: .default(Text("OK"), action: {
                        alertMessage = nil
                    })
                )
            }
        }
        .accentColor(Color("Color3"))
    }
}

struct CreateTemplateCategoryView: View {
    @StateObject var viewModel: CreateTemplateViewModel
    
    @FetchRequest(
        fetchRequest: Category.fetchRequestWithCourses()
    ) var categories: FetchedResults<Category>
    
    let colors = [Color("Color1"), Color("Color2"), Color("Color3"), Color("Color4"), Color("Color6"), Color("Color7"), Color("Color8"), Color("Color9")]
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(categories, id: \.self) { category in
                  
                    let courses = viewModel.courses
                        .flatMap { $0 }
                        .filter { $0.category == category.id }
                    let amount = courses.count
                    let credits = courses.map(\.credits).reduce(0, +)
                   
                    NavigationLink {
                        TemplateCategoryOverviewView(courses: $viewModel.courses, category: category, isEditing: true)
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
            .padding(.bottom, 120)
        }
    }
}

struct CreateTemplateSemesterView: View {
    @ObservedObject var viewModel: CreateTemplateViewModel
    
    let colors = [Color("Color1"), Color("Color2"), Color("Color3"), Color("Color4"), Color("Color6"), Color("Color7"), Color("Color8"), Color("Color9"), Color("Color6"), Color("Color7"), Color("Color8"), Color("Color9")]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                ForEach(0..<viewModel.courses.count, id: \.self) { index in
                    let courses = viewModel.courses[index]
                    let amount = courses.count
                    let credits = courses.reduce(0) { $0 + $1.credits }
                    
                    NavigationLink {
                        TemplateSemesterOverviewView(courses: $viewModel.courses, semesterNumber: index, isEditing: true, semesterTitle: nil)
                    } label: {
                        ZStack {
                            Color(UIColor.secondarySystemGroupedBackground)
                            
                            HStack {
                                Text("\(index + 1)")
                                    .font(.system(size: 33, weight: .semibold, design: .rounded))
                                    .foregroundStyle(colors[index])
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
                
                HStack {
                    Spacer()

                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Add Semester")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background {
                        Color("Color1")
                    }
                    .cornerRadius(30)
                    .onTapGesture {
                        if(viewModel.courses.count <= 9) {
                            viewModel.courses.append([])
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 30)
                .padding(.bottom, 90)
            }
        }
    }
}

struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String?
}


#Preview {
    CreateTemplateView(courses: [], isPresented: .constant(true))
}
