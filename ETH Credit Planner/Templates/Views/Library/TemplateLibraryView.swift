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
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Create Templates")
                                        .font(.system(size: 22, weight: .bold))
                                        .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20)
                                    
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
                                        .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20)
                                    }
                                }
                                .padding(.top, 5)
                                
                                topics
                                
                                if(UIDevice.current.userInterfaceIdiom == .phone) {
                                    semesters
                                } else {
                                    catalystSemesters
                                }
                                
                                mostLikes
                                    .padding(.bottom, 80)
                            }
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
                                    .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20)
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
                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20)
            
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
                                        .padding(.leading, (index == 0) ? (UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20) : 0)
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
                .padding(.leading, UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20)
            
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
            .padding(.leading, UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20)
        }
    }
    
    var catalystSemesters: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Amount of Semesters")
                .font(.system(size: 22, weight: .bold))
                .padding(.leading, UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20)
            
            HStack(spacing: 10) {
                ForEach(Array(AppConstants.TemplateTopics.semesters.enumerated()), id: \.element) { index, topic in
                    ZStack {
                        Color(UIColor.secondarySystemGroupedBackground)
                        
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
                        .padding(.vertical, 16)
                    }
                    .cornerRadius(15)
                }
            }
            .padding(.horizontal, 20)
        }
    }

   
    var categories: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("More")
                .font(.system(size: 22, weight: .bold))
                .padding(.leading, UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20)
            
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
                                        .padding(.leading, (index == 0) ? (UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20) : 0)
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
                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20)
            
            VStack(spacing: 10) {
                if(!isLoading) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: UIDevice.current.userInterfaceIdiom == .phone ? 1 : 2), spacing: 10) {
                        ForEach($mostLikedTemplates, id: \.self) { $template in
                            NavigationLink {
                                TemplateOverviewView(template: $template, color: Color("Color7"))
                            } label: {
                                TemplatePreviewCard(template: template, color: Color("Color7"))
                            }
                        }
                    }
                } else {
                    if(isLoading) {
                        LoadingPlaceholderCards(count: 5, color: Color("Color7"))
                    }
                }
            }
            .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20)
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

#Preview {
    TemplateLibraryView()
}
