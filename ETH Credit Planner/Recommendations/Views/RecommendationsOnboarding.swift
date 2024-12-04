//
//  RecommendationsOnboarding.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 21.11.24.
//

import SwiftUI
import SimpleAnalytics

struct RecommendationsOnboarding: View {
    @StateObject var viewModel: RecommendationsAPI = RecommendationsAPI()
    @Binding var isPresented: Bool
    
    @State var progress: Int = 0
    @State var isLoading: Bool = false
    @State var isAlertShown: Bool = false
    
    var body: some View {
        if(!isLoading) {
            NavigationStack {
                VStack {
                    
                    switch progress {
                    case 0:
                        totalSemesters
                    default:
                        workload
                    }
                    
                    ZStack {
                        Color("Color1")
                        
                        Text("Continue")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(height: 54)
                    .cornerRadius(15)
                    .padding(.horizontal, 16)
                    .onTapGesture {
                        if(progress == 0) {
                            for _ in 0...(viewModel.totalSemester - (viewModel.currentSemester + 1)) {
                                viewModel.maxCredits.append(35)
                            }
                            
                            progress += 1
                        } else {
                            SimpleAnalytics.shared.track(event: "requested recommendations")
                            isLoading = true
                            
                            viewModel.fetchAPIResult() { result in
                                switch result {
                                case .success(_):
                                    isLoading = false
                                    isPresented = false
                                case .failure(let error):
                                    print("ERROR: \(error)")
                                    isAlertShown = true
                                }
                            }
                        }
                    }
                    .padding(.bottom, 10)
                }
                .background(Color(UIColor.systemGroupedBackground))
                .toolbar {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(UIColor.systemGray3))
                        .onTapGesture {
                            isPresented = false
                        }
                }
                .onAppear {
                    SimpleAnalytics.shared.track(path: ["recommendations", "onboarding"])
                }
                .alert("Error", isPresented: $isAlertShown) {
                    Button {
                        isLoading = false
                        isAlertShown = false
                        isPresented = false
                    } label: {
                        Text("Ok")
                    }
                } message: {
                    Text("It was not possible to generate a valid study plan.")
                }
            }
        } else {
            NavigationStack {
                loadingView
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
    
    
    var totalSemesters: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                ProgressBar(progress: 0, amountOfSteps: 2)
                
                ZStack {
                    Color(UIColor.systemGray2)
                    
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 25, weight: .semibold))
                        Text("Please select the total number of semesters you are planning for your Bachelor's degree.")
                            .foregroundStyle(.white)
                            .font(.system(size: 15, weight: .semibold))
                        
                        Spacer()
                    }
                    .padding(.leading, 3)
                    .padding(10)
                }
                .cornerRadius(15)
                
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
                        
                        
                        Text("Semesters: \(viewModel.totalSemester)")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Spacer()
                        
                        Stepper("Semesters", value: $viewModel.totalSemester, in: 1...10)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 12)
                }
                .frame(height: 52)
                .cornerRadius(10)
                .padding(.top, -5)
                .padding(.bottom, 30)
                
                ZStack {
                    Color(UIColor.systemGray2)
                    
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 25, weight: .semibold))
                        Text("Please select the semester you are currently in. We are going to generate the study from you current semester onwards.")
                            .foregroundStyle(.white)
                            .font(.system(size: 15, weight: .semibold))
                        
                        Spacer()
                    }
                    .padding(.leading, 3)
                    .padding(10)
                }
                .cornerRadius(15)
                
                
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
                        
                        
                        Text("\(viewModel.currentSemester + 1). Semester")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Spacer()
                        
                        Stepper("Semesters", value: $viewModel.currentSemester, in: 0...(viewModel.totalSemester - 1))
                            .labelsHidden()
                    }
                    .padding(.horizontal, 12)
                }
                .frame(height: 52)
                .cornerRadius(10)
                .padding(.top, -5)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Recommendations")
        .padding(.horizontal, 16)
    }
    
    var workload: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                
                ProgressBar(progress: 1, amountOfSteps: 2)
                
                ZStack {
                    Color(UIColor.systemGray2)
                    
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 25, weight: .semibold))
                        Text("Please select the maximum number of credits you would like to take during the upcoming semester.")
                            .foregroundStyle(.white)
                            .font(.system(size: 15, weight: .semibold))
                        
                        Spacer()
                    }
                    .padding(.leading, 3)
                    .padding(10)
                }
                .cornerRadius(15)
                
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0...(viewModel.totalSemester - (viewModel.currentSemester + 1)), id: \.self) { semester in
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\((viewModel.currentSemester + 1) + semester). Semester")
                                .font(.system(size: 22, weight: .semibold))
                            
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
                                    
                                    
                                    Text("Max Credits: \(viewModel.maxCredits[semester])")
                                        .font(.system(size: 20, weight: .semibold))
                                    
                                    Spacer()
                                    
                                    Stepper("Semesters", value: $viewModel.maxCredits[semester], in: 0...50)
                                        .labelsHidden()
                                }
                                .padding(.horizontal, 12)
                            }
                            .frame(height: 52)
                            .cornerRadius(10)
                            .padding(.top, -5)
                            .padding(.bottom, 30)
                        }
                         
                    }
                }
                
            }
        }
        .navigationTitle("Recommendations")
        .padding(.horizontal, 16)
    }
    
    var loadingView: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 10) {
                Spacer()
                
                ProgressView()
                Text("Generating Study Plan")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(UIColor.systemGray2))
                
                Spacer()
            }
        }
    }
}




#Preview {
    RecommendationsOnboarding(isPresented: .constant(true))
}
