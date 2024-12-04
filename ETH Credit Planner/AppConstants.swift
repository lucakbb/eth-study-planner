//
//  AppConstants.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 17.11.24.
//

import Foundation
import SwiftUI

struct AppConstants {
    struct Tags {
        static let interests: [String] = ["Algorithms", "Data Structures", "Programming", "Theoretical Computer Science", "Computer Architecture", "Virtual Reality", "Interaction Design", "Probability", "Machine Learning", "Neuroinformatics", "Cryptography", "Game Design", "Computer Vision", "Parallel Computing", "Networks", "Computer Systems"]
        
        
        static let template: [String] = ["Machine Learning", "Parallel Computing", "Theoretical Computer Science", "Visual Computing", "Algorithms", "Virtual Reality", "Cryptography", "Computer Systems", "Computer Architecture", "Programming", "Networks", "Interaction Design"]
    }
    
    struct TemplateTopics {
        static let topics: [[TemplateLibararyTopic]] = [[TemplateLibararyTopic(title: "Machine Learning", icon: "brain.fill", color: Color("Color1")),                                                             TemplateLibararyTopic(title: "Parallel Computing", icon: "cpu", color: Color("Color1")),
                                                         TemplateLibararyTopic(title: "Theoretical Computer Science", icon: "infinity", color: Color("Color1"))],
                                                        [TemplateLibararyTopic(title: "Visual Computing", icon: "eye.fill", color: Color("Color1")), TemplateLibararyTopic(title: "Algorithms", icon: "gear", color: Color("Color1")), TemplateLibararyTopic(title: "Virtual Reality", icon: "cube.transparent", color: Color("Color1")), TemplateLibararyTopic(title: "Cryptography", icon: "lock.fill", color: Color("Color1")), TemplateLibararyTopic(title: "Networks", icon: "network", color: Color("Color1"))],
                                                        [TemplateLibararyTopic(title: "Computer Systems", icon: "desktopcomputer", color: Color("Color1")),
                                                         TemplateLibararyTopic(title: "Computer Architecture", icon: "memorychip", color: Color("Color1")),
                                                         TemplateLibararyTopic(title: "Programming", icon: "chevron.left.slash.chevron.right", color: Color("Color1")),
                                                         TemplateLibararyTopic(title: "Interaction Design", icon: "hand.tap.fill", color: Color("Color1"))]]
        
        
        static let semesters: [TemplateLibararyTopic] = [TemplateLibararyTopic(title: "6 Semesters", icon: "6.circle", color: Color("Color6")),
                                                         TemplateLibararyTopic(title: "7 Semesters", icon: "7.circle", color: Color("Color7")),
                                                         TemplateLibararyTopic(title: "8+ Semesters", icon: "8.circle", color: Color("Color8"))]
        
        
        static let categories: [[TemplateLibararyTopic]] = [[TemplateLibararyTopic(title: "Templates You Liked", icon: "bookmark.fill", color: Color(UIColor.systemRed)),
                                                             TemplateLibararyTopic(title: "Most Liked", icon: "heart.fill", color: Color(UIColor.systemRed))],
                                                            [TemplateLibararyTopic(title: "Fewest Courses", icon: "arrow.down", color: Color("Color3")),
                                                             TemplateLibararyTopic(title: "Most Courses", icon: "arrow.up", color: Color("Color7"))]]
    }
    
    struct DefaultObjects {
        
