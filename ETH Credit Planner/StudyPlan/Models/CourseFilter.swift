//
//  CourseFilter.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 29.12.24.
//

import Foundation

class CourseFilter {
    static let shared = CourseFilter()
    
    /// Filters an array of courses to ensure only one course per unique ID is retained.
    /// - If all courses with the same ID have the same status, any one of them can be retained.
    /// - If one of the courses has the status "passed", it will be prioritized and retained.
    /// - If none are "passed" but one is "planned", it will be prioritized and retained.
    /// - If all courses have the status "failed", any one of them will be retained.
    /// - Parameter courses: An array of `Course` objects to filter.
    /// - Returns: A filtered array of `Course` objects where only one course per unique ID is retained.
    func filterCourses(_ courses: [Course]) -> [Course] {
        // Separate courses with nil or empty ID as they should not be filtered
        // This is done for custom courses, which don't have an id
        var filteredCourses: [Course] = courses.filter { $0.id == nil || $0.id?.isEmpty == true }
        
        // Group courses by their main ID (extract course-id part before "&&" if applicable)
        let groupedCourses = Dictionary(grouping: courses.filter { $0.id != nil && !$0.id!.isEmpty }, by: { course in
            course.id!.split(separator: "&&").first.map(String.init) ?? course.id!
        })

        // Apply filtering rules for each group
        let uniqueCourses = groupedCourses.compactMap { (_, coursesWithSameMainID) -> Course? in
            // Priority 1: Retain the course with status "passed"
            if let passedCourse = coursesWithSameMainID.first(where: { $0.status == CourseStatus.passed.rawValue }) {
                return passedCourse
            }
            // Priority 2: Retain the course with status "planned"
            if let plannedCourse = coursesWithSameMainID.first(where: { $0.status == CourseStatus.planned.rawValue }) {
                return plannedCourse
            }
            // Priority 3: Retain any course (all have the status "failed")
            return coursesWithSameMainID.first
        }
        
        // Combine filtered courses with nil/empty IDs and unique courses
        filteredCourses.append(contentsOf: uniqueCourses)
        
        return filteredCourses
    }



}
