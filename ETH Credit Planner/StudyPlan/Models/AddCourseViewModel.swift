//
//  AddCourseViewModel.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 11.11.24.
//

import Foundation
import Firebase

struct FirestoreCourse: Hashable, Decodable, Encodable, Equatable, Identifiable {
    var id: String
    var category: Int
    var credits: Int
    var name: String
    var semester: [Int]
    var tags: [String]
    var vvz: String
    
    static func == (lhs: FirestoreCourse, rhs: FirestoreCourse) -> Bool {
       return lhs.id == rhs.id
   }
}

class AddCourseViewModel: ObservableObject {
    @Published var sessions: Bool = false
    
    let cacheManager = FirestoreCacheManager()
    let recommendationsManager = RecommendationsManager()
    
    /// Generates an array of the last five semesters, including the current semester, which are displayed in the search filter.
    /// The semester format is "FSYY" for spring semester and "HSYY" for fall semester, where `YY` is the two-digit year.
    ///
    /// **Returns:**
    /// - An array of strings representing the last five semesters in descending order, starting with the current semester.
    ///
    /// Example output:
    /// ```
    /// ["HS24", "FS24", "HS23", "FS23", "HS22"]
    /// ```
    func getLastFiveSemesters() -> [String] {
        let calendar = Calendar.current
        let currentDate = Date()
        let currentYear = calendar.component(.year, from: currentDate)
        let currentWeek = calendar.component(.weekOfYear, from: currentDate)
        
        var currentSemester: String
        if (1...22).contains(currentWeek) {
            currentSemester = "FS\(currentYear % 100)"
        } else {
            currentSemester = "HS\(currentYear % 100)"
        }
        
        var semesters: [String] = [currentSemester]
        for _ in 1..<5 {
            if currentSemester.starts(with: "HS") {
                let year = Int(currentSemester.suffix(2))!
                currentSemester = "FS\(year)"
            } else if currentSemester.starts(with: "FS") {
                let year = Int(currentSemester.suffix(2))! - 1
                currentSemester = "HS\(year)"
            }
            semesters.append(currentSemester)
        }
        
        return semesters
    }
    
    /// Calculates the index of a semester for Firestore.
    /// - Parameter semester: A `String` representing the semester, formatted as "HSYY" or "FSYY",
    ///   where "HS" indicates a Herbstsemester (fall semester) and "FS" indicates a Frühjahrssemester (spring semester).
    /// - Returns: An `Int` representing the calculated semester index, or `nil` if the input format is invalid.
    /// - Behavior:
    ///   - Determines if the semester is an HS or FS based on its prefix.
    ///   - Extracts the year suffix (last two digits) and converts it to a full year (e.g., "19" becomes 2019).
    ///   - Calculates the index using the formula: `(year - 2019) * 2 + (isHs ? 1 : 0)`, where:
    ///     - `2019` is the reference year.
    ///     - Each year contributes 2 indices (one for FS and one for HS).
    ///     - HS semesters add an additional index offset of `1`.
    /// - Returns `nil` if the semester string is incorrectly formatted or invalid.
    func calculateSemesterIndex(from semester: String) -> Int? {
        let isHs = semester.hasPrefix("HS")
        let isFs = semester.hasPrefix("FS")
        
        guard isHs || isFs else { return nil }
        
        guard let yearSuffix = Int(semester.suffix(2)) else { return nil }
        let year = 2000 + yearSuffix
        
        return (year - 2019) * 2 + (isHs ? 1 : 0)
    }
    
    /// Calculates the index for the current Semester
    func calculateCurrentSemesterIndex() -> Int {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentWeek = calendar.component(.weekOfYear, from: Date())
        
        let isHs = (23...51).contains(currentWeek)
        
        return (currentYear - 2019) * 2 + (isHs ? 1 : 0)
    }
    
    func getCategoryRecommendations(semester: Int, category: Category) -> [FirestoreCourse] {
        return recommendationsManager.generateCategoryRecommendations(semesterID: semester, categoryID: Int(category.id))
    }
    
    func getSemesterRecommendations(semester: Int) -> [FirestoreCourse] {
        return recommendationsManager.generateSemesterRecommendations(semesterID: semester)
    }
    
