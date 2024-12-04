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
    
    @State var isPassed: Bool = false
    @State private var selectedRating: Int? = nil
    
    @State var isReviewsSheetShown: Bool = false
    @State var isVVZSheetShown: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                links
                
                general
                
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
            .padding(.horizontal, 16)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Course Overview")
        .onAppear {
            self.isPassed = course?.isPassed ?? false
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
                    if let url = URL(string: "https://n.ethz.ch/~lteufelbe/coursereview/?course=\(course?.id ?? "")") {
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
                    
                    HStack {
                        Image(systemName: isPassed == true ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 23, weight: .semibold))
                            .foregroundStyle(Color("Color1"))
                        Text("Passed")
                            .font(.system(size: 23, weight: .semibold))
                    }
                    .padding(.bottom, 15)
                    .onTapGesture {
                        let generator = UIImpactFeedbackGenerator(style: .heavy)
                        generator.impactOccurred()
                        
                        if let course = course {
                            isPassed.toggle()
                            course.isPassed.toggle()
                        }
                        
                        do {
                            try viewContext.save()
                        } catch {
                            print(error)
                        }
                    }
                }
            }
            .cornerRadius(10)
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
                    
                    HStack {
                        ForEach(0..<5) { index in
                            Spacer()
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
                    .padding(.horizontal, 40)
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

