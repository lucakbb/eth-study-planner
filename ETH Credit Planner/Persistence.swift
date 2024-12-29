//
//  Persistence.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 03.11.24.
//

import CoreData
import CloudKit

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    private var cloudOptionsToKeep: NSPersistentCloudKitContainerOptions? = nil
    
    lazy var container: NSPersistentContainer = {
        return createContainer()
    }()
    
    private func createContainer() -> NSPersistentContainer {
        let useCloudSync = CloudKitPreferencesManager.shared.getICloudSync()
        let modelURL = Bundle.main.url(forResource: "ETH_Credit_Planner", withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        
        let newContainer = useCloudSync ? NSPersistentCloudKitContainer(name: "ETH_Credit_Planner", managedObjectModel: model)
                                     : NSPersistentContainer(name: "ETH_Credit_Planner", managedObjectModel: model)
        
        guard let description = newContainer.persistentStoreDescriptions.first else {
            fatalError("No description found")
        }
        
        if useCloudSync {
            let options = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.hci.ETHCreditPlanner")
            description.cloudKitContainerOptions = options
            newContainer.viewContext.automaticallyMergesChangesFromParent = true
            newContainer.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        } else {
            description.cloudKitContainerOptions = nil
        }
        
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        newContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        return newContainer
    }

    private func setupContainer() {
        let useCloudSync = CloudKitPreferencesManager.shared.getICloudSync()
                
        // Save and reset context before detaching stores
        saveContext()
        container.viewContext.reset()
        
        let coordinator = container.persistentStoreCoordinator
        
        for store in coordinator.persistentStores {
            do {
                try coordinator.remove(store)
            } catch {
                fatalError("Error removing store: \(error)")
            }
        }

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Could not create or retrieve persistent container")
        }

        if useCloudSync {
            if let savedOptions = cloudOptionsToKeep {
                description.cloudKitContainerOptions = savedOptions
            } else {
                let options = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.hci.ETHCreditPlanner")
                description.cloudKitContainerOptions = options
                cloudOptionsToKeep = options
            }

            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        } else {
            description.cloudKitContainerOptions = nil
        }

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

    func toggleICloudSync(enabled: Bool) {
        CloudKitPreferencesManager.shared.setICloudSync(enabled)

        if enabled {
            NSUbiquitousKeyValueStore.default.set(UserDefaults.standard.bool(forKey: "oldUser"), forKey: "oldUser")
            NSUbiquitousKeyValueStore.default.set(UserDefaults.standard.string(forKey: "userName"), forKey: "userName")

            do {
                let interestsManager = InterestsManager()
                let interests = interestsManager.loadInterests()
                let encodedInterests = try JSONEncoder().encode(interests)
                NSUbiquitousKeyValueStore.default.set(encodedInterests, forKey: "interests")
            } catch {
                print("Failed to synchronize interests: \(error)")
            }
        } else {
            let container = CKContainer(identifier: "iCloud.com.hci.ETHCreditPlanner")
            let database = container.privateCloudDatabase

            database.delete(withRecordZoneID: .init(zoneName: "com.apple.coredata.cloudkit.zone"), completionHandler: { (zoneID, error) in
                if let error = error {
                    print("deleting zone error \(error.localizedDescription)")
                }
            })
        }

        setupContainer()
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func cleanUpDuplicates() {
        resolveDuplicates(for: "Semester", in: container.viewContext)
        resolveDuplicates(for: "Category", in: container.viewContext)
    }
    
    /// Attempts to find and remove duplicate objects for a given entity in the provided managed object context.
    /// This method identifies duplicates based on a unique identifier key, determines the "best" object for each duplicate set,
    /// and removes all other redundant objects. Finally, it saves the changes to the context.
    ///
    /// - Parameters:
    ///   - entityName: The name of the entity to inspect for duplicates.
    ///   - context: The NSManagedObjectContext in which duplicates should be resolved.
    private func resolveDuplicates(for entityName: String, in context: NSManagedObjectContext) {
        let uniqueKey = uniqueIDKey(for: entityName)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        
        do {
            let allObjects = try context.fetch(fetchRequest)
            
            // Hier wird der tatsächliche Wert geholt und je nach Typ in String konvertiert.
            let groupedObjects = Dictionary(grouping: allObjects) { object -> String in
                let value = object.value(forKey: uniqueKey)
                
                if let stringValue = value as? String {
                    return stringValue
                } else if let intValue = value as? Int16 {
                    return String(intValue)
                } else {
                    return ""
                }
            }
            
            for (uniqueID, duplicates) in groupedObjects {
                guard !uniqueID.isEmpty, duplicates.count > 1,
                      let bestObject = chooseBestObject(from: duplicates) else { continue }
                
                for object in duplicates where object != bestObject {
                    context.delete(object)
                }
            }
            
            try context.save()
        } catch {
            print("Failed to resolve duplicates for \(entityName): \(error.localizedDescription)")
        }
    }

    /// Provides the key name that uniquely identifies objects of a given entity.
    /// By customizing this logic per entity, one can flexibly determine how duplicates are identified.
    ///
    /// - Parameter entityName: The name of the entity.
    /// - Returns: The attribute name used to uniquely identify objects of the given entity.
    private func uniqueIDKey(for entityName: String) -> String {
        switch entityName {
        case "Semester":
            return "number"
        default:
            return "id"
        }
    }

    /// Determines the "best" object from a list of duplicate objects.
    /// The selection criteria can be customized, for example by prioritizing objects with more related courses,
    /// or those with the greatest number of passed courses.
    ///
    /// - Parameter duplicates: A non-empty list of objects considered duplicates.
    /// - Returns: The object deemed to be the best candidate or nil if none could be determined.
    private func chooseBestObject(from duplicates: [NSManagedObject]) -> NSManagedObject? {
        guard !duplicates.isEmpty else { return nil }
        
        let sortedDuplicates = duplicates.sorted { obj1, obj2 in
            let courses1 = (obj1.value(forKey: "courses") as? Set<NSManagedObject>) ?? []
            let courses2 = (obj2.value(forKey: "courses") as? Set<NSManagedObject>) ?? []
            
            if courses1.count != courses2.count {
                return courses1.count > courses2.count
            }
            
            let passedCount1 = courses1.filter { ($0.value(forKey: "status") as? String) == CourseStatus.passed.rawValue }.count
            let passedCount2 = courses2.filter { ($0.value(forKey: "status") as? String) == CourseStatus.passed.rawValue }.count
            
            if passedCount1 != passedCount2 {
                return passedCount1 > passedCount2
            }
            
            return false
        }
        
        return sortedDuplicates.first
    }
}
