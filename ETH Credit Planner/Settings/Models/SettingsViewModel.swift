//
//  TemplateLibraryView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 18.11.24.
//

import Foundation
import SafariServices
import CoreData

class SettingsModel: ObservableObject {
    let viewContext = PersistenceController.shared.container.viewContext
    
    func writeReview() {
        #if os(iOS)
        let urlStr = "https://apps.apple.com/app/eth-credit-planner/id6737737758?action=write-review"
        guard
            let url = URL(string: urlStr),
            UIApplication.shared.canOpenURL(url)
        else { return }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)

        #elseif os(macOS)
        let urlStr = "macappstore://itunes.apple.com/app/id6737737758?action=write-review"
        guard let url = URL(string: urlStr) else { return }

        NSWorkspace.shared.open(url)
        
        #endif
    }
    
    func getVersionInformation() -> String {
        return "Version: " + Bundle.main.appVersion + "(" + Bundle.main.buildNumber + ")"
    }
    
    func addNewSemester(number: Int) {
        let newSemester = Semester(context: viewContext)
        newSemester.number = Int16(number)

        do {
            try viewContext.save()
        } catch {
            print(print(error))
        }
    }
    
    func deleteSemester(semester: Int) {
        let fetchRequest: NSFetchRequest<Semester> = Semester.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "number == %d", semester)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            
            for semester in results {
                viewContext.delete(semester)
            }

            if viewContext.hasChanges {
                try viewContext.save()
            }
        } catch {
            print("\(error.localizedDescription)")
        }
    }
}

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}

