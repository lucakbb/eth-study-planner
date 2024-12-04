//
//  SettingsView.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 18.11.24.
//

import SwiftUI
import AcknowList

struct SettingsEntry: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let image: String
    let color: UIColor
}

struct SettingsView: View {
    @Environment(\.openURL) var openURL
    @ObservedObject var viewModel = SettingsModel()
    
    @State var isChangeNamePresented: Bool = false
    @State var isNameTooLongAlertPresented: Bool = false
    @State var isLicencesSheetPresented: Bool = false
    @State var changedName: String = ""
    @State var amountOfSemesters: Int = 0
    @State var isDeleteSemesterAlertShown: Bool = false
    
    @State var amountOfClicks: Int = 0
    @State var isABPopupShown: Bool = false
    
    @FetchRequest(
        entity: Semester.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Semester.number, ascending: true)]
    ) var semesters: FetchedResults<Semester>
    
    let viewContext = PersistenceController.shared.container.viewContext
    let settings = [SettingsEntry(name: "Support", image: "mail.fill", color: UIColor(Color("Color1"))), SettingsEntry(name: "Review App", image: "star.fill", color: UIColor.systemYellow), SettingsEntry(name: "Legal Notice", image: "book.closed.fill", color: UIColor.gray), SettingsEntry(name: "Privacy Policy", image: "lock.fill", color: UIColor.gray)]
    
    var body: some View {
        NavigationStack {
            VStack {
                settingsList
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Settings")
            .onAppear {
                amountOfSemesters = semesters.count
            }
            .sheet(isPresented: $isABPopupShown) {
                ABVersionSettings(isPresented: $isABPopupShown)
            }
        }
    }
    
    var settingsList: some View {
        List {
            if(UserDefaults.standard.string(forKey: "userName") != nil) {
                Section(footer: Text("Change your username, which will be visible on your templates.")) {
                    HStack(spacing: 13) {
                        ZStack {
                            Circle()
                                .foregroundColor(Color("Color1"))
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 23, weight: .semibold))
                        }
                        .frame(width: 45, height: 45)
                        .cornerRadius(5)
                        
                        Text("\(UserDefaults.standard.string(forKey: "userName") ?? "")")
                            .lineLimit(1)
                            .font(.system(size: 21, weight: .medium))
                        
                        Spacer()
                        
                        Button {
                            isChangeNamePresented = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(UIColor.gray))
                                .padding(10)
                                .background {
                                    Circle()
                                        .foregroundColor(Color(UIColor.tertiarySystemGroupedBackground))
                                }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.leading, 13)
                    .padding(.trailing, 14)
                    .listRowInsets(EdgeInsets())
                }
                .alert("Username", isPresented: $isChangeNamePresented) {
                    TextField("Name", text: $changedName)
                    
                    Button("Cancel", action: {
                        isChangeNamePresented = false
                    })
                    
                    Button("Save", action: {
                        if(changedName != "" && changedName.count <= 30) {
                            UserDefaults.standard.set(changedName, forKey: "userName")
                            
                            isChangeNamePresented = false
                        } else {
                            isNameTooLongAlertPresented = true
                        }
                    })
                } message: {
                    Text("Change your username.")
                }
                .alert("Error", isPresented: $isNameTooLongAlertPresented) {
                    Button("Verstanden", action: {
                        isNameTooLongAlertPresented = false
                    })
                    
                } message: {
                    Text("Your user name must not be longer than 30 characters.")
                }
            }
            
            Section {
                HStack(spacing: 13) {
                    ZStack {
                        Color(Color("Color3"))
                        Image(systemName: "calendar")
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(width: 29, height: 29)
                    .cornerRadius(5)
                    
                    Text("Total Semesters: \(semesters.count)")
                        .font(.system(size: 18))
                    
                    Spacer()
                    
                    Stepper("", value: $amountOfSemesters, in: 2...10)
                        .labelsHidden()
                        .onChange(of: amountOfSemesters) {
                            if amountOfSemesters < semesters.count {
                                isDeleteSemesterAlertShown = true
                            } else {
                                viewModel.addNewSemester(number: semesters.count)
                            }
                        }
                        .alert("Delete Semester", isPresented: $isDeleteSemesterAlertShown) {
                            Button("Cancel", role: .cancel) {
                                isDeleteSemesterAlertShown = false
                            }
                            Button("Yes", role: .destructive) {
                                viewModel.deleteSemester(semester: semesters.count - 1)
                            }
                        } message: {
                            Text("Are you sure you want to delete a semester? All courses in that semester will also be deleted.")
                        }

                }
                .padding(.vertical, 10)
                .padding(.leading, 13)
                .padding(.trailing, 14)
                .listRowInsets(EdgeInsets())
                .contentShape(Rectangle())
            }
            
            Section {
                ForEach(settings, id: \.self) { entry in
                    SettingsEntryView(entry: entry)
                        .listRowInsets(EdgeInsets())
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if(entry.name == "Support") {
                                openURL(URL(string: "https://sable-perfume-44c.notion.site/147e068d9afc8012b229daac3caecf29?pvs=105")!)
                            } else if(entry.name == "Review App") {
                                viewModel.writeReview()
                            } else if(entry.name == "Legal Notice") {
                                openURL(URL(string: "https://study-planner.notion.site/Legal-Notice-143e068d9afc80339837f9bf09487d95")!)
                            } else if(entry.name == "Privacy Policy") {
                                openURL(URL(string: "https://study-planner.notion.site/Data-Privacy-143e068d9afc80c99501f18a5bbedae0")!)
                            }
                        }
                }
            }
            
            Section(footer: Text("\(viewModel.getVersionInformation())")) {
                SettingsEntryView(entry: SettingsEntry(name: "Licences", image: "list.clipboard.fill", color: UIColor.gray))
                    .listRowInsets(EdgeInsets())
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isLicencesSheetPresented = true
                    }
                    .sheet(isPresented: $isLicencesSheetPresented) {
                        if let url = Bundle.main.url(forResource: "Package", withExtension: "resolved"),
                           let data = try? Data(contentsOf: url),
                           let acknowList = try? AcknowPackageDecoder().decode(from: data) {
                            NavigationStack {
                                List {
                                    ForEach (acknowList.acknowledgements) { acknowledgement in
                                        if let destination = acknowledgement.repository {
                                            Link(destination: destination) {
                                                Text(acknowledgement.title)
                                                    .foregroundColor(Color(UIColor.label))
                                                    .bold()
                                            }
                                        }
                                    }
                                }
                                .navigationTitle("Licences")
                                .scrollIndicators(.hidden)
                                .toolbar {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color(UIColor.systemGray3))
                                        .onTapGesture {
                                            isLicencesSheetPresented = false
                                        }
                                }
                            }
                        }
                    }
            }
            
            Section {
                HStack {
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 20) {
                        Text("Made with ❤ in CAB G41")
                        Text("Built by: \nLuca, Alex, Julius,\nJoel, Sven, Sven \n\nETH Study Planner is neither supported by ETH nor by VSETH, its a private initiative run by Students. \n\nCourse data taken from vvz.ethz.ch. No guarantee for accuracy and completeness.")
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .onTapGesture {
                    amountOfClicks += 1
                    
                    if(amountOfClicks >= 7) {
                        isABPopupShown = true
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.defaultMinListRowHeight, 10)
    }
}

struct SettingsEntryView: View {
    @State var entry: SettingsEntry
    
    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                Color(entry.color)
                Image(systemName: entry.image)
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(width: 29, height: 29)
            .cornerRadius(5)
            
            Text("\(entry.name)")
                .font(.system(size: 18))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(UIColor.lightGray))
        }
        .padding(.vertical, 10)
        .padding(.leading, 13)
        .padding(.trailing, 14)
    }
}

#Preview {
    SettingsView()
}
