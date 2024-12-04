//
//  TopicOverviewView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 13.11.24.
//

import SwiftUI
import SimpleAnalytics

struct TopicOverviewView: View {
    @ObservedObject var viewModel = TopicOverviewViewModel()
    @State var topic: TemplateLibararyTopic
    
    @State var templates: [Template] = []
    @State var isLoading: Bool = false
    @State var isShowMoreShown: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    if(!isLoading || templates.count > 0) {
                        if(templates.count == 0) {
                            noTemplatesFound
                        }
                        
                        ForEach($templates, id: \.self) { $template in
                            NavigationLink {
                                TemplateOverviewView(template: $template, color: topic.color)
                            } label: {
                                TemplatePreviewCard(template: template, color: topic.color)
                            }
                        }
                        
                        if(isShowMoreShown) {
                            HStack {
                                Spacer()
                                
                                Button {
                                    Task {
                                        isLoading = true
                                        var newTemplates: [Template] = []
                                        (newTemplates, isShowMoreShown) = await viewModel.fetchTemplates(topic: topic)
                                        
                                        if !newTemplates.isEmpty {
                                            templates.append(contentsOf: newTemplates)
                                        }
                                        isLoading = false
                                    }
                                } label: {
                                    if(isLoading) {
                                        ProgressView()
                                    } else {
                                        Text("Show More")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(Color("Color3"))
                                            .padding(.top, 20)
                                            .padding(.bottom, 40)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    } else {
                        if(isLoading) {
                            LoadingPlaceholderCards(count: 5, color: topic.color)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .onAppear {
                    SimpleAnalytics.shared.track(path: ["templates", "topic"])
                    
                    if(templates.count == 0) {
                        viewModel.lastFetchedDocument = nil
                        
                        Task {
                            isLoading = true
                            (templates, isShowMoreShown) = await viewModel.fetchTemplates(topic: topic)
                            isLoading = false
                        }
                    }
                }
            }
            .navigationTitle(topic.title)
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
    
    var noTemplatesFound: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(Color(UIColor.systemGray2))
                Text("No Templates Found")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(Color(UIColor.systemGray2))
            }
            .padding(.vertical, 40)
            
            Spacer()
        }
    }
}

struct TemplatePreviewCard: View {
    @State var template: Template? = nil
    @State var color: Color = Color("Color1")
    
    var body: some View {
        ZStack(alignment: .leading) {
            color
            
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top) {
                    Text(template?.title ?? "")
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                HStack(spacing: 10) {
                    HStack(spacing: 3) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.system(size: 17, weight: .medium))
                        Text(template?.authorName ?? "")
                            .lineLimit(1)
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.system(size: 17, weight: .medium))
                    }
                    
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.system(size: 17, weight: .medium))
                        Text("\(template?.amountOfLikes ?? 0)")
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.system(size: 17, weight: .medium))
                    }
                    
                    HStack(spacing: 0) {
                        Image(systemName: "number")
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.system(size: 17, weight: .medium))
                        Text(template?.shareCode ?? "")
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
}

struct LoadingPlaceholderCards: View {
    let count: Int
    @State var color: Color = Color("Color1")

    var body: some View {
        ForEach(0..<count, id: \.self) { _ in
            TemplatePreviewCard(template: Template(id: UUID(), title: "ML", shareCode: "", authorName: "Alex", authorID: "", likes: [], amountOfLikes: 42, tags: ["Tag 1", "Tag 2", "Tag 3"], courses: [], amountOfSemesters: 0, amountOfCourses: 0), color: color)
                .redacted(reason: .placeholder)
        }
    }
}

#Preview {
    TopicOverviewView(topic: TemplateLibararyTopic(title: "Machine Learning", icon: "brain.fill", color: Color("Color1")))
}
