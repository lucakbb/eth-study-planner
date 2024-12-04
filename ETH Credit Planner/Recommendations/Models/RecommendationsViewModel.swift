//
//  RecommendationsViewModel.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 22.11.24.
//

import Foundation

class RecommendationsViewModel {
    
    func fetchRecommendationCourses(for recommendation: Recommendation) -> [[String]] {
        let relatedCourses = recommendation.courses?.allObjects as? [RecommendedCourse] ?? []
        let groupedBySemester = Dictionary(grouping: relatedCourses, by: { $0.semester })

        let sortedSemesters = groupedBySemester.keys.sorted()
        var nestedArray: [[String]] = []

        for semester in sortedSemesters {
            if let courses = groupedBySemester[semester] {
                let courseIds = courses.compactMap { $0.id }
                nestedArray.append(courseIds)
            }
        }

        return nestedArray
    }
    
    func fetchFirestoreCourses(courseIDs: [[String]]) async -> [[FirestoreCourse]] {
        let cacheManager = FirestoreCacheManager()
        let cachedCourses = cacheManager.loadCourses(with: courseIDs)
        
        if !cachedCourses.isEmpty {
            if cachedCourses.flatMap({ $0 }).count == courseIDs.flatMap({ $0 }).count {
                print("Fetched Courses from Cache")
                return cachedCourses
            }
        }
        
        let addCourseViewModel = AddCourseViewModel()
        let courses = await addCourseViewModel.getCourses()
        
        let coursesDict = Dictionary(uniqueKeysWithValues: courses.map { ($0.id, $0) })
        
        let mappedCourses: [[FirestoreCourse]] = courseIDs.map { ids in
            ids.compactMap { coursesDict[$0] }
        }
        
        return mappedCourses
    }

}
