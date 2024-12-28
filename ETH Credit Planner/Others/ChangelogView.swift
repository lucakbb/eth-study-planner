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
    @Binding var isPresented: Bool
    @State var isGithubLinkShown: Bool = false
    
    var body: some View {
            VStack {
                ZStack {
                    Color("Color1")
                    
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 23))
                                .padding()
                                .onTapGesture {
                                    isPresented = false
                                }
                        }
                        
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
                .frame(height: 150)
                
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
                                    Text("\u{2022} Added the ability to share templates via a direct link.")
                                    Text("\u{2022} When adding a course, it is now easier to see if it is not offered in a semester.")
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
                    Text("Continue")
                        .foregroundStyle(.white)
                        .font(.system(size: 20, weight: .semibold))
                        .padding(12)
                }
                .frame(height: 54)
                .cornerRadius(15)
                .padding(.horizontal)
                .onTapGesture {
                    isPresented = false
                }
            }
            .onDisappear(perform: {
                UserDefaults.standard.setValue("1.1", forKey: "currentVersion")
                updateErgaenzungMaxCredits()
                
                SimpleAnalytics.shared.track(event: "dismissedChangelog")
            })
        
    }
    
    @MainActor
    func updateErgaenzungMaxCredits() {
        let viewContext = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == 3")
        
        do {
            let categories = try viewContext.fetch(fetchRequest)
            
            if(categories.count == 1) {
                let category = categories[0]
                category.maxCredits = 10
                
                try viewContext.save()
            }
        } catch {
            print("error: \(error)")
        }
    }
}

#Preview {
    Text("Hello, world!")
        .sheet(isPresented: .constant(true)) {
            ChangelogView(isPresented: .constant(true))
        }
}
