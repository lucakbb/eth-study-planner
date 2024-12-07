//
//  ContentView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 03.11.24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("oldUser") private var oldUser = false
    @AppStorage("BVersionRecommendations") private var bVersion = false
    @AppStorage("recommendationsEnabled") private var recommendationsEnabled = true
    
    var body: some View {
        if(oldUser) {
            TabView {
                StudyPlanView()
                    .tabItem {
                        Label("Study Plan", systemImage: "doc.text")
                    }
                
                SearchView()
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                
                if(!bVersion) {
                    if(recommendationsEnabled) {
                        RecommendationsView()
                            .tabItem {
                                Label("Recommendations", systemImage: "star.fill")
                            }
                    }
                }
                
                TemplateLibraryView()
                    .tabItem {
                        Label("Templates", systemImage: "rectangle.stack")
                    }
            }
            .accentColor(Color("Color3"))
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let viewModel = OnboardingViewModel()
    let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
    
    do {
        if try context.count(for: fetchRequest) == 0 {
            Task {
                try await viewModel.createDefaultCourses()
            }
        }
    } catch {
        print("Error checking or creating default courses: \(error)")
    }
    
    do {
        if try context.fetch(fetchRequest).count > 0 {
            return ContentView().environment(\.managedObjectContext, context)
        } else {
            return Text("No categories found")
        }
    } catch {
        return Text("Error loading categories: \(error.localizedDescription)")
    }
}