    /// Fetches courses for a specified semester from Firestore.
    /// - Parameter semester: An `Int` representing the semester for which courses are being requested.
    /// - Returns: An array of `FirestoreCourse` objects corresponding to the specified semester.
    /// - Behavior:
    ///   - Attempts to retrieve courses from the cache if available.
    ///   - Ensures the user is logged in before querying Firestore.
    ///   - Queries the "courses" collection in Firestore where the `semester` field matches the given semester value.
    ///   - Caches the fetched courses to improve future access times.
    /// - Error Handling:
    ///   - Returns an empty array and prints an error message if the user is not logged in or the Firestore query fails.
    /// - Note:
    ///   - The cache is checked first; if courses for the semester exist in the cache, they are returned immediately.
    ///   - The "semester" field in Firestore is expected to be an array that contains the semester integer.
    func getCourses() async -> [FirestoreCourse] {
        
        let cachedCourses = cacheManager.loadCourses()
        if(!cachedCourses.isEmpty) {
            if(await shouldUpdateCourses() == false) {
                print("Fetched Courses from Cache")
                return cachedCourses
            }
        }
        
        let isLoggedIn = await FirestoreAPI.shared.ensureUserIsLoggedIn()
        
        guard isLoggedIn else {
            print("User could not be logged in.")
            return []
        }
        
        let coursesCollectionRef = FirestoreAPI.shared.db.collection("courses")
        let lastUpdateDocumentRef = FirestoreAPI.shared.db.collection("general").document("lastCourseUpdate")

        do {
            let lastUpdateSnapshot = try await lastUpdateDocumentRef.getDocument()
            
            if let data = lastUpdateSnapshot.data(), let lastUpdateTimestamp = data["date"] as? Timestamp {
                let lastUpdateDate = lastUpdateTimestamp.dateValue()
                UserDefaults.standard.set(lastUpdateDate, forKey: "lastCourseUpdate")
            }
            
            let query = coursesCollectionRef.order(by: "id", descending: false)
            let snapshot = try await query.getDocuments()
            
            let courses: [FirestoreCourse] = try snapshot.documents.compactMap { document in
                try document.data(as: FirestoreCourse.self)
            }
            
            UserDefaults.standard.set(Date(), forKey: "lastCheckForCourseUpdate")
            cacheManager.saveCourses(courses: courses)
            return courses
        } catch {
            print("Error fetching data: \(error)")
            return []
        }
    }
    
    /// Determines whether the app should update the list of courses by checking the last update timestamp.
    ///
    /// **Logic:**
    /// 1. Checks the timestamp of the last course update stored in `UserDefaults`:
    ///    - If it has been less than 3 hours since the last check, it returns `false` (no update needed).
    ///    - If more than 3 hours have passed, it proceeds to validate whether a course update is required.
    /// 2. Ensures the user is logged in to Firestore:
    ///    - If the user cannot be logged in, it assumes an update is needed.
    /// 3. Fetches the `lastCourseUpdate` document from the Firestore database:
    ///    - Compares the timestamp of the last known course update with the locally stored value.
    ///    - If the remote timestamp is newer, it updates the local timestamp and returns `true`.
    ///    - Otherwise, it returns `false`.
    ///
    /// **Returns:**
    /// - `true` if the courses should be updated.
    /// - `false` if no update is necessary.
    ///
    /// **Side Effects:**
    /// - Updates `UserDefaults` to track the last check time and course update timestamp.
    ///
    /// **Errors:**
    /// - If fetching the `lastCourseUpdate` document fails, it defaults to returning `true`.
    func shouldUpdateCourses() async -> Bool {
        if let lastUpdate = UserDefaults.standard.object(forKey: "lastCheckForCourseUpdate") as? Date {
            let threeHours: TimeInterval = 3 * 60 * 60
            
            if Date().timeIntervalSince(lastUpdate) >= threeHours {
                
                let isLoggedIn = await FirestoreAPI.shared.ensureUserIsLoggedIn()
                
                guard isLoggedIn else {
                    print("User could not be logged in.")
                    return true
                }
                
                let documentRef = FirestoreAPI.shared.db.collection("general").document("lastCourseUpdate")
                    
                do {
                    let documentSnapshot = try await documentRef.getDocument()
                    
                    guard let data = documentSnapshot.data(), let timestamp = data["date"] as? Timestamp else {
                        print("Document does not exist or date field is missing.")
                        return true
                    }
                    
                    UserDefaults.standard.set(Date(), forKey: "lastCheckForCourseUpdate")
                    let lastUpdateDate = timestamp.dateValue()
                    
                    if let lastStoredUpdate = UserDefaults.standard.object(forKey: "lastCourseUpdate") as? Date {
                        if(lastUpdateDate > lastStoredUpdate) {
                            UserDefaults.standard.set(lastUpdateDate, forKey: "lastCourseUpdate")
                            return true
                        } else {
                            return false
                        }
                    } else {
                        UserDefaults.standard.set(lastUpdateDate, forKey: "lastCourseUpdate")
                        return true
                    }
                } catch {
                    print("Error fetching last course update date: \(error)")
                    return true
                }
            } else {
                return false
            }
        } else {
            UserDefaults.standard.set(Date(), forKey: "lastCheckForCourseUpdate")
            return true
        }
    }
}

extension Array where Element == FirestoreCourse {
    /// Filters courses that include a specific semester index in their `semester` array.
    /// - Parameter semesterIndex: The semester index to filter courses by.
    /// - Returns: An array of `FirestoreCourse` containing the specified semester index.
    func filterBySemesterIndex(_ semesterIndex: Int) -> [FirestoreCourse] {
        return self.filter { course in
            course.semester.contains(semesterIndex)
        }
    }
}

