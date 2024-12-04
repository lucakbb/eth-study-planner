//
//  Persistence.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 03.11.24.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        let firstYearCourses = Category(context: viewContext)
        firstYearCourses.id = 0
        firstYearCourses.name = "First Year Courses"
        firstYearCourses.icon = "book.closed.fill"
        firstYearCourses.maxCredits = 56
        firstYearCourses.minCredits = 56
        
        let basicCourses = Category(context: viewContext)
        basicCourses.id = 1
        basicCourses.name = "Basic Courses"
        basicCourses.icon = "lightbulb.max.fill"
        basicCourses.maxCredits = 52
        basicCourses.minCredits = 45
        
        let coreCourses = Category(context: viewContext)
        coreCourses.id = 2
        coreCourses.name = "Core Courses"
        coreCourses.icon = "star.fill"
        coreCourses.maxCredits = 180
        coreCourses.minCredits = 32
        
        let minorCourses = Category(context: viewContext)
        minorCourses.id = 3
        minorCourses.name = "Minor Courses"
        minorCourses.icon = "flask.fill"
        minorCourses.maxCredits = 180
        minorCourses.minCredits = 5
        
        let electives = Category(context: viewContext)
        electives.id = 4
        electives.name = "Electives"
        electives.icon = "text.page.badge.magnifyingglass"
        electives.maxCredits = 180
        electives.minCredits = 0
        
        let gess = Category(context: viewContext)
        gess.id = 5
        gess.name = "Science in Perspective"
        gess.icon = "binoculars.fill"
        gess.maxCredits = 6
        gess.minCredits = 6
        
        let seminar = Category(context: viewContext)
        seminar.id = 6
        seminar.name = "Seminar"
        seminar.icon = "document.on.document.fill"
        seminar.maxCredits = 2
        seminar.minCredits = 2
        
        let thesis = Category(context: viewContext)
        thesis.id = 7
        thesis.name = "Bachelor Thesis"
        thesis.icon = "pencil"
        thesis.maxCredits = 10
        thesis.minCredits = 10
        
        let semester1 = Semester(context: viewContext)
        semester1.number = 1
        
        do {
            try viewContext.save()
        } catch {
            print(error)
        }
        
        return result
        
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ETH_Credit_Planner")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                print(error)
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
