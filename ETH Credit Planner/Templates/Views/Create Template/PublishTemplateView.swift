//
//  PublishTemplateView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 14.11.24.
//

import SwiftUI
import SimpleAnalytics

struct PublishTemplateView: View {
    @StateObject var viewModel: CreateTemplateViewModel
    @Binding var isPresented: Bool
    @Binding var isPublishViewShown: Bool
    @State var title: String = ""
    @State var isNameAlertShown: Bool = false
    @State private var selectedTags: Set<String> = []
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(alignment: .leading) {
                        titleSection
                            .padding(.bottom, 25)
                        
                        Text("Tags")
                            .font(.system(size: 20, weight: .bold))
                        
                        Text("Choose at least 3 tag.")
                            .foregroundStyle(Color(UIColor.systemGray2))
                            .font(.system(size: 17, weight: .semibold))
                        
                        WordCloud(selectedTags: $selectedTags)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                        
                    }
                    .padding(.horizontal, 16)
                }
                
                Button {
                    if(selectedTags.count > 2 && !title.isEmpty && (title.count <= 100)) {
                        Task {
                            SimpleAnalytics.shared.track(event: "uploaded template")
                            
                            await viewModel.uploadTemplate(title: title, selectedTags: Array(selectedTags))
                            isPresented = false
                        }
                    } else {
                        isNameAlertShown = true
                    }
                } label: {
                    ZStack {
                        if(selectedTags.count > 2 && !title.isEmpty) {
                            Color("Color1")
                        } else {
                            Color(UIColor.secondarySystemGroupedBackground)
                        }
                        
                        Text("Publish")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(selectedTags.count > 2 && !title.isEmpty ? .white : Color(UIColor.label))
                    }
                    .frame(height: 54)
                    .cornerRadius(15)
                    .padding(.horizontal, 16)
                }
                .alert("Error", isPresented: $isNameAlertShown) {
                    Button {
                        isNameAlertShown = false
                    } label: {
                        Text("Ok")
                    }
                } message: {
                    Text("Please select at least 3 tags and choose a title with less than 100 characters.")
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Publish")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isPublishViewShown = false
                    } label: {
                        Text("Back")
                    }
                }
            }
            .onAppear {
                SimpleAnalytics.shared.track(path: ["templates", "published-templates", "publish-template"])
            }
        }
        .accentColor(Color("Color3"))
    }
    
    var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Title")
                .font(.system(size: 20, weight: .bold))
            
            Text("Choose a title that best describes your study plan.")
                .foregroundStyle(Color(UIColor.systemGray2))
                .font(.system(size: 17, weight: .semibold))
                .padding(.top, -7)
            
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
                    
                    TextField("Title", text: $title)
                        .font(.system(size: 17, weight: .medium))
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 52)
            .cornerRadius(10)
        }
    }
}

struct WordCloud: View {
    @Binding var selectedTags: Set<String>
    
    var body: some View {
        WordCloudLayout(spacing: 8) {
            ForEach(AppConstants.Tags.template, id: \.self) { word in
                Text(word)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(selectedTags.contains(word) ? Color("Color1") : Color(UIColor.secondarySystemGroupedBackground))
                    .foregroundColor(selectedTags.contains(word) ? .white : Color(UIColor.label))
                    .cornerRadius(30)
                    .lineLimit(1)
                    .fixedSize()
                    .onTapGesture {
                        if selectedTags.contains(word) {
                            selectedTags.remove(word)
                        } else {
                            selectedTags.insert(word)
                        }
                    }
            }
        }
    }
}

#Preview {
    PublishTemplateView(viewModel: CreateTemplateViewModel(courses: []), isPresented: .constant(true), isPublishViewShown: .constant(true))
}