        // Mapping between categoryID (Int) and Category (String):
        //
        // 0 - "Basisjahr Fächer"
        // 1 - "Grundlagen Fächer"
        // 2 - "Kernfächer"
        // 3 - "Ergänzung"
        // 4 - "Wahlfächer"
        // 5 - "GESS"
        // 6 - "Seminar"
        // 7 - "Bachelor Arbeit"
        static let categories: [FirestoreCategory] = [FirestoreCategory(id: 0, name: "Basisjahr Fächer", icon: "book.closed.fill", maxCredits: 56, minCredits: 56),
                                                      FirestoreCategory(id: 1, name: "Grundlagen Fächer", icon: "lightbulb.max.fill", maxCredits: 52, minCredits: 45),
                                                      FirestoreCategory(id: 2, name: "Kernfächer", icon: "star.fill", maxCredits: 180, minCredits: 32),
                                                      FirestoreCategory(id: 3, name: "Ergänzung", icon: "flask.fill", maxCredits: 180, minCredits: 5),
                                                      FirestoreCategory(id: 4, name: "Wahlfächer", icon: "doc.text.magnifyingglass", maxCredits: 180, minCredits: 0),
                                                      FirestoreCategory(id: 5, name: "GESS", icon: "binoculars.fill", maxCredits: 6, minCredits: 6),
                                                      FirestoreCategory(id: 6, name: "Seminar", icon: "doc.on.doc.fill", maxCredits: 2, minCredits: 2),
                                                      FirestoreCategory(id: 7, name: "Bachelor Arbeit", icon: "pencil", maxCredits: 10, minCredits: 10)]
        static let courses: [FirestoreCourse] = [FirestoreCourse(id: "227-0003-10L", category: 0, credits: 7, name: "Digital Design and Computer Architecture", semester: [10], tags: [], vvz: "https://www.vvz.ethz.ch/Vorlesungsverzeichnis/lerneinheit.view?lerneinheitId=188955&semkez=2025S&ansicht=LEHRVERANSTALTUNGEN&lang=en"),
                                                 FirestoreCourse(id: "252-0025-01L", category: 0, credits: 7, name: "Discrete Mathematics", semester: [11], tags: [], vvz: "https://www.vvz.ethz.ch/Vorlesungsverzeichnis/lerneinheit.view?lerneinheitId=182974&semkez=2024W&ansicht=LEHRVERANSTALTUNGEN&lang=en"),
                                                 FirestoreCourse(id: "252-0026-00L", category: 0, credits: 7, name: "Algorithms and Data Structures", semester: [11], tags: [], vvz: "https://www.vvz.ethz.ch/Vorlesungsverzeichnis/lerneinheit.view?lerneinheitId=181727&semkez=2024W&ansicht=LEHRVERANSTALTUNGEN&lang=en"),
                                                 FirestoreCourse(id: "252-0027-00L", category: 0, credits: 7, name: "Introduction to Programming", semester: [11], tags: [], vvz: "https://www.vvz.ethz.ch/Vorlesungsverzeichnis/lerneinheit.view?lerneinheitId=183366&semkez=2024W&ansicht=LEHRVERANSTALTUNGEN&lang=en"),
                                                 FirestoreCourse(id: "252-0029-00L", category: 0, credits: 7, name: "Parallel Programming", semester: [10], tags: [], vvz: "https://www.vvz.ethz.ch/Vorlesungsverzeichnis/lerneinheit.view?lerneinheitId=187434&semkez=2025S&ansicht=LEHRVERANSTALTUNGEN&lang=en"),
                                                 FirestoreCourse(id: "252-0030-00L", category: 0, credits: 7, name: "Algorithms and Probability", semester: [10], tags: [], vvz: "https://www.vvz.ethz.ch/Vorlesungsverzeichnis/lerneinheit.view?lerneinheitId=187867&semkez=2025S&ansicht=LEHRVERANSTALTUNGEN&lang=en"),
                                                 FirestoreCourse(id: "401-0131-00L", category: 0, credits: 7, name: "Linear Algebra", semester: [11], tags: [], vvz: "https://www.vvz.ethz.ch/Vorlesungsverzeichnis/lerneinheit.view?lerneinheitId=183173&semkez=2024W&ansicht=LEHRVERANSTALTUNGEN&lang=en"),
                                                 FirestoreCourse(id: "401-0212-16L", category: 0, credits: 7, name: "Analysis I", semester: [10], tags: [], vvz: "https://www.vvz.ethz.ch/Vorlesungsverzeichnis/lerneinheit.view?lerneinheitId=188507&semkez=2025S&ansicht=LEHRVERANSTALTUNGEN&lang=en"),
                                                 FirestoreCourse(id: "252-0057-00L", category: 1, credits: 7, name: "Theoretical Computer Science", semester: [11], tags: [], vvz: "https://www.vvz.ethz.ch/Vorlesungsverzeichnis/lerneinheit.view?lerneinheitId=183407&semkez=2024W&ansicht=LEHRVERANSTALTUNGEN&lang=en"),
                                                 FirestoreCourse(id: "252-0058-00L", category: 1, credits: 7, name: "Formal Methods and Functional Programming", semester: [10], tags: [], vvz: "https://www.vvz.ethz.ch/Vorlesungsverzeichnis/lerneinheit.view?lerneinheitId=188508&semkez=2025S&ansicht=LEHRVERANSTALTUNGEN&lang=en"),
                                                 FirestoreCourse(id: "252-0061-00L", category: 1, credits: 7, name: "Systems Programming and Computer Architecture", semester: [11], tags: [], vvz: "https://www.vvz.ethz.ch/Vorlesungsverzeichnis/lerneinheit.view?lerneinheitId=182124&semkez=2024W&ansicht=LEHRVERANSTALTUNGEN&lang=en"),
                                                 FirestoreCourse(id: "252-0063-00L", category: 1, credits: 7, name: "Data Modelling and Databases", semester: [10], tags: [], vvz: "https://www.vvz.ethz.ch/Vorlesungsverzeichnis/lerneinheit.view?lerneinheitId=188765&semkez=2025S&ansicht=LEHRVERANSTALTUNGEN&lang=en"),
                                                 FirestoreCourse(id: "252-0064-00L", category: 1, credits: 7, name: "Computer Networks", semester: [10], tags: [], vvz: "https://www.vvz.ethz.ch/Vorlesungsverzeichnis/lerneinheit.view?lerneinheitId=188626&semkez=2025S&ansicht=LEHRVERANSTALTUNGEN&lang=en"),
                                                 FirestoreCourse(id: "401-0213-16L", category: 1, credits: 5, name: "Analysis II", semester: [11], tags: [], vvz: "https://www.vvz.ethz.ch/Vorlesungsverzeichnis/lerneinheit.view?lerneinheitId=182378&semkez=2024W&ansicht=LEHRVERANSTALTUNGEN&lang=en"),
                                                 FirestoreCourse(id: "401-0614-00L", category: 1, credits: 5, name: "Probability and Statistics", semester: [10], tags: [], vvz: "https://www.vvz.ethz.ch/Vorlesungsverzeichnis/lerneinheit.view?lerneinheitId=188550&semkez=2025S&ansicht=LEHRVERANSTALTUNGEN&lang=en"),
                                                 FirestoreCourse(id: "401-0663-00L", category: 1, credits: 7, name: "Numerical Methods for Computer Science", semester: [11], tags: [], vvz: "https://www.vvz.ethz.ch/Vorlesungsverzeichnis/lerneinheit.view?lerneinheitId=182278&semkez=2024W&ansicht=LEHRVERANSTALTUNGEN&lang=en")]
    }
}
