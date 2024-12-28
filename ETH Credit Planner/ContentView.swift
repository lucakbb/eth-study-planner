//
//  ContentView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 03.11.24.
//

import SwiftUI
import CoreData
import SimpleAnalytics

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @AppStorage("oldUser") private var oldUser = false
    @AppStorage("recommendationsEnabled") private var recommendationsEnabled = true

    @State private var selectedMenu: MenuItem? = .semesters
    @State private var isCreditOverviewShown = false
    @State private var isChangelogShown = false
    
    @State private var sharedTemplate: Template? = nil
    
    var body: some View {
        if(oldUser || CloudKitPreferencesManager.shared.getOldUser()) {
            if UIDevice.current.userInterfaceIdiom == .phone {
                TabView {
                    StudyPlanView()
                        .onAppear {
                            PersistenceController.shared.cleanUpDuplicates()
                        }
                        .tabItem {
                            Label("Study Plan", systemImage: "doc.text")
                        }
                    
                    SearchView()
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                    
                    if(recommendationsEnabled) {
                        RecommendationsView()
                            .tabItem {
                                Label("Recommendations", systemImage: "star.fill")
                            }
                    }
                    
                    TemplateLibraryView()
                        .tabItem {
                            Label("Templates", systemImage: "rectangle.stack")
                        }
                }
                .onOpenURL { incomingURL in
                    Task {
                        print("App was opened via URL: \(incomingURL)")
                        sharedTemplate = await URLHandler.shared.handleIncomingURL(incomingURL)
                    }
                }
                .onAppear {
                    if(UserDefaults.standard.string(forKey: "currentVersion") != "1.1") {
                        isChangelogShown = true
                    }
                }
                .sheet(isPresented: $isChangelogShown) {
                    ChangelogView(isPresented: $isChangelogShown)
                }
                .sheet(item: $sharedTemplate) { template in
                    NavigationStack {
                        TemplateOverviewView(template: .constant(template), color: Color("Color1"))
                            .toolbar {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color(UIColor.systemGray3))
                                    .onTapGesture {
                                        sharedTemplate = nil
                                    }
                            }
                    }
                }
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                NavigationSplitView {
                    VStack {
                        List(selection: $selectedMenu) {
                            Section(header: Text("Study Plan")) {
                                NavigationLink(value: MenuItem.semesters) {
                                    Label("Semesters", systemImage: "calendar")
                                }
                                NavigationLink(value: MenuItem.categories) {
                                    Label("Categories", systemImage: "tray.full.fill")
                                }
                            }
                            
                            Section(header: Text("Explore")) {
                                NavigationLink(value: MenuItem.search) {
                                    Label("Search", systemImage: "magnifyingglass")
                                }
                                NavigationLink(value: MenuItem.recommendations) {
                                    Label("Recommendations", systemImage: "star.fill")
                                }
                                NavigationLink(value: MenuItem.templates) {
                                    Label("Templates", systemImage: "rectangle.stack.fill")
                                }
                            }
                            
                            Section(header: Text("More")) {
                                NavigationLink(value: MenuItem.settings) {
                                    Label("Settings", systemImage: "gear")
                                }
                            }
                        }
                        .listStyle(SidebarListStyle())
                        .navigationTitle("Study Planner")
                        .scrollContentBackground(.hidden)
                        .background(Color(UIColor.systemGroupedBackground))
                    }
                    .background(Color(UIColor.systemGroupedBackground))
                } detail: {
                    if let selectedMenu = selectedMenu {
                        selectedMenu.view
                    }
                }
                .onAppear {
                    if(UserDefaults.standard.string(forKey: "currentVersion") != "1.1") {
                        isChangelogShown = true
                    }
                }
                .sheet(isPresented: $isChangelogShown) {
                    ChangelogView(isPresented: $isChangelogShown)
                }
            }
        } else {
            OnboardingView()
        }
    }
}

enum MenuItem: String, CaseIterable, Hashable, Identifiable {
    case semesters
    case categories
    case search
    case recommendations
    case templates
    case settings
    
    var id: String { rawValue }
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .semesters:
            SemesterCatalystView()
        case .categories:
            CategoryCatalystView()
        case .search:
            SearchView()
        case .recommendations:
            RecommendationsView()
        case .templates:
            TemplateLibraryView()
        case .settings:
            SettingsView()
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

struct SemesterCatalystView: View {
    @State var isCreditOverviewShown = false
    
    var body: some View {
        NavigationStack {
            SemesterView(isCreditOverviewShown: $isCreditOverviewShown)
                .padding(.horizontal, 16)
                .background(Color(UIColor.systemGroupedBackground))
                .navigationTitle("Semesters")
                .sheet(isPresented: $isCreditOverviewShown) {
                    CreditsOverviewView(isPresented: $isCreditOverviewShown)
                }
                .onAppear {
                    PersistenceController.shared.cleanUpDuplicates()
                }
        }
    }
}

struct CategoryCatalystView: View {
    @State var isCreditOverviewShown = false
    
    var body: some View {
        NavigationStack {
            CategoryView(isCreditOverviewShown: $isCreditOverviewShown)
                .padding(.horizontal, 16)
                .background(Color(UIColor.systemGroupedBackground))
                .navigationTitle("Categories")
                .sheet(isPresented: $isCreditOverviewShown) {
                    CreditsOverviewView(isPresented: $isCreditOverviewShown)
                }
        }
    }
}
