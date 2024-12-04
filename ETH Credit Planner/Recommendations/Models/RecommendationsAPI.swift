//
//  RecommendationsAPI.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 21.11.24.
//

import Foundation
import CoreData

struct APIResponse: Codable {
    let result: String
}

class RecommendationsAPI: ObservableObject {
    let viewContext = PersistenceController.shared.container.viewContext
    let interestsManager = InterestsManager()
    let addCourseViewModel = AddCourseViewModel()
    
    @Published var totalSemester: Int = 6
    @Published var currentSemester: Int = 0
    @Published var maxCredits: [Int] = []
    
    func convertToJSONString(courses: [[RecommendationsAlgorithmusCourse]]) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let jsonData = try encoder.encode(courses)
            
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Error converting to JSON: \(error)")
            return nil
        }
    }
    
    func convertToJSONString<T: Codable>(_ input: T) -> String {
        let encoder = JSONEncoder()
        
        do {
            let jsonData = try encoder.encode(input)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            } else {
                return ""
            }
        } catch {
            print("JSON Encoding failed: \(error)")
            return ""
        }
    }

    
    func fetchAPIResult(completion: @escaping (Result<[[RecommendationsAlgorithmusCourse]], Error>) -> Void) {
        Task {
            do {
                guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
                      let secrets = NSDictionary(contentsOfFile: path),
                      let apiUrl = secrets["API_URL"] as? String else {
                    completion(.failure(NSError(domain: "Secrets.plist not found or missing API_BASE_URL", code: 0, userInfo: nil)))
                    return
                }

                
                guard let url = URL(string: apiUrl) else {
                    completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
                    return
                }
                
                // Create the HTTP request
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                
                // Await async functions and handle their results
                let allCourses = convertToJSONString(await fetchAllCourses())
                let takenCourses = convertToJSONString(fetchTakenCourses())
                let plannedCourses = convertToJSONString(fetchPlannedCourses())
                let likedTags = (interestsManager.loadInterests())?.titles ?? []
                
                // Prepare the request body
                let requestBody: [String: Any] = [
                    "totalSemester": totalSemester,
                    "currentSemesterRelative": currentSemester,
                    "currentSemesterIndex": addCourseViewModel.calculateCurrentSemesterIndex(),
                    "workload": maxCredits,
                    "takenCourses": takenCourses,
                    "likedTags": likedTags,
                    "totalCourses": allCourses,
                    "plannedCourses": plannedCourses
                ]
                
                // Convert the body into JSON format
                let jsonBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
                
                
                // Convert JSON data to String for debugging
                if let jsonString = String(data: jsonBody, encoding: .utf8) {
                    print(jsonString)
                } else {
                    print("Failed to convert JSON data to String")
                }
                
                request.httpBody = jsonBody
                
                // Set the Content-Type header
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                // Make the network request using async/await
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Check the HTTP response status
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    completion(.failure(NSError(domain: "Invalid Response", code: 0, userInfo: nil)))
                    return
                }
                
                do {
                    // Parse JSON data into the nested structure
                    let apiResponse = try JSONDecoder().decode([[RecommendationsAlgorithmusCourse]].self, from: data)
                    
                    let recommendation = Recommendation(context: self.viewContext)
                    recommendation.date = Date()
                    recommendation.currentSemester = Int16(currentSemester)
                    recommendation.amountOfSemesters = Int16(totalSemester)
                    
                    var semesterNumber = 0
                    for semester in apiResponse {
                        for course in semester {
                            let newCourse = RecommendedCourse(context: self.viewContext)
                            newCourse.id = course.id
                            newCourse.semester = Int16(semesterNumber)
                            newCourse.recommendation = recommendation
                        }
                        
                        semesterNumber += 1
                    }
                    
                    do {
                        try self.viewContext.save()
                    } catch {
                        print("Failed to fetch categories: \(error)")
                    }
                    
                    completion(.success(apiResponse))
                } catch {
                    completion(.failure(error))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func fetchAllCourses() async -> [RecommendationsAlgorithmusCourse] {
        let addCourseViewModel = AddCourseViewModel()
        
        let courses = await addCourseViewModel.getCourses()
        var result: [RecommendationsAlgorithmusCourse] = []
        
        for course in courses {
            let recommendationCourse = RecommendationsAlgorithmusCourse(
                id: course.id,
                category: course.category,
                credits: course.credits,
                name: course.name,
                semester: course.semester,
                plannedSemester: -1,
                tags: course.tags,
                vvz: course.vvz,
                rating: -1
            )
            
            result.append(recommendationCourse)
        }
        
        return result
    }
    
    func fetchTakenCourses() -> [RecommendationsAlgorithmusCourse] {
        let fetchRequest: NSFetchRequest<Course> = Course.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "semester.number < %d", currentSemester)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "semester.number", ascending: true)]
        
        do {
            let courses = try viewContext.fetch(fetchRequest)
            var result: [RecommendationsAlgorithmusCourse] = []
            
            for course in courses {
                let recommendationCourse = RecommendationsAlgorithmusCourse(
                    id: course.id ?? "",
                    category: Int(course.category?.id ?? -1),
                    credits: Int(course.credits),
                    name: course.name ?? "",
                    semester: [],
                    plannedSemester: -1,
                    tags: [],
                    vvz: course.vvz ?? "",
                    rating: Int(course.rating)
                )
                
                result.append(recommendationCourse)
            }
            
            return result
        } catch {
            print("Failed to fetch courses: \(error)")
            return []
        }
    }
    
    /// Fetches and organizes planned courses into a nested array, grouped by semester.
    /// - The method fetches `Course` objects from the Core Data `viewContext`
    ///   where the semester number is greater than or equal to the current semester.
    /// - It transforms each `Course` into a `RecommendationsAlgorithmusCourse` and groups them by semester.
    /// - The result is a nested array where each index corresponds to a semester relative to the current semester,
    ///   with empty arrays for semesters with no planned courses.
    /// - Returns: A nested array of `[RecommendationsAlgorithmusCourse]`, where each sub-array represents courses
    ///   planned for a specific semester. The length of the array is `totalSemester - currentSemester`, ensuring
    ///   every semester has an entry, even if no courses are planned.
    func fetchPlannedCourses() -> [[RecommendationsAlgorithmusCourse]] {
        let fetchRequest: NSFetchRequest<Course> = Course.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "semester.number >= %d AND semester.number < %d", currentSemester, totalSemester)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "semester.number", ascending: true)]
        
        do {
            let courses = try viewContext.fetch(fetchRequest)
            var coursesBySemester: [Int: [RecommendationsAlgorithmusCourse]] = [:]
            
            for course in courses {
                guard let semesterNumber = course.semester?.number else { continue }
                
                let recommendationCourse = RecommendationsAlgorithmusCourse(
                    id: course.id ?? "",
                    category: Int(course.category?.id ?? -1),
                    credits: Int(course.credits),
                    name: course.name ?? "",
                    semester: [],
                    plannedSemester: -1,
                    tags: [],
                    vvz: course.vvz ?? "",
                    rating: Int(course.rating)
                )
                
                if coursesBySemester[Int(semesterNumber)] != nil {
                    coursesBySemester[Int(semesterNumber)]?.append(recommendationCourse)
                } else {
                    coursesBySemester[Int(semesterNumber)] = [recommendationCourse]
                }
            }
            
            var nestedArray: [[RecommendationsAlgorithmusCourse]] = Array(repeating: [], count: totalSemester - currentSemester)
            
            for (semesterNumber, coursesInSemester) in coursesBySemester {
                let index = semesterNumber - currentSemester
                if index >= 0 && index < nestedArray.count {
                    nestedArray[index] = coursesInSemester
                }
            }
            
            return nestedArray
        } catch {
            print("Failed to fetch courses: \(error)")
            return Array(repeating: [], count: totalSemester - currentSemester)
        }
    }

}

    struct RecommendationsAlgorithmusCourse: Codable {
        var id: String
        var category: Int
        var credits: Int
        var name: String
        var semester: [Int]
        var plannedSemester: Int
        var tags: [String]
        var vvz: String
        var rating: Int
    }
