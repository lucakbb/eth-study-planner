//
//  AddCustomCourseView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 20.11.24.
//

import SwiftUI
import SimpleAnalytics

struct AddCustomCourseView: View {
    @StateObject var viewModel: AddCustomCourseViewModel = AddCustomCourseViewModel()
    @Binding var isPresented: Bool
    
    @FetchRequest(
        entity: Semester.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Semester.number, ascending: true)]
    ) var semesters: FetchedResults<Semester>
    
    @State var semester: Semester?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 5) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        VStack(alignment: .leading, spacing: 10) {
                            ZStack {
                                Color(UIColor.secondarySystemGroupedBackground)
                                
                                HStack {
                                    ZStack {
                                        Color("Color1")
                                        
                                        Image(systemName: "tag.fill")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                                    .frame(width: 32, height: 32)
                                    .cornerRadius(5)
                                    
                                    TextField("Name", text: $viewModel.title)
                                        .font(.system(size: 17, weight: .medium))
                                }
                                .padding(.horizontal, 12)
                            }
                            .frame(height: 52)
                            .cornerRadius(10)
                            
                            ZStack {
                                Color(UIColor.secondarySystemGroupedBackground)
                                
                                HStack {
                                    ZStack {
                                        Color("Color1")
                                        
                                        Image(systemName: "calendar")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                                    .frame(width: 32, height: 32)
                                    .cornerRadius(5)
                                    
                                    Text("Credits: \(viewModel.credits)")
                                        .font(.system(size: 20, weight: .semibold))
                                    
                                    Spacer()
                                    
                                    Stepper("Credits", value: $viewModel.credits, in: 1...20)
                                        .labelsHidden()
                                }
                                .padding(.horizontal, 12)
                            }
                            .frame(height: 52)
                            .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Categories")
                                .font(.system(size: 20, weight: .semibold))
                            
                            CategoryCloud(selectedCategory: $viewModel.selectedCategory)
                        }
                    }
                    .padding(.horizontal, 16)
                    .navigationTitle("Add Custom Course")
                }
                
                Menu {
                    ForEach(semesters, id: \.self) { semester in
                        Button {
                            viewModel.selectedSemester = semester
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
                
                ZStack {
                    if(viewModel.title != "" && viewModel.selectedCategory != nil && viewModel.selectedSemester != nil) {
                        Color("Color1")
                    } else {
                        Color(UIColor.secondarySystemGroupedBackground)
                    }
                    
                    Text("Add Course to \((viewModel.selectedSemester?.number ?? 0) + 1). Semester")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle((viewModel.title != "" && viewModel.selectedCategory != nil && viewModel.selectedSemester != nil) ? .white: Color(UIColor.label))
                }
                .frame(height: 54)
                .cornerRadius(15)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .onTapGesture {
                    if(viewModel.title != "" && viewModel.selectedCategory != nil && viewModel.selectedSemester != nil) {
                        
                        SimpleAnalytics.shared.track(event: "added custom course")
                        viewModel.saveCourse()
                        isPresented = false
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear {
                if let semester = semester {
                    viewModel.selectedSemester = semester
                    return
                }
                
                if semesters.count > 0 {
                    viewModel.selectedSemester = semesters[0]
                }
            }
            .toolbar {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color(UIColor.systemGray3))
                    .onTapGesture {
                        isPresented = false
                    }
            }
        }
    }
}

struct CategoryCloud: View {
    @Binding var selectedCategory: Category?
    
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.id, ascending: true)]
    ) var categories: FetchedResults<Category>
    
    var body: some View {
        WordCloudLayout(spacing: 8) {
            ForEach(categories, id: \.self) { category in
                Text(category.name ?? "")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(selectedCategory == category ? Color("Color1") : Color(UIColor.secondarySystemGroupedBackground))
                    .foregroundColor(selectedCategory == category ? .white : Color(UIColor.label))
                    .cornerRadius(30)
                    .lineLimit(1)
                    .fixedSize()
                    .onTapGesture {
                        selectedCategory = category
                    }
            }
        }
    }
}

#Preview {
    Text("Hello, World!")
        .sheet(isPresented: .constant(true)) {
            AddCustomCourseView(isPresented: .constant(false))
        }
}
