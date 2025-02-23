//
//  Toggle.swift
//  ContactExplorer
//
//  Created by Harvin Park on 2/23/25.
//

import SwiftUI

struct ToggleView: View {
    
    var activeForeground: Color = .white
    var activeBackground: Color = .blue
    
    @Binding var activeTab: TabModel
    
    var body: some View {
        
        HStack(spacing: 0) {
            
            ForEach(TabModel.allCases, id: \.rawValue) { tab in
                Button {
                    activeTab = tab
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.rawValue)
                            .font(.title3.bold())
                            .frame(width:30, height: 30)
                        if activeTab == tab {
                            Text(tab.title)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                        }
                    }
                    .foregroundStyle(activeTab == tab ? activeForeground : . gray)
                    .padding(.vertical, 2)
                    .padding(.leading, 10)
                    .padding(.trailing, 15)
                    .contentShape(.rect)
                    .background{
                        if activeTab == tab {
                            Capsule()
                                .fill(activeBackground.gradient)
                        }
                    }
                
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.smooth(duration:0.3, extraBounce: 0), value: activeTab)
    }
}

#Preview {
    ContentView()
}


/*
 
 // Left button
 Button(action: {
     withAnimation(.spring()) {
         isActive = false
     }
 }) {
     Text("Chat")
         .padding(.vertical, 10)
         .padding(.horizontal, 20)
         .background(!isActive ? Color.blue : Color.gray.opacity(0.3))
         .foregroundColor(!isActive ? .white : .gray)
 }
 
 // Right button
 Button(action: {
     withAnimation(.spring()) {
         isActive = true
     }
 }) {
     Text("Contact")
         .padding(.vertical, 10)
         .padding(.horizontal, 20)
         .background(isActive ? Color.blue : Color.gray.opacity(0.3))
         .foregroundColor(isActive ? .white : .gray)
 }
 */
