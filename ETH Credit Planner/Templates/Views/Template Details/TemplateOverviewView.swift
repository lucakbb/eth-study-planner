//
//  TemplateOverviewView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 13.11.24.
//

import SwiftUI
import SimpleAnalytics

struct TemplateOverviewView: View {
    @ObservedObject var viewModel: TemplateOverviewViewModel = TemplateOverviewViewModel()
    
    @Binding var template: Template
    @State var isSemesterPopoverShown: Bool = false
    @State var isCategoryPopoverShown: Bool = false
    @State var hasLiked: Bool = false
    @State var amountOfLikes: Int = 0
    
    @State var color: Color
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        shortStats
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("View Courses")
                                .font(.system(size: 22, weight: .bold))
                            
                            courseOverview
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Divider()
                            
                            HStack {
                                ZStack {
                                    Image(systemName: hasLiked ? "heart.fill" : "heart")
                                        .foregroundStyle(hasLiked ? Color(UIColor.systemRed) : Color(UIColor.label))
                                        .font(.system(size: 20, weight: .semibold))
                                        .padding(6)
                                        .background {
                                            Circle()
                                                .foregroundStyle(Color(UIColor.secondarySystemGroupedBackground))
                                        }
                                }
                                .onTapGesture {
                                    if(!hasLiked) {
                                        Task {
                                            if let modifiedTemplate = await viewModel.addLike(template: template) {
                                                template = modifiedTemplate
                                            }
                                            
                                            let generator = UIImpactFeedbackGenerator(style: .heavy)
                                            generator.impactOccurred()
                                            
                                            hasLiked = true
                                            amountOfLikes += 1
                                        }
                                    } else {
                                        Task {
                                            if let modifiedTemplate = await viewModel.removeLike(template: template) {
                                                template = modifiedTemplate
                                            }
                                            
                                            let generator = UIImpactFeedbackGenerator(style: .heavy)
                                            generator.impactOccurred()
                                            
                                            hasLiked = false
                                            amountOfLikes -= 1
                                        }
                                    }
                                }
                                
                                Text("\(amountOfLikes)")
                                    .font(.system(size: 20, weight: .semibold))
                                
                                Spacer()
                                
                                ShareLink(item: "#\(template.shareCode)") {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(Color("Color3"))
                                }
                            }
                            .padding(.horizontal, 5)
                        }
                    }
                }
            }
            .navigationTitle("\(template.authorName)'s Study Plan")
            .padding(.horizontal, 16)
            .background(Color(UIColor.systemGroupedBackground))
            .sheet(isPresented: $isSemesterPopoverShown) {
                TemplateSemesterView(isPresented: $isSemesterPopoverShown, template: template)
            }
            .sheet(isPresented: $isCategoryPopoverShown) {
                TemplateCategoryView(isPresented: $isCategoryPopoverShown, template: template)
            }
            .onAppear {
                hasLiked = viewModel.hasLiked(template: template)
                amountOfLikes = template.amountOfLikes
                
                SimpleAnalytics.shared.track(path: ["templates", "topic", "template-overview"])
            }
        }
    }
    
    var shortStats: some View {
        ZStack(alignment: .leading) {
            color
            
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top) {
                    Text(template.title)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                HStack(spacing: 10) {
                    HStack(spacing: 3) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.system(size: 17, weight: .medium))
                        Text(template.authorName)
                            .lineLimit(1)
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.system(size: 17, weight: .medium))
                    }
                    
                    HStack(spacing: 0) {
                        Image(systemName: "number")
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.system(size: 17, weight: .medium))
                        Text(template.shareCode)
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.system(size: 17, weight: .medium))
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .cornerRadius(15)
    }
    
    var courseOverview: some View {
        VStack {
            ZStack {
                Color(UIColor.secondarySystemGroupedBackground)
                
                HStack(spacing: 7) {
                    Image(systemName: "calendar")
                        .font(.system(size: 22, weight: .semibold))
                    
                    Text("Courses by Semester")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 22, weight: .semibold))
                }
                .padding(.horizontal, 13)
            }
            .frame(height: 54)
            .cornerRadius(15)
            .onTapGesture {
                isSemesterPopoverShown = true
            }
            
            ZStack {
                Color(UIColor.secondarySystemGroupedBackground)
                
                HStack(spacing: 7) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 22, weight: .semibold))
                    
                    Text("Courses by Category")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 22, weight: .semibold))
                }
                .padding(.horizontal, 13)
            }
            .frame(height: 54)
            .cornerRadius(15)
            .onTapGesture {
                isCategoryPopoverShown = true
            }
        }
    }
}

#Preview {
    TemplateOverviewView(template: .constant(Template(id: UUID(), title: "Machine Learning", shareCode: "", authorName: "Simon", authorID: "123", likes: [], amountOfLikes: 0, tags: ["Machine Learning", "Coding", "Algorithms"], courses: [], amountOfSemesters: 0, amountOfCourses: 0)), color: Color("Color1"))
     
}
