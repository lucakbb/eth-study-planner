//
//  ChangelogView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 24.12.24.
//

import SwiftUI
import SimpleAnalytics
import CoreData

struct ChangelogView: View {
    @StateObject var viewModel: ChangelogViewModel = ChangelogViewModel()
    
    @Binding var isPresented: Bool
    @State var isGithubLinkShown: Bool = false
    
    var body: some View {
            VStack {
                ZStack {
                    Color("Color1")
                    
                    VStack {
                        Spacer()
                        
                        HStack {
                            Text("Changelog")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                            Spacer()
                        }
                    }
                }
                .frame(height: 170)
                
                ScrollView(.vertical) {
                    VStack {
                        ZStack {
                            Color(.tertiarySystemGroupedBackground)
                            
                            VStack(spacing: 10) {
                                HStack {
                                    ZStack {
                                        Color("Color1")
                                        Image(systemName: "star.fill")
                                            .cornerRadius(10)
                                            .foregroundColor(.white)
                                            .font(.system(size: 15, weight: .semibold))
                                        Spacer()
                                    }
                                    .frame(width: 27, height: 27)
                                    .cornerRadius(5)
                                    
                                    Text("New in this version")
                                        .font(.system(size: 20, weight: .semibold))
                                    Spacer()
                                }
                                .padding(.top)
                                .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("\u{2022} The app is now also available on iPad and Mac.")
                                    Text("\u{2022} Your study plan can now be transferred to multiple devices via iCloud. To do this, activate “iCloud Sync” in the settings.")
                                    Text("\u{2022} Courses, such as Soccer Analytics, which are offered in two categories, are now listed for each of these categories.")
                                    Text("\u{2022} Courses can now be marked as failed and added to multiple semesters.")
                                    Text("\u{2022} Added the ability to share templates via a direct link.")
                                }
                                .padding(.bottom)
                                .padding(.horizontal)
                            }
                        }
                        .cornerRadius(15)
                        .padding()
                    }
                    
                   
                    VStack {
                        ZStack {
                            Color(.tertiarySystemGroupedBackground)
                            
                            VStack(spacing: 10) {
                                HStack {
                                    ZStack {
                                        Color("Color1")
                                        Image(systemName: "info")
                                            .cornerRadius(10)
                                            .foregroundColor(.white)
                                            .font(.system(size: 15, weight: .semibold))
                                        Spacer()
                                    }
                                    .frame(width: 27, height: 27)
                                    .cornerRadius(5)
                                    
                                    Text("GitHub")
                                        .font(.system(size: 20, weight: .semibold))
                                    Spacer()
                                }
                                .padding(.top)
                                .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("The app code is now available on Github. We appreciate any form of help. If you have noticed a bug, we would be happy if you create an issue.")
                                    
                                    HStack(spacing: 5) {
                                        Spacer()
                                        Image(systemName: "arrow.up.forward.square")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(Color("Color3"))
                                        Text("Link to GitHub")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(Color("Color3"))
                                        Spacer()
                                    }
                                    .padding(.vertical, 10)
                                    .onTapGesture {
                                        isGithubLinkShown = true
                                    }
                                    .sheet(isPresented: $isGithubLinkShown) {
                                        SafariView(url: URL(string: "https://github.com/lucakbb/eth-study-planner")!)
                                    }
                                    
                                }
                                .padding(.bottom)
                                .padding(.horizontal)
                            }
                        }
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
              
                    
                }
                
                ZStack {
                    Color("Color1")
                    
                    if(!viewModel.isLoading) {
                        Text("Continue")
                            .foregroundStyle(.white)
                            .font(.system(size: 20, weight: .semibold))
                            .padding(12)
                    } else {
                        HStack {
                            ProgressView()
                            Text("Loading")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(12)
                    }
                    
                }
                .frame(height: 54)
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.bottom, 15)
                .onTapGesture {
                    viewModel.updateErgaenzungMaxCredits()
                    viewModel.migrateCourseStatus()
                    
                    SimpleAnalytics.shared.track(event: "dismissedChangelog")
                    UserDefaults.standard.setValue("1.1", forKey: "currentVersion")
                    isPresented = false
                }
            }
            .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    Text("Hello, world!")
        .fullScreenCover(isPresented: .constant(true)) {
            ChangelogView(isPresented: .constant(true))
        }
}
