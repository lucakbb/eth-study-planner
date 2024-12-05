//
//  RecommendationsManager.swift
//  ETH Credit Planner
//
//  Created by Alexander Falter on 20.11.24.
//

import Foundation
import CoreData

struct RecommendationsCourse {
    var id: String
    var category: Int
    var credits: Int
    var name: String
    var semester: [Int]
    var tags: [String]
    var vvz: String
    var rating: Int
}

/// `RecommendationsManager` is responsible for generating personalized course recommendations
/// for the `AddCourseView`. It combines data from Firebase Firestore and Core Data to filter, prioritize,
/// and recommend courses tailored to the user's preferences and academic plan. Recommendations can
/// be based on categories or semesters, depending on which filters the user sets.
///
/// **Key Features:**
/// - Filters courses by semester, category, or user preferences.
/// - Removes already planned or completed courses from recommendations.
/// - Prioritizes courses based on user-tagged preferences, calculated via tag-weighted scoring.
/// - Integrates local Core Data courses and remote Firestore courses seamlessly.
/// - Converts between `Course` (Core Data) and `FirestoreCourse` (Firebase) models for compatibility.
///
/// This class leverages Firebase Firestore for fetching available courses and Core Data for managing
/// locally planned and liked courses.
class RecommendationsManager {
    let cacheManager = FirestoreCacheManager()
    let viewContext = PersistenceController.shared.container.viewContext

    // Main function
    func generateCategoryRecommendations(semesterID: Int, categoryID: Int) -> [FirestoreCourse] {
        let courses = convertFirestoreCoursesToRecommendations(cacheManager.loadCourses())
        var targetCourses = filterCoursesBySemesterAndCategory(semesterID: semesterID, categoryID: categoryID, courses: courses)
        
        let plannedCourses = convertCoursesToRecommendations(fetchAllCourses())
        targetCourses = removeAlreadyTaken(toEdit: targetCourses, planned: plannedCourses)
        
        let likedCourses = convertCoursesToRecommendations(fetchLikedCourses())
        let likedCoursesWithTags = addTagsToLocal(localCourses: likedCourses, courses: courses)
        
        let result = generateLikedCourses(likedCourses: likedCoursesWithTags, toPrioritize: targetCourses)
        
        return convertToFirestoreCourses(from: Array(result.prefix(3)))
    }
    
    func generateSemesterRecommendations(semesterID: Int) -> [FirestoreCourse] {
        let courses = convertFirestoreCoursesToRecommendations(cacheManager.loadCourses())
        
        let plannedCourses = convertCoursesToRecommendations(fetchAllCourses())
        var targetCourses = filterCoursesBySemester(semesterID: semesterID, courses: courses)
        targetCourses = removeAlreadyTaken(toEdit: targetCourses, planned: plannedCourses)
        
        let likedCourses = convertCoursesToRecommendations(fetchLikedCourses())
        let likedCoursesWithTags = addTagsToLocal(localCourses: likedCourses, courses: courses)
        let result = generateLikedCourses(likedCourses: likedCoursesWithTags, toPrioritize: targetCourses)
        return convertToFirestoreCourses(from: Array(result.prefix(3)))
    }
    
