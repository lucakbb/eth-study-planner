//
//  RecommendationsView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 21.11.24.
//

import SwiftUI
import SimpleAnalytics

struct RecommendationsView: View {
    let viewContext = PersistenceController.shared.container.viewContext
    let dateformatter = DateFormatter()
    
    @State var viewModel: RecommendationsViewModel = RecommendationsViewModel()
    @State var isOnboardingIsShown: Bool = false
    
    @State private var recommendationPopup: Recommendation?
    
    @State var resultText: String = ""
    @State var firestoreCourses: [[FirestoreCourse]] = []

    @FetchRequest(
        entity: Recommendation.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Recommendation.date, ascending: false)]
    ) var recommendations: FetchedResults<Recommendation>
    
    init() {
        dateformatter.dateFormat = "MM/dd/YYYY"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    ZStack {
                        Color(UIColor.systemGray2)
                        
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 25, weight: .semibold))
                            Text("Unsure how you want to plan your upcoming semesters? Generate course suggestions based on your interests, current study plan and course ratings.")
                                .foregroundStyle(.white)
                                .font(.system(size: 15, weight: .semibold))
                            
                            Spacer()
                        }
                        .padding(.leading, 3)
                        .padding(10)
                    }
                    .cornerRadius(15)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Get Recommendations")
                            .font(.system(size: 20, weight: .semibold))
                        
                            ZStack {
                                Color("Color1")
                                
                                HStack {
                                    ZStack {
                                        Color(.white)
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(Color("Color1"))
                                    }
                                    .frame(width: 30, height: 30)
                                    .cornerRadius(10)
                                    
                                    Text("Generate Study Plan")
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
                        .onTapGesture {
                            isOnboardingIsShown = true
                        }
                    }
                   
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Previously Generated")
                            .font(.system(size: 20, weight: .semibold))
                        
                        recommendationList
                    }
                    
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("Recommendations")
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear {
                SimpleAnalytics.shared.track(path: ["recommendations"])
            }
            .fullScreenCover(isPresented: $isOnboardingIsShown) {
                RecommendationsOnboarding(isPresented: $isOnboardingIsShown)
            }
            .sheet(item: $recommendationPopup) { recommendation in
                RecommendationsSemesterView(recommendation: $recommendationPopup)
            }
        }
    }
    
    var recommendationList: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(recommendations, id: \.self) { recommendation in
                Button {
                    if recommendationPopup != recommendation {
                        recommendationPopup = recommendation
                    }
                } label: {
                    ZStack {
                        Color(UIColor.secondarySystemGroupedBackground)
                        
                        HStack(spacing: 10) {
                            ZStack {
                                Color(Color("Color1"))
                                Image(systemName: "tray.full.fill")
                                    .font(.system(size: 21, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 39, height: 39)
                            .cornerRadius(10)
                            
                            VStack(alignment: .leading, spacing: -1) {
                                Text("\(recommendation.amountOfSemesters) Semesters")
                                    .foregroundStyle(Color(UIColor.label))
                                    .font(.system(size: 21, weight: .semibold))
                                
                                Text("\(dateformatter.string(from: Date()))")
                                    .foregroundStyle(Color(UIColor.systemGray2))
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color(UIColor.systemGray3))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .cornerRadius(15)
                }
                .contextMenu {
                    Button {
                        viewContext.delete(recommendation)
                        
                        do {
                            try viewContext.save()
                        } catch {
                            print("\(error)")
                        }
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
            }
        }
    }
}

#Preview {
    RecommendationsView()
}
