//
//  WelcomeScreen.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 12.11.24.
//

import SwiftUI
import CoreData
import SimpleAnalytics

struct OnboardingView: View {
    @Environment(\.openURL) var openURL
    @StateObject private var viewModel: OnboardingViewModel = OnboardingViewModel()
    
    @State var name: String = ""
    @State var selectedInterests: Set<String> = []
    
    @State var progress: Int = 0
    @State var isAlertShown = false
    @State var isNameAlertShown = false
    @State var isInterestsAlertShown = false
    @State var isiCloudAlertShown = false
    
    @State var isLoading: Bool = false
    
    var body: some View {
        VStack {
            
            switch progress {
            case 0:
                welcome
                    .background(Color(UIColor.systemGroupedBackground))
            case 1:
                importData
            case 2:
                nameView
            case 3:
                interests
            case 4:
                semester
            default:
                OnboardingCoursesView(viewModel: viewModel)
            }
            
            if(progress != 1) {
                ZStack {
                    Color("Color1")
                    
                    if(!isLoading) {
                        Text("Continue")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    } else {
                        HStack {
                            ProgressView()
                            Text("Loading")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 54)
                .cornerRadius(15)
                .padding(.horizontal, 16)
                .onTapGesture {
                    Task {
                        if(progress == 4) {
                            if(isLoading) {
                                return
                            }
                            
                            do {
                                isLoading = true
                                try await viewModel.createDefaultCourses()
                                isLoading = false
                            } catch {
                                isAlertShown = true
                                return
                            }
                        }
                        
                        if(progress == 2 && (name.isEmpty || name.count > 30)) {
                            isNameAlertShown = true
                            return
                        }
                        
                        if(progress == 3 && selectedInterests.count <= 2) {
                            isInterestsAlertShown = true
                            return
                        }
                        
                        if(progress <= 4) {
                            progress += 1
                        } else {
                            SimpleAnalytics.shared.track(event: "finished onboarding")
                            
                            CloudKitPreferencesManager.shared.setUserName(name)
                            CloudKitPreferencesManager.shared.setOldUser(true)
                            CloudKitPreferencesManager.shared.setInterests(Interests(titles: Array(selectedInterests)))
                            
                            UserDefaults.standard.setValue("1.1", forKey: "currentVersion")
                        }
                    }
                }
                .padding(.bottom, 10)
                .alert("Error", isPresented: $isAlertShown) {
                    Button {
                        isAlertShown = false
                    } label: {
                        Text("Ok")
                    }
                } message: {
                    Text("Please check your connection and try again.")
                }
                .alert("Name", isPresented: $isNameAlertShown) {
                    Button {
                        isNameAlertShown = false
                    } label: {
                        Text("Ok")
                    }
                } message: {
                    Text("Please choose a name between 1 and 30 characters.")
                }
                .alert("Interests", isPresented: $isInterestsAlertShown) {
                    Button {
                        isInterestsAlertShown = false
                    } label: {
                        Text("Ok")
                    }
                } message: {
                    Text("Please choose at least 3 interests.")
                }
            }
        }
        .onAppear {
            SimpleAnalytics.shared.track(path: ["onboarding"])
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    var importData: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("Would you like to start fresh or import existing data from another device via iCloud?")
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 20, weight: .semibold))
                    
                    Spacer()
                    
                    ZStack {
                        Color("Color1")
                        
                        VStack(spacing: 25) {
                            VStack(spacing: 5) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 30, weight: .semibold))
                                Text("Start fresh")
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            .padding(.top, 25)
                            .onTapGesture {
                                progress += 1
                            }
                            
                            Divider()
                                .background(Color.white)
                            
                            VStack(spacing: 5) {
                                Image(systemName: "cloud.fill")
                                    .font(.system(size: 30, weight: .semibold))
                                Text("Use iCloud")
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            .padding(.bottom, 25)
                            .onTapGesture {
                                isiCloudAlertShown = true
                            }
                            .alert("Error", isPresented: $isiCloudAlertShown) {
                                Button {
                                    isiCloudAlertShown = false
                                } label: {
                                    Text("Ok")
                                }
                            } message: {
                                Text("To view and edit data from another device, please follow these steps:\n\n1. On the other device whose data you wish to sync, open the ETH Study Planner settings and enable the \"iCloud Sync\" option. Note that it may take a few moments for the data to upload.\n\n2. Restart the app on this device and wait briefly.\n\nIf these steps do not work, ensure that you are signed in with the same Apple ID on both devices and that you have sufficient iCloud storage space.\n\nImportant: Do not proceed with \"Start Fresh\" onboarding on this device, as doing so may cause synchronization issues.\n\nIf you have any questions or encounter any problems, please contact us at studyplanner.ch.")
                            }
                        }
                        .padding(.horizontal)
                    }
                    .cornerRadius(10)
                    .padding(.top, -5)
                    .padding(.bottom, 30)
                    
                    Spacer()
                }
                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20)
                .navigationTitle("Import Data")
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
    
    var semester: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    ProgressBar(progress: 2, amountOfSteps: 4)
                    
                    Text("How many semesters do you plan to study in total?")
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 20, weight: .semibold))
                    
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
                            
                            
                            Text("Semesters: \(viewModel.amountOfSemesters)")
                                .font(.system(size: 20, weight: .semibold))
                            
                            Spacer()
                            
                            Stepper("Semesters", value: $viewModel.amountOfSemesters, in: 4...10)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 12)
                    }
                    .frame(height: 52)
                    .cornerRadius(10)
                    .padding(.top, -5)
                    .padding(.bottom, 30)
                    
                    Text("Which semester are you in?")
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 20, weight: .semibold))
                    
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
                            
                            Stepper("Semesters", value: $viewModel.currentSemester, in: 0...(viewModel.amountOfSemesters - 1))
                                .labelsHidden()
                        }
                        .padding(.horizontal, 12)
                    }
                    .frame(height: 52)
                    .cornerRadius(10)
                    .padding(.top, -5)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .navigationTitle("Semesters")
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
    
    var interests: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    ProgressBar(progress: 1, amountOfSteps: 4)
                    
                    ZStack {
                        Color(UIColor.systemGray2)
                        
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 25, weight: .semibold))
                            Text("Choose at least 3 interests.")
                                .foregroundStyle(.white)
                                .font(.system(size: 15, weight: .semibold))
                            
                            Spacer()
                        }
                        .padding(.leading, 3)
                        .padding(10)
                    }
                    .cornerRadius(15)
                    
                    InterestsCloud(selectedInterests: $selectedInterests)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .navigationTitle("Your Interests")
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
    
    var nameView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    ProgressBar(progress: 0, amountOfSteps: 4)
                    
                    ZStack {
                        Color(UIColor.systemGray2)
                        
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 25, weight: .semibold))
                            Text("We use your name to personalise the app for you. It will be published with your templates. You can change it at any time in the settings.")
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
                                
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 32, height: 32)
                            .cornerRadius(5)
                            
                            TextField("Name", text: $name)
                                .font(.system(size: 17, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                    }
                    .frame(height: 52)
                    .cornerRadius(10)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .navigationTitle("Your Name")
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
    
    var welcome: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 15) {
                    
                    Spacer()
                    
                    Image(systemName: "graduationcap.fill")
                        .foregroundStyle(Color("Color1"))
                        .font(.system(size: 50, weight: .semibold))
                    Text("Let's start by setting up \nthe app for you.")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 30, weight: .semibold))
                    
                    Spacer()
                    
                    Text("ETH Study Planner is neither supported by ETH nor by VSETH, its a private initiative run by Students. \n\nCourse data taken from vvz.ethz.ch. No guarantee for accuracy and completeness. \n\nBy continuing to use the app, you agree to the privacy policy (can be viewed here)")
                        .font(.system(size: 17, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(UIColor.systemGray))
                        .padding(.bottom, 20)
                        .onTapGesture {
                            openURL(URL(string: "https://study-planner.notion.site/Data-Privacy-143e068d9afc80c99501f18a5bbedae0")!)
                        }
                }
                .padding(.horizontal, 16)
                .navigationTitle("Welcome")
            }
        
        }
    }
}

struct InterestsCloud: View {
    @Binding var selectedInterests: Set<String>
    
    var body: some View {
        WordCloudLayout(spacing: 8) {
            ForEach(AppConstants.Tags.interests, id: \.self) { word in
                Text("#\(word)")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(selectedInterests.contains(word) ? Color("Color1") : Color(UIColor.secondarySystemGroupedBackground))
                    .foregroundColor(selectedInterests.contains(word) ? .white : Color(UIColor.label))
                    .cornerRadius(30)
                    .lineLimit(1)
                    .fixedSize()
                    .onTapGesture {
                        if selectedInterests.contains(word) {
                            selectedInterests.remove(word)
                        } else {
                            selectedInterests.insert(word)
                        }
                    }
            }
        }
    }
}

struct ProgressBar: View {
    @State var progress: Int
    @State var amountOfSteps: Int
    
    var body: some View {
        HStack {
            ForEach(0..<amountOfSteps, id: \.self) { step in
                Rectangle()
                    .foregroundStyle(progress >= step ? Color("Color1") : Color(UIColor.systemGray3))
                    .frame(height: 10)
                    .cornerRadius(10)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
