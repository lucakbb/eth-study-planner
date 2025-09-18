//
//  SemesterView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 13.11.24.
//

import SwiftUI
import SimpleAnalytics

struct RecommendationsSemesterView: View {
    var viewModel: RecommendationsViewModel = RecommendationsViewModel()
    let viewContext = PersistenceController.shared.container.viewContext
    
    @Binding var recommendation: Recommendation?
    @State var semesters: [[FirestoreCourse]] = []
    @State var isLoading: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if(!isLoading) {
                        semesterList
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
            .navigationTitle("Generated Study Plan")
            .background(Color(UIColor.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(UIColor.systemRed))
                        .onTapGesture {
                            if let recommendation = recommendation {
                                viewContext.delete(recommendation)
                                
                                do {
                                    try viewContext.save()
                                } catch {
                                    print(error)
                                }
                            }
                            
                            recommendation = nil
                        }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26.0, *) {
                        Image(systemName: "xmark")
                            .onTapGesture {
                                recommendation = nil
                            }
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(UIColor.systemGray3))
                            .onTapGesture {
                                recommendation = nil
                            }
                    }
                }
            }
            .onAppear {
                SimpleAnalytics.shared.track(path: ["recommendations", "semester"])
                
                if let recommendation = recommendation {
                    Task {
                        isLoading = true
                        let coursesIDs = viewModel.fetchRecommendationCourses(for: recommendation)
                        semesters = await viewModel.fetchFirestoreCourses(courseIDs: coursesIDs)
                        isLoading = false
                    }
                }
            }
        }
        .accentColor(Color("Color3"))
    }
    
    var semesterList: some View {
        ScrollView {
            if let recommendation = recommendation {
                VStack {
                    ForEach(Array(semesters.enumerated()), id: \.offset) { index, courses in
                        let amount = courses.count
                        let credits = courses.reduce(0) { $0 + $1.credits }
                        
                        NavigationLink {
                            TemplateSemesterOverviewView(courses: $semesters, semesterNumber: index, isEditing: false, semesterTitle: "\(Int(recommendation.currentSemester) + index + 1). Semester")
                        } label: {
                            ZStack {
                                Color(UIColor.secondarySystemGroupedBackground)
                                
                                HStack {
                                    Text("\((Int(recommendation.currentSemester) + index + 1))")
                                        .font(.system(size: 33, weight: .semibold, design: .rounded))
                                        .foregroundStyle(AppConstants.DefaultObjects.colors[index])
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
            }
        }
    }
}

#Preview {
    RecommendationsSemesterView(viewModel: RecommendationsViewModel(), recommendation: .constant(nil), semesters: [], isLoading: false)
}
