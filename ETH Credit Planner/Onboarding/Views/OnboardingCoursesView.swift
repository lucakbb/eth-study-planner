//
//  OnboardingCoursesView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 19.11.24.
//

import SwiftUI

struct OnboardingCoursesView: View {
    @StateObject var viewModel: OnboardingViewModel
    
    @FetchRequest(
        entity: Semester.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Semester.number, ascending: true)]
    ) var semesters: FetchedResults<Semester>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    ProgressBar(progress: 3, amountOfSteps: 4)
                    
                    ZStack {
                        Color(UIColor.systemGray2)
                        
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 25, weight: .semibold))
                            Text("Select all courses you already passed.")
                                .foregroundStyle(.white)
                                .font(.system(size: 15, weight: .semibold))
                            
                            Spacer()
                        }
                        .padding(.leading, 3)
                        .padding(10)
                    }
                    .cornerRadius(15)
                    
                    if(semesters.count > 0) {
                        VStack(spacing: 10) {
                            if(viewModel.currentSemester >= 0) {
                                FirstYearCoursesView(semester: semesters[0])
                            }
                            
                            if(viewModel.currentSemester >= 1) {
                                FirstYearCoursesView(semester: semesters[1])
                            }
                            
                            if(viewModel.currentSemester >= 2) {
                                BasicCoursesView(semester: semesters[2])
                            }
                            
                            if(viewModel.currentSemester >= 3) {
                                BasicCoursesView(semester: semesters[3])
                            }
                        }
                    }
                    
                }
            }
            .padding(.horizontal, 16)
            .navigationTitle("Passed Courses")
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

struct FirstYearCoursesView: View {
    let viewContext = PersistenceController.shared.container.viewContext
    @FetchRequest var courses: FetchedResults<Course>
    