    func fetchAllCourses() -> [Course] {
        let fetchRequest: NSFetchRequest<Course> = Course.fetchRequest()
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch courses: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchLikedCourses() -> [Course] {
        let fetchRequest: NSFetchRequest<Course> = Course.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "rating != %d", -1)
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch courses: \(error.localizedDescription)")
            return []
        }
    }
    
    func convertCoursesToRecommendations(_ courses: [Course]) -> [RecommendationsCourse] {
        return courses.compactMap { $0.toRecommendationsCourse() }
    }
    
    func convertFirestoreCoursesToRecommendations(_ courses: [FirestoreCourse]) -> [RecommendationsCourse] {
        return courses.map { course in
            RecommendationsCourse(
                id: course.id,
                category: course.category,
                credits: course.credits,
                name: course.name,
                semester: course.semester,
                tags: course.tags,
                vvz: course.vvz,
                rating: -1
            )
        }
    }
    
    func convertToFirestoreCourses(from recommendations: [RecommendationsCourse]) -> [FirestoreCourse] {
        return Array(recommendations.prefix(3)).compactMap { recommendationsCourse in
            FirestoreCourse(
                id: recommendationsCourse.id,
                category: recommendationsCourse.category,
                credits: recommendationsCourse.credits,
                name: recommendationsCourse.name,
                semester: recommendationsCourse.semester,
                tags: recommendationsCourse.tags,
                vvz: recommendationsCourse.vvz
            )
        }
    }


    // MARK: - Firestore Functions

    func filterCoursesBySemester(semesterID: Int, courses: [RecommendationsCourse]) -> [RecommendationsCourse] {
        return courses.filter { $0.semester.contains(semesterID) }
    }

    func filterCoursesBySemesterAndCategory(semesterID: Int, categoryID: Int, courses: [RecommendationsCourse]) -> [RecommendationsCourse] {
        return courses.filter { $0.semester.contains(semesterID) && $0.category == categoryID }
    }

    func addTagsToLocal(localCourses: [RecommendationsCourse], courses: [RecommendationsCourse]) -> [RecommendationsCourse] {
        let globalCourseTags = Dictionary(uniqueKeysWithValues: courses.map { ($0.id, $0.tags) })
        var result: [RecommendationsCourse] = []
        for var localCourse in localCourses {
            if let tags = globalCourseTags[localCourse.id] {
                localCourse.tags = tags
            }
            result.append(localCourse)
        }
        return result
    }

    func removeAlreadyTaken(toEdit: [RecommendationsCourse], planned: [RecommendationsCourse]) -> [RecommendationsCourse] {
        let plannedIDs = Set(planned.map { $0.id })
        return toEdit.filter { !plannedIDs.contains($0.id) }
    }

    // MARK: - Sort by Priority

    func generateLikedCourses(likedCourses: [RecommendationsCourse], toPrioritize: [RecommendationsCourse]) -> [RecommendationsCourse] {
        let prefs = generateTagPrio(likedCourses: likedCourses)
        var intermediate = [String: Double]() // Course ID to score
        
        for course in toPrioritize {
            var tmp: Double = 0.0
            for tag in course.tags {
                tmp += prefs[tag] ?? 0.0
            }
            intermediate[course.id] = tmp / Double(course.tags.count)
        }
        
        let output = toPrioritize.sorted { (course1, course2) -> Bool in
            let score1 = intermediate[course1.id] ?? 0.0
            let score2 = intermediate[course2.id] ?? 0.0
            return score1 > score2
        }
        
        return output
    }

    func generateTagPrio(likedCourses: [RecommendationsCourse]) -> [String: Double] {
        var likesByTags = [String: (value: Double, counter: Int)]()
        
        for course in likedCourses {
            for tag in course.tags {
                if var entry = likesByTags[tag] {
                    entry.value += Double(course.rating - 2)
                    entry.counter += 1
                    likesByTags[tag] = entry
                } else {
                    likesByTags[tag] = (Double(course.rating - 2), 1)
                }
            }
        }
        
        var tagPriorities = [String: Double]()
        for (tag, entry) in likesByTags {
            tagPriorities[tag] = entry.value / Double(entry.counter)
        }
        
        return tagPriorities
    }
}

extension Course {
    /// Converts a single `Course` Core Data object to a `RecommendationsCourse` struct.
    func toRecommendationsCourse() -> RecommendationsCourse? {
        // Ensure required fields are present
        guard let id = id,
              let name = name,
              let category = category?.id else { return nil }
        
        // Collect tags (assuming a 'tags' attribute or relationship exists)
        let tags: [String] = [] // Modify if a tags relationship or attribute is added later
        
        // Build the RecommendationsCourse
        return RecommendationsCourse(
            id: id,
            category: Int(category),
            credits: Int(credits),
            name: name,
            semester: [],
            tags: tags,
            vvz: "", // Assuming VVZ is not in Core Data yet, or set a placeholder
            rating: Int(rating)
        )
    }
}
