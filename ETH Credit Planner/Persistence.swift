//
//  Persistence.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 03.11.24.
//

import CoreData

class PersistenceController {
    static private var _shared: PersistenceController?
    static var shared: PersistenceController {
        if _shared == nil {
            _shared = PersistenceController()
        }
        return _shared!
    }

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let useCloudSync = CloudKitPreferencesManager.shared.getICloudSync()

        if useCloudSync {
            let cloudContainer = NSPersistentCloudKitContainer(name: "ETH_Credit_Planner")
            if let description = cloudContainer.persistentStoreDescriptions.first {
                description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.hci.ETHCreditPlanner")
                description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            }
            
            container = cloudContainer
        } else {
            container = NSPersistentContainer(name: "ETH_Credit_Planner")
        }

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

       
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("Persistent Store loaded: \(storeDescription.url?.absoluteString ?? "Unknown URL")")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    static func toggleICloudSync(enabled: Bool) {
        CloudKitPreferencesManager.shared.setICloudSync(enabled)

        if(enabled) {
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
        }
        
        _shared = PersistenceController()
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
            
            let passedCount1 = courses1.filter { ($0.value(forKey: "isPassed") as? Bool) == true }.count
            let passedCount2 = courses2.filter { ($0.value(forKey: "isPassed") as? Bool) == true }.count
            
            if passedCount1 != passedCount2 {
                return passedCount1 > passedCount2
            }
            
            return false
        }
        
        return sortedDuplicates.first
    }
}
