//
//  CourseOverviewView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 12.11.24.
//

import SwiftUI
import CoreData
import SafariServices
import SimpleAnalytics

struct CourseOverviewView: View {
    let viewContext = PersistenceController.shared.container.viewContext
    
    @Environment(\.dismiss) private var dismiss
    @State var course: Course?
    
    @State var courseStatus: CourseStatus = .planned
    @State private var selectedRating: Int? = nil
    
    @State var isReviewsSheetShown: Bool = false
    @State var isVVZSheetShown: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                links
                
                general
                
                status
                
                rating
                
                HStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color(UIColor.systemRed))
                    Text("Delete Course")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color(UIColor.systemRed))
                    Spacer()
                }
                .padding(.bottom, 40)
                .onTapGesture {
                    dismiss()
                    
                    if let course = course {
                        viewContext.delete(course)
                        do {
                            try viewContext.save()
                        } catch {
                            print("\(error)")
                        }
                    }
                }
            }
            .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Course Overview")
        .onAppear {
            self.courseStatus = CourseStatus(rawValue: course?.status ?? CourseStatus.planned.rawValue) ?? .planned
            self.selectedRating = Int(course?.rating ?? -1)
            
            SimpleAnalytics.shared.track(path: ["study-plan", "course-overview"])
        }
    }
    
    var links: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Links")
                .font(.system(size: 20, weight: .bold))
            
            HStack {
                ZStack {
                    Color(UIColor.secondarySystemGroupedBackground)
                    
                    HStack {
                        ZStack {
                            Color("Color1")
                            Image(systemName: "doc.text.fill")
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .frame(width: 27, height: 27)
                        .cornerRadius(5)
                        
                        
                        Text("VVZ")
                            .fontWeight(.semibold)
                            .font(.system(size: 20))
                        
                        Spacer()
                        
                    }
                    .padding(10)
                }
                .cornerRadius(10)
                .onTapGesture {
                    if(course?.vvz != "") {
                        isVVZSheetShown = true
                    }
                }
                .sheet(isPresented: $isVVZSheetShown) {
                    if let url = URL(string: (course?.vvz ?? "")) {
                        SafariView(url: url)
                    }
                }
                
                ZStack {
                    Color(UIColor.secondarySystemGroupedBackground)
                    
                    HStack {
                        ZStack {
                            Color(UIColor.systemYellow)
                            Image(systemName: "star.fill")
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .frame(width: 27, height: 27)
                        .cornerRadius(5)
                        
                        
                        Text("Reviews")
                            .fontWeight(.semibold)
                            .font(.system(size: 20))
                        
                        Spacer()
                        
                    }
                    .padding(10)
                }
                .cornerRadius(10)
                .onTapGesture {
                    isReviewsSheetShown = true
                }
                .sheet(isPresented: $isReviewsSheetShown) {
                    let courseMainID = course?.id?.split(separator: "&&").first.map(String.init) ?? course?.id
                    if let url = URL(string: "https://n.ethz.ch/~lteufelbe/coursereview/?course=\(courseMainID ?? "")") {
                        SafariView(url: url)
                    }
                }
            }
        }
    }
    
    var general: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("General")
                .font(.system(size: 20, weight: .bold))
                .padding(.bottom, -5)
            
            ZStack {
                Color(UIColor.secondarySystemGroupedBackground)
                
                VStack {
                    HStack {
                        ZStack {
                            Color("Color1")
                            Image(systemName: "doc.text.fill")
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .frame(width: 27, height: 27)
                        .cornerRadius(5)
                        
                        
                        Text("Information")
                            .fontWeight(.semibold)
                            .font(.system(size: 20))
                        
                        Spacer()
                        
                    }
                    .padding(10)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(course?.name ?? "")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.vertical, 7)
                            .padding(.leading, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemGroupedBackground))
                            .cornerRadius(10)
                        
                        Text(course?.category?.name ?? "")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.vertical, 7)
                            .padding(.leading, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemGroupedBackground))
                            .cornerRadius(10)
                        
                        Text("\(course?.credits ?? 0) ECTS")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.vertical, 7)
                            .padding(.leading, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemGroupedBackground))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                }
            }
            .cornerRadius(10)
        }
    }
    
    var status: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Status")
                .font(.system(size: 20, weight: .bold))
                .padding(.bottom, -5)
            
            HStack {
                ZStack {
                    courseStatus == CourseStatus.planned ? Color("Color1") : Color(UIColor.secondarySystemGroupedBackground)
                    
                    VStack(spacing: 5) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(courseStatus == CourseStatus.planned ? .white : Color(UIColor.lightGray))
                        Text("Planned")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(courseStatus == CourseStatus.planned ? .white : Color(UIColor.lightGray))
                    }
                    .padding(.vertical, 15)
                }
                .cornerRadius(10)
                .onTapGesture {
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                    
                    if let course = course {
                        courseStatus = .planned
                        course.status = CourseStatus.planned.rawValue
                    }
                    
                    do {
                        try viewContext.save()
                    } catch {
                        print(error)
                    }
                }
                
                Spacer()
                
                ZStack {
                    courseStatus == CourseStatus.passed ? Color("Color1") : Color(UIColor.secondarySystemGroupedBackground)
                    
                    VStack(spacing: 5) {
                        Image(systemName: "medal.fill")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(courseStatus == CourseStatus.passed ? .white : Color(UIColor.lightGray))
                        Text("Passed")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(courseStatus == CourseStatus.passed ? .white : Color(UIColor.lightGray))
                    }
                    .padding(.vertical, 15)
                }
                .cornerRadius(10)
                .onTapGesture {
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                    
                    if let course = course {
                        courseStatus = .passed
                        course.status = CourseStatus.passed.rawValue
                    }
                    
                    do {
                        try viewContext.save()
                    } catch {
                        print(error)
                    }
                }
                
                Spacer()
                
                ZStack {
                    courseStatus == CourseStatus.failed ? Color("Color8") : Color(UIColor.secondarySystemGroupedBackground)
                    
                    VStack(spacing: 5) {
                        Image(systemName: "xmark.diamond.fill")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(courseStatus == CourseStatus.failed ? .white : Color(UIColor.lightGray))
                        Text("Failed")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(courseStatus == CourseStatus.failed ? .white : Color(UIColor.lightGray))
                    }
                    .padding(.vertical, 15)
                }
                .cornerRadius(10)
                .onTapGesture {
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                    
                    if let course = course {
                        courseStatus = .failed
                        course.status = CourseStatus.failed.rawValue
                    }
                    
                    do {
                        try viewContext.save()
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
        
    
    var rating: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rate Course")
                .font(.system(size: 20, weight: .bold))
                .padding(.bottom, -5)
            
            ZStack {
                Color(UIColor.secondarySystemGroupedBackground)
                
                VStack {
                    HStack {
                        ZStack {
                            Color("Color1")
                            Image(systemName: "number")
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .frame(width: 27, height: 27)
                        .cornerRadius(5)
                        
                        
                        Text(course?.name ?? "")
                            .fontWeight(.semibold)
                            .font(.system(size: 20))
                        
                        Spacer()
                        
                    }
                    .padding(10)
                    
                    HStack(spacing: 10) {
                        Spacer()
                        ForEach(0..<5) { index in
                            Image(systemName: "star.fill")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundColor(index <= (selectedRating ?? -1) ? Color(UIColor.systemYellow) : Color(UIColor.systemGray2))
                                .onTapGesture {
                                    
                                    selectedRating = index
                                    
                                    if let course = course {
                                        course.rating = Int16(index)
                                        
                                        do {
                                            try viewContext.save()
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 20)
                    
                }
            }
            .cornerRadius(10)
        }
    }
}


#Preview {
    CourseOverviewView(course: nil)
}

