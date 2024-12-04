//
//  FirestoreCacheManager.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 20.11.24.
//

import Foundation

class FirestoreCacheManager {
    // File names for courses and semesters
    private let coursesFileName = "firestore_courses.json"
    
    // URL for storing courses data
    private var coursesCacheURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(coursesFileName)
    }
    
    /// Saves an array of courses to the courses cache file.
    /// - Parameter courses: Array of `FirestoreCourse` objects to save.
    func saveCourses(courses: [FirestoreCourse]) {
        saveCoursesToFile(data: courses)
    }
    
    /// Loads all cached courses from the courses cache file.
    /// - Returns: An array of `FirestoreCourse` objects, or an empty array if no data exists.
    func loadCourses() -> [FirestoreCourse] {
        guard let data = try? Data(contentsOf: coursesCacheURL) else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([FirestoreCourse].self, from: data)) ?? []
    }
    
    /// Converts a nested array of course IDs to a nested array of `FirestoreCourse` objects using the cache.
    /// - Parameter nestedCourseIDs: A nested array of course IDs (`[[String]]`).
    /// - Returns: A nested array of `FirestoreCourse` (`[[FirestoreCourse]]`).
    func loadCourses(with courseIDs: [[String]]) -> [[FirestoreCourse]] {
        // Load all cached courses
        let allCourses = loadCourses()
        let courseDictionary = Dictionary(uniqueKeysWithValues: allCourses.map { ($0.id, $0) })

        // Map each course ID to its corresponding `FirestoreCourse` if it exists in the cache
        return courseIDs.map { courseIDs in
            courseIDs.compactMap { courseDictionary[$0] }
        }
    }
    
    /// Encodes and saves an array of courses to the courses cache file.
    /// - Parameter data: An array of `FirestoreCourse` objects to save.
    private func saveCoursesToFile(data: [FirestoreCourse]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let encodedData = try encoder.encode(data)
            try encodedData.write(to: coursesCacheURL)
        } catch {
            print("Failed to save courses to file: \(error)")
        }
    }
}


extension FirestoreCacheManager {
    func getCoursesFileSize() -> String {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: coursesCacheURL.path) else {
            return "Files does not exist"
        }
        do {
            let attributes = try fileManager.attributesOfItem(atPath: coursesCacheURL.path)
            if let fileSize = attributes[.size] as? NSNumber {
                return formatBytes(fileSize.intValue)
            } else {
                return "File size couldn't be calculated"
            }
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) Bytes"
        } else if bytes < 1048576 {
            return String(format: "%.2f KB", Double(bytes) / 1024.0)
        } else {
            return String(format: "%.2f MB", Double(bytes) / 1048576.0)
        }
    }
}
