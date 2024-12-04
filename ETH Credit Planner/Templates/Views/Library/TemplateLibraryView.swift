//
//  TemplateLibraryView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 13.11.24.
//

import SwiftUI
import SimpleAnalytics

struct TemplateLibraryView: View {
    @Environment(\.isSearching) private var isSearching
    @ObservedObject var viewModel: TemplateLibraryViewModel = TemplateLibraryViewModel()
    @AppStorage("BVersionTemplates") private var bVersion = false
    
    @State var searchText: String = ""
    @State var searchResults: [Template] = []
    @State var isLoading: Bool = false
    @State var mostLikedTemplates: [Template] = []
    
    @State var isUploadedTemplatesShown: Bool = false
    
    var body: some View {
        ZStack {
            if(!isUploadedTemplatesShown) {
                templateLibrary
                    .onAppear {
                        SimpleAnalytics.shared.track(path: ["templates", "library"])
                    }
            } else {
                UploadedTemplatesView(isUploadedTemplatesShown: $isUploadedTemplatesShown)
                    .onAppear {
                        SimpleAnalytics.shared.track(path: ["templates", "published-templates"])
                    }
            }
        }
        .onDisappear {
            isUploadedTemplatesShown = false
        }
    }
    
    var templateLibrary: some View {
        NavigationStack {
            VStack {
                if(searchText.isEmpty) {
                    ZStack {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 20) {
                                
                                if(!bVersion) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Create Templates")
                                            .font(.system(size: 22, weight: .bold))
                                            .padding(.leading, 16)
                                        
                                        NavigationLink {
                                            UploadedTemplatesView(isUploadedTemplatesShown: $isUploadedTemplatesShown)
                                                .onAppear {
                                                    SimpleAnalytics.shared.track(path: ["templates", "published-templates"])
                                                }
                                        } label: {
                                            ZStack {
                                                Color("Color7")
                                                
                                                HStack {
                                                    ZStack {
                                                        Color(.white)
                                                        Image(systemName: "person.fill")
                                                            .font(.system(size: 20, weight: .semibold))
                                                            .foregroundStyle(Color("Color7"))
                                                    }
                                                    .frame(width: 35, height: 35)
                                                    .cornerRadius(10)
                                                    
                                                    Text("Your Templates")
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
                                            .padding(.horizontal, 16)
                                        }
                                    }
                                    .padding(.top, 5)
                                }
                                
                                topics
                                
                                semesters
                                
                                mostLikes
                                    .padding(.bottom, 80)
                            }
                        }
                        
                        if(bVersion) {
                            VStack {
                                Spacer()
                                
                                ChangeTemplatesViewButton(isUploadedTemplatesShown: $isUploadedTemplatesShown)
                            }
                            .padding(.bottom, 15)
                        }
                    }
                } else {
                    if(searchResults.count > 0) {
                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach($searchResults, id: \.self) { $template in
                                    NavigationLink {
                                        TemplateOverviewView(template: $template, color: Color("Color1"))
                                    } label: {
                                        TemplatePreviewCard(template: template)
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    } else {
                        noTemplatesFound
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Templates")
            .searchable(text: $searchText, prompt: "Enter Template ID")
            .onChange(of: searchText) {
                if(searchText.count == 5) {
                    Task {
                        searchResults = await viewModel.getTemplatesByShareCode(shareCode: searchText)
                    }
                }
            }
            .toolbar {
                NavigationLink {
                    TopicOverviewView(topic: TemplateLibararyTopic(title: "Templates You Liked", icon: "bookmark.fill", color: Color("Color1")))
                } label: {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                        .padding(8)
                        .background {
                            Circle()
                                .foregroundColor(Color(UIColor.secondarySystemGroupedBackground))
                        }
                }
            }
            .refreshable {
                Task {
                    isLoading = true
                    mostLikedTemplates = await viewModel.fetchMostLikedTemplates()
                    isLoading = false
                }
            }
        }
    }
    
    var topics: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Topics")
                .font(.system(size: 22, weight: .bold))
                .padding(.leading, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 7) {
                    VStack(spacing: 7) {
                        ForEach(AppConstants.TemplateTopics.topics, id: \.self) { row in
                            HStack(spacing: 7) {
                                ForEach(Array(row.enumerated()), id: \.offset) { index, topic in
                                    NavigationLink {
                                        TopicOverviewView(topic: topic)
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: topic.icon)
                                                .foregroundStyle(Color(UIColor.label))
                                                .font(.system(size: 20, weight: .semibold))
                                            Text(topic.title)
                                                .foregroundStyle(Color(UIColor.label))
                                                .font(.system(size: 20, weight: .semibold))
                                        }
                                        .padding(.horizontal, 10)
                                        .frame(height: 35)
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .cornerRadius(30)
                                        .padding(.leading, (index == 0) ? 16 : 0)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }
   
    
    var semesters: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Amount of Semesters")
                .font(.system(size: 22, weight: .bold))
                .padding(.leading, 16)
            
            ZStack {
                Color(UIColor.secondarySystemGroupedBackground)
                
                HStack {
                    ForEach(Array(AppConstants.TemplateTopics.semesters.enumerated()), id: \.element) { index, topic in
                        Spacer()
                        NavigationLink {
                            TopicOverviewView(topic: topic)
                        } label: {
                            VStack {
                                ZStack {
                                    Circle()
                                        .frame(width: 65, height: 65)
                                        .foregroundStyle(topic.color)
                                    if(topic.title.prefix(1) == "8") {
                                        Text("8+")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 30, weight: .semibold, design: .rounded))
                                    } else {
                                        Text(topic.title.prefix(1))
                                            .foregroundStyle(.white)
                                            .font(.system(size: 30, weight: .semibold, design: .rounded))
                                    }
                                }
                                
                                Text("Semesters")
                                    .foregroundStyle(Color(UIColor.label))
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 16)
            }
            .cornerRadius(15)
            .padding(.horizontal, 16)
        }
    }

   
    var categories: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("More")
                .font(.system(size: 22, weight: .bold))
                .padding(.leading, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 7) {
                    VStack(spacing: 7) {
                        ForEach(AppConstants.TemplateTopics.categories, id: \.self) { row in
                            HStack(spacing: 7) {
                                ForEach(Array(row.enumerated()), id: \.offset) { index, topic in
                                    NavigationLink {
                                        TopicOverviewView(topic: topic)
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: topic.icon)
                                                .foregroundStyle(Color(UIColor.label))
                                                .font(.system(size: 20, weight: .semibold))
                                            Text(topic.title)
                                                .foregroundStyle(Color(UIColor.label))
                                                .font(.system(size: 20, weight: .semibold))
                                        }
                                        .padding(.horizontal, 10)
                                        .frame(height: 35)
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .cornerRadius(30)
                                        .padding(.leading, (index == 0) ? 16 : 0)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }
    
    var mostLikes: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Most Liked Templates")
                .font(.system(size: 22, weight: .bold))
                .padding(.leading, 16)
            
            VStack(spacing: 10) {
                if(!isLoading) {
                    ForEach($mostLikedTemplates, id: \.self) { $template in
                        NavigationLink {
                            TemplateOverviewView(template: $template, color: Color("Color7"))
                        } label: {
                            TemplatePreviewCard(template: template, color: Color("Color7"))
                        }
                    }
                } else {
                    if(isLoading) {
                        LoadingPlaceholderCards(count: 5, color: Color("Color7"))
                    }
                }
            }
            .padding(.horizontal, 16)
            .onAppear {
                if(mostLikedTemplates.count == 0) {
                    Task {
                        isLoading = true
                        mostLikedTemplates = await viewModel.fetchMostLikedTemplates()
                        isLoading = false
                    }
                }
            }
        }
    }
    
    var noTemplatesFound: some View {
        VStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(Color(UIColor.systemGray2))
            Text("No Templates Found")
                .multilineTextAlignment(.center)
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(Color(UIColor.systemGray2))
        }
    }
}

struct ChangeTemplatesViewButton: View {
    @Binding var isUploadedTemplatesShown: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 3) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("Library")
                    .font(.system(size: 15, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .background {
                if(!isUploadedTemplatesShown) {
                    Color(UIColor.systemBackground)
                        .frame(height: 40)
                        .cornerRadius(40)
                }
            }
            .onTapGesture {
                isUploadedTemplatesShown = false
                
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
            
            HStack(spacing: 3) {
                Image(systemName: "person.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("Published")
                    .font(.system(size: 15, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .background {
                if(isUploadedTemplatesShown) {
                    Color(UIColor.systemBackground)
                        .frame(height: 40)
                        .cornerRadius(40)
                }
            }
            .onTapGesture {
                isUploadedTemplatesShown = true
                
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

#Preview {
    TemplateLibraryView()
}
