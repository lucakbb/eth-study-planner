//
//  CreditsOverviewBanner.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 13.11.24.
//

import SwiftUI

struct CreditsOverviewBanner: View {
    @FetchRequest(entity: Course.entity(), sortDescriptors: [])
    var courses: FetchedResults<Course>
    
    @FetchRequest(entity: Category.entity(), sortDescriptors: [])
    var categories: FetchedResults<Category>
    
    @State var hasEnoughCredits: Bool = false
    
    var creditsByCategory: [Category: Int] {
        var result = Dictionary(uniqueKeysWithValues: categories.map { ($0, 0) })
        
        courses.forEach { course in
            if let category = course.category {
                result[category, default: 0] += Int(course.credits)
            }
        }
        
        return result
    }
    
    /// A computed property that checks if graduation requirements are fulfilled.
    /// - Returns: A `Bool` indicating whether the requirements are met.
    /// - Behavior:
    ///   - Evaluates the following conditions:
    ///     1. **Minimum Credits per Category:** Ensures that the credits for each category meet or exceed the required minimum (`category.minCredits`).
    ///     2. **Basic + Core Credits:** Ensures that courses in the Basic and Core categories together sum to at least 84 credits.
    ///     3. **Fundamentals + Core + Elective Credits:** Ensures that the sum of credits from these categories is at least 96 credits.
    ///     4. **Total Credits:** Ensures that the total credits, capped at the maximum for each category (`category.maxCredits`), reach at least 180.
    ///   - Returns `false` if any of the conditions are not met; otherwise, returns `true`.
    /// - Note:
    ///   - The `creditsByCategory` dictionary provides the credits earned in each category.
    ///   - The `courses` array contains individual courses with their credits and categories.
    ///   - The `categories` array contains all available categories, each with its `minCredits` and `maxCredits` constraints.
    var checkGraduationRequirements: Bool {
        // Condition 1: fulfil the minimum number of credits in each category
        for (category, credits) in creditsByCategory {
            if credits < category.minCredits {
                return false
            }
        }
        
        let basicAndCoreCredits = courses.filter { $0.category?.id == 1 || $0.category?.id == 2 }
                                         .reduce(0) { $0 + Int($1.credits) }
        let electiveCredits = courses.filter { $0.category?.id == 4 }
                                     .reduce(0) { $0 + Int($1.credits) }
        
        
        // Condition 2: Basic + Core at least 84 credits
        if basicAndCoreCredits < 84 {
            return false
        }
        
        // Condition 3: Fundamentals + Core + Elective at least 96 credits
        if (basicAndCoreCredits + electiveCredits) < 96 {
            return false
        }
        
        // Condition 4: A total of at least 180 credits
        var totalCredits = 0
        categories.forEach { category in
            totalCredits += min(creditsByCategory[category] ?? 0, Int(category.maxCredits))
        }
        
        if totalCredits < 180 {
            return false
        }
        
        return true
    }
    
    var body: some View {
        if(!checkGraduationRequirements) {
            ZStack {
                Color(UIColor.systemGray2)
                
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 25, weight: .semibold))
                    Text("You do not currently have enough credits planned for your degree.")
                        .foregroundStyle(.white)
                        .font(.system(size: 15, weight: .semibold))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white)
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.trailing, 5)
                }
                .padding(.leading, 3)
                .padding(10)
            }
            .cornerRadius(15)
        } else {
            ZStack {
                Color(UIColor.systemGray2)
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 25, weight: .semibold))
                    Text("You have enough credits planned for your degree.")
                        .foregroundStyle(.white)
                        .font(.system(size: 15, weight: .semibold))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.trailing, 5)
                }
                .padding(.leading, 3)
                .padding(10)
            }
            .cornerRadius(15)
        }
    }
}

#Preview {
    CreditsOverviewBanner()
}
