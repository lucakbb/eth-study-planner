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
    @Environment(\.managedObjectContext) private var viewContext
    
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var course: Course
    
    @State var courseStatus: CourseStatus = .planned
    @State private var selectedRating: Int? = nil
    
    @State var isReviewsSheetShown: Bool = false
    @State var isVVZSheetShown: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                if let vvz = course.vvz, let id = course.id {
                    if vvz != "" && id != "" {
                        links
                    }
                }
                
                general
                
                status
                
                rating
                
                HStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color("Color9"))
                    Text("Delete Course")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color("Color9"))
                    Spacer()
                }
                .padding(.bottom, 40)
                .onTapGesture {
                    dismiss()
                    
                    viewContext.delete(course)
                    
                    do {
                        try viewContext.save()
                    } catch {
                        print("\(error)")
                    }
                }
            }
            .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .phone ? 16 : 20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Course Overview")
        .onAppear {
            self.courseStatus = CourseStatus(rawValue: course.status ?? CourseStatus.planned.rawValue) ?? .planned
            self.selectedRating = Int(course.rating)
            
            SimpleAnalytics.shared.track(path: ["study-plan", "course-overview"])
        }
        .onDisappear { try? viewContext.save() }
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
                    if(course.vvz != "") {
                        #if targetEnvironment(macCatalyst)
                        openURL(URL(string: course.vvz ?? "")!)
                        #else
                        isVVZSheetShown = true
                        #endif
                    }
                }
                .sheet(isPresented: $isVVZSheetShown) {
                    if let url = URL(string: (course.vvz ?? "")) {
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
                    let courseMainID = course.id?.split(separator: "&&").first.map(String.init) ?? course.id
                    #if targetEnvironment(macCatalyst)
                    openURL(URL(string: "https://n.ethz.ch/~lteufelbe/coursereview/?course=\(courseMainID ?? "")")!)
                    #else
                    isReviewsSheetShown = true
                    #endif
                }
                .sheet(isPresented: $isReviewsSheetShown) {
                    let courseMainID = course.id?.split(separator: "&&").first.map(String.init) ?? course.id
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
                        Text(course.name ?? "")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.vertical, 7)
                            .padding(.leading, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemGroupedBackground))
                            .cornerRadius(10)
                        
                        Text(course.category?.name ?? "")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.vertical, 7)
                            .padding(.leading, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemGroupedBackground))
                            .cornerRadius(10)
                        
                        Text("\(course.credits) ECTS")
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
            
            ZStack {
                Color(UIColor.secondarySystemGroupedBackground)
                
                HStack {
                    ZStack {
                        courseStatus == CourseStatus.planned ? Color("Color1") : Color(UIColor.systemGroupedBackground)
                        
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
                        
                        courseStatus = .planned
                        course.status = CourseStatus.planned.rawValue
                        
                        do {
                            try viewContext.save()
                        } catch {
                            print(error)
                        }
                    }
                    
                    Spacer()
                    
                    ZStack {
                        courseStatus == CourseStatus.passed ? Color("Color1") : Color(UIColor.systemGroupedBackground)
                        
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
                        
                        courseStatus = .passed
                        course.status = CourseStatus.passed.rawValue
                        
                        do {
                            try viewContext.save()
                        } catch {
                            print(error)
                        }
                    }
                    
                    Spacer()
                    
                    ZStack {
                        courseStatus == CourseStatus.failed ? Color("Color8") : Color(UIColor.systemGroupedBackground)
                        
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
                        
                        courseStatus = .failed
                        course.status = CourseStatus.failed.rawValue
                        
                        do {
                            try viewContext.save()
                        } catch {
                            print(error)
                        }
                    }
                }
                .padding()
            }
            .cornerRadius(15)
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
                        
                        
                        Text(course.name ?? "")
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
                                    
                                    course.rating = Int16(index)
                                    
                                    do {
                                        try viewContext.save()
                                    } catch {
                                        print(error)
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
    CourseOverviewView(course: Course())
}

