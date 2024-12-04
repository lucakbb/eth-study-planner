//
//  ABVersionSettings.swift
//  ETH Credit Planner
//
//  Created by Luca Blume on 22.11.24.
//

import SwiftUI

struct ABVersionSettings: View {
    @Binding var isPresented: Bool
    @AppStorage("BVersionRecommendations") private var bVersionRecommendations = false
    @AppStorage("BVersionTemplates") private var bVersionTemplates = false
    
    var body: some View {
        NavigationStack {
            List {
                HStack(spacing: 13) {
                    ZStack {
                        Color(Color("Color3"))
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(width: 29, height: 29)
                    .cornerRadius(5)
                    
                    Text("B-Version Recommendation")
                        .font(.system(size: 18))
                    
                    Spacer()
                    
                    Toggle("B-Version", isOn: $bVersionRecommendations)
                        .labelsHidden()
                }
                .padding(.vertical, 10)
                .padding(.leading, 13)
                .padding(.trailing, 14)
                .listRowInsets(EdgeInsets())
                .contentShape(Rectangle())
                
                HStack(spacing: 13) {
                    ZStack {
                        Color(Color("Color3"))
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(width: 29, height: 29)
                    .cornerRadius(5)
                    
                    Text("B-Version Templates")
                        .font(.system(size: 18))
                    
                    Spacer()
                    
                    Toggle("B-Version", isOn: $bVersionTemplates)
                        .labelsHidden()
                }
                .padding(.vertical, 10)
                .padding(.leading, 13)
                .padding(.trailing, 14)
                .listRowInsets(EdgeInsets())
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 12)
            .toolbar {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color(UIColor.systemGray3))
                    .onTapGesture {
                        isPresented = false
                    }
            }
            .navigationTitle("A/B Tests")
        }
    }
}

#Preview {
    ABVersionSettings(isPresented: .constant(true))
}
