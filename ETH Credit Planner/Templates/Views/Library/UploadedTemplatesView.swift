//
//  UploadedTemplatesView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 13.11.24.
//

import SwiftUI

struct UploadedTemplatesView: View {
    @State var isCreatePopUpShown: Bool = false
    @State var isLoading: Bool = false
    @State var uploadedTemplates: [Template] = []
    @State var isDeleteAlertShown: Bool = false
    @State var templateToDelete: Template? = nil
    @State var isImportAlertShown: Bool = false
    @State var studyPlan: [[FirestoreCourse]] = []
    @Binding var isUploadedTemplatesShown: Bool
    @ObservedObject var viewModel: UploadedTemplateViewModel = UploadedTemplateViewModel()
    
    @AppStorage("BVersionTemplates") private var bVersion = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        Button {
                            isImportAlertShown = true
                        } label: {
                            uploadTemplateButton
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Published")
                                .font(.system(size: 22, weight: .bold))
                                .padding(.leading, 16)
                            
                            if(uploadedTemplates.count > 0) {
                                templates
                                    .padding(.horizontal, 16)
                            } else {
                                if(isLoading) {
                                    loadingTemplates
                                } else {
                                    noTemplatesFound
                                }
                            }
                        }
                    }
                    .fullScreenCover(isPresented: $isCreatePopUpShown, onDismiss: {
                        Task {
                            isLoading = true
                            uploadedTemplates = await viewModel.getUserTemplates()
                            isLoading = false
                        }
                    }) {
                        CreateTemplateView(courses: studyPlan, isPresented: $isCreatePopUpShown)
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
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Your Templates")
            .onAppear {
                Task {
                    isLoading = true
                    
                    uploadedTemplates = await viewModel.getUserTemplates()
                    
                    isLoading = false
                }
            }
            .alert("Import Courses", isPresented: $isImportAlertShown) {
                Button("No") {
                    isCreatePopUpShown = true
                }
                Button("Import") {
                    studyPlan = viewModel.fetchCoursesOrganizedBySemester()
                    isCreatePopUpShown = true
                }
            } message: {
                Text("Would you like to import the courses from your study plan?")
            }
        }
    }
    
    var templates: some View {
        ForEach($uploadedTemplates, id: \.self) { $template in
            NavigationLink {
                TemplateOverviewView(template: $template, color: Color("Color1"))
            } label: {
                ZStack(alignment: .leading) {
                    Color("Color1")
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .top) {
                            Text(template.title)
                                .multilineTextAlignment(.leading)
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
                                Text(template.authorName)
                                    .foregroundStyle(.white.opacity(0.6))
                                    .font(.system(size: 17, weight: .medium))
                            }
                            
                            HStack(spacing: 3) {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.white.opacity(0.6))
                                    .font(.system(size: 17, weight: .medium))
                                Text("\(template.amountOfLikes)")
                                    .foregroundStyle(.white.opacity(0.6))
                                    .font(.system(size: 17, weight: .medium))
                            }
                        }
                        
                        HStack(spacing: 3) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color(UIColor.systemRed))
                            Text("Delete")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color(UIColor.systemRed))
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.white)
                        .cornerRadius(30)
                        .padding(.top, 10)
                        .onTapGesture {
                            templateToDelete = template
                            isDeleteAlertShown = true
                        }
                        
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
                .cornerRadius(15)
                .alert("Delete Template", isPresented: $isDeleteAlertShown) {
                    Button("Cancel", role: .cancel) {
                        isDeleteAlertShown = false
                    }
                    Button("Yes", role: .destructive) {
                        if let template = templateToDelete {
                            Task {
                                await viewModel.deleteTemplate(template: template)
                                uploadedTemplates.removeAll(where: { $0.id == template.id })
                            }
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete this template?")
                }
            }
        }
    }
    
    var noTemplatesFound: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(Color(UIColor.systemGray2))
                Text("You have not yet \nuploaded a template")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(Color(UIColor.systemGray2))
            }
            .padding(.vertical, 40)
            
            Spacer()
        }
    }
    
    var loadingTemplates: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 7) {
                ProgressView()
                Text("Loading Templates")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(Color(UIColor.systemGray2))
            }
            .padding(.vertical, 40)
            
            Spacer()
        }
    }
    
    var uploadTemplateButton: some View {
        ZStack {
            Color("Color7")
            
            HStack {
                ZStack {
                    Color(.white)
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color("Color7"))
                }
                .frame(width: 30, height: 30)
                .cornerRadius(10)
                
                Text("Create a new Template")
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

#Preview {
    UploadedTemplatesView(isUploadedTemplatesShown: .constant(true))
}