    @State var semester: Semester?
    @State var isCollapsed: Bool = true
    @State var isPassed: Bool = false
  
        
    init(semester: Semester?) {
        self.semester = semester
        
        self._courses = FetchRequest<Course>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Course.id, ascending: true)],
            predicate: semester != nil ? NSPredicate(format: "semester == %@", semester!) : nil
        )
    }
    
    var body: some View {
        if(isCollapsed) {
            collapsedView
                .onTapGesture {
                    isCollapsed.toggle()
                }
        } else {
            expandedView
        }
    }
    
    var collapsedView: some View {
        ZStack {
            Color(UIColor.secondarySystemGroupedBackground)
            
            HStack {
                Image(systemName: (semester?.number ?? 0) == 0 ? "1.square.fill" : "2.square.fill")
                    .font(.system(size: 35, weight: .semibold))
                    .foregroundStyle(Color("Color1"))
                
                VStack(alignment: .leading) {
                    Text("Semester")
                        .font(.system(size: 20, weight: .semibold))
                    if(!isPassed) {
                        Text("\(courses.count) Courses")
                            .foregroundStyle(Color(UIColor.systemGray2))
                            .font(.system(size: 17, weight: .semibold))
                    } else {
                        Text("\(courses.count) Courses Passed")
                            .foregroundStyle(Color(UIColor.systemGreen))
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .foregroundStyle(Color(UIColor.systemGray2))
                    .font(.system(size: 20, weight: .semibold))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
        }
        .cornerRadius(15)
    }
    
    var expandedView: some View {
        ZStack {
            Color(UIColor.secondarySystemGroupedBackground)
            
            VStack {
                HStack {
                    Image(systemName: (semester?.number ?? 0) == 0 ? "1.square.fill" : "2.square.fill")
                        .font(.system(size: 35, weight: .semibold))
                        .foregroundStyle(Color("Color1"))
                    
                    VStack(alignment: .leading) {
                        Text("Semester")
                            .font(.system(size: 20, weight: .semibold))
                        if(!isPassed) {
                            Text("\(courses.count) Courses")
                                .foregroundStyle(Color(UIColor.systemGray2))
                                .font(.system(size: 17, weight: .semibold))
                        } else {
                            Text("\(courses.count) Courses Passed")
                                .foregroundStyle(Color(UIColor.systemGreen))
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up")
                        .foregroundStyle(Color(UIColor.systemGray2))
                        .font(.system(size: 20, weight: .semibold))
                }
                .onTapGesture {
                    isCollapsed.toggle()
                }
                
                VStack {
                    ForEach(courses, id: \.self) { course in
                        Text(course.name ?? "")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.vertical, 7)
                            .padding(.leading, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemGroupedBackground))
                            .cornerRadius(10)
                    }
                
                }
                .padding(.vertical, 15)
                
                ZStack() {
                    if(!isPassed) {
                        Color(UIColor.tertiarySystemGroupedBackground)
                        HStack {
                            Text("Mark Block as Passed")
                                .font(.system(size: 20, weight: .semibold))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 10)
                    } else {
                        Color(UIColor.systemGreen).opacity(0.5)
                        HStack {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color(UIColor.systemGreen))
                                .font(.system(size: 20, weight: .semibold))
                            Text("Marked as Passed")
                                .foregroundStyle(Color(UIColor.systemGreen))
                                .font(.system(size: 20, weight: .semibold))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 10)
                    }
                }
                .frame(height: 54)
                .cornerRadius(10)
                .onTapGesture {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    for course in courses {
                        course.isPassed = !isPassed
                    }
                    
                    isPassed.toggle()
                    
                    do {
                        try viewContext.save()
                    } catch {
                        print(error)
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
        }
        .cornerRadius(15)
    }
}

struct BasicCoursesView: View {
    let viewContext = PersistenceController.shared.container.viewContext
    @FetchRequest var courses: FetchedResults<Course>
    
    @State var semester: Semester?
    @State var isCollapsed: Bool = true
    @State var passedCourses: Set<Course> = []
    
    init(semester: Semester?) {
        self.semester = semester
        
        self._courses = FetchRequest<Course>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Course.id, ascending: true)],
            predicate: semester != nil ? NSPredicate(format: "semester == %@", semester!) : nil
        )
    }
    
    var body: some View {
        if isCollapsed {
            collapsedView
                .onTapGesture {
                    isCollapsed.toggle()
                }
        } else {
            expandedView
        }
    }
    
    var collapsedView: some View {
        ZStack {
            Color(UIColor.secondarySystemGroupedBackground)
            
            HStack {
                Image(systemName: (semester?.number ?? 0) == 2 ? "3.square.fill" : "4.square.fill")
                    .font(.system(size: 35, weight: .semibold))
                    .foregroundStyle(Color("Color1"))
                
                VStack(alignment: .leading) {
                    Text("Semester")
                        .font(.system(size: 20, weight: .semibold))
                    if passedCourses.isEmpty {
                        Text("\(courses.count) Courses")
                            .foregroundStyle(Color(UIColor.systemGray2))
                            .font(.system(size: 17, weight: .semibold))
                    } else {
                        Text("\(passedCourses.count) Courses Passed")
                            .foregroundStyle(Color(UIColor.systemGreen))
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .foregroundStyle(Color(UIColor.systemGray2))
                    .font(.system(size: 20, weight: .semibold))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
        }
        .cornerRadius(15)
    }
    
    var expandedView: some View {
        ZStack {
            Color(UIColor.secondarySystemGroupedBackground)
            
            VStack {
                HStack {
                    Image(systemName: (semester?.number ?? 0) == 2 ? "3.square.fill" : "4.square.fill")
                        .font(.system(size: 35, weight: .semibold))
                        .foregroundStyle(Color("Color1"))
                    
                    VStack(alignment: .leading) {
                        Text("Semester")
                            .font(.system(size: 20, weight: .semibold))
                        if passedCourses.isEmpty {
                            Text("\(courses.count) Courses")
                                .foregroundStyle(Color(UIColor.systemGray2))
                                .font(.system(size: 17, weight: .semibold))
                        } else {
                            Text("\(passedCourses.count) Courses Passed")
                                .foregroundStyle(Color(UIColor.systemGreen))
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up")
                        .foregroundStyle(Color(UIColor.systemGray2))
                        .font(.system(size: 20, weight: .semibold))
                }
                .onTapGesture {
                    isCollapsed.toggle()
                }
                
                VStack {
                    ForEach(courses, id: \.self) { course in
                        HStack(spacing: 10) {
                            if passedCourses.contains(course) {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(Color(UIColor.systemGreen))
                                    .font(.system(size: 23, weight: .semibold))
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(Color(UIColor.systemGray2))
                                    .font(.system(size: 23, weight: .semibold))
                            }
                            
                            Text(course.name ?? "")
                                .multilineTextAlignment(.leading)
                                .font(.system(size: 20, weight: .semibold))
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.systemGroupedBackground))
                        .cornerRadius(10)
                        .onTapGesture {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            toggleCoursePassed(course: course)
                        }
                    }
                }
                .padding(.vertical, 15)
                
                ZStack {
                    if passedCourses.count != courses.count {
                        Color(UIColor.tertiarySystemGroupedBackground)
                        HStack {
                            Text("Mark all Courses as Passed")
                                .font(.system(size: 20, weight: .semibold))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 10)
                    } else {
                        Color(UIColor.systemGreen).opacity(0.5)
                        HStack {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color(UIColor.systemGreen))
                                .font(.system(size: 20, weight: .semibold))
                            Text("All Courses Passed")
                                .foregroundStyle(Color(UIColor.systemGreen))
                                .font(.system(size: 20, weight: .semibold))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 10)
                    }
                }
                .frame(height: 54)
                .cornerRadius(10)
                .onTapGesture {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    toggleAllCourses()
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
        }
        .cornerRadius(15)
    }
    
    private func toggleCoursePassed(course: Course) {
        if passedCourses.contains(course) {
            passedCourses.remove(course)
            
            course.isPassed = false
        } else {
            passedCourses.insert(course)
            
            course.isPassed = true
        }
        
        do {
            try viewContext.save()
        } catch {
            print(error)
        }
    }
    
    private func toggleAllCourses() {
        if passedCourses.count == courses.count {
            
            for course in passedCourses {
                course.isPassed = false
            }
            
            passedCourses.removeAll()
        } else {
            passedCourses = Set(courses)
            
            for course in passedCourses {
                course.isPassed = true
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            print(error)
        }
    }
}


#Preview {
    OnboardingCoursesView(viewModel: OnboardingViewModel())
}

