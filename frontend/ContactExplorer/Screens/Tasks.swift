//
//  Contacts.swift
//  ContactExplorer
//
//  Created by callum on 2025-02-23.
//

import Foundation
import SwiftUI

struct TasksView: View {
    @StateObject private var viewModel = GetTasks()
    
    var body: some View {
        ZStack {
            //background orb
            Image("orb1")
                .resizable()
                .frame(width: 750, height: 750)
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .blur(radius: 5)
                .offset(x:150, y:-10)
            
            
            // Overlay layer
            Rectangle()
                .fill(.white.opacity(0.2))
                .ignoresSafeArea()
            
            Rectangle()
                .fill(.black.opacity(0.1))
                .ignoresSafeArea()
            
            //content layer
            VStack{
                HStack{
                    Spacer()
                    HStack(spacing: 18){
                        NavigationLink(destination: HomeView()) {
                            Image(systemName: "xmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.gray)
                                .padding(15)
                                .background(Circle().stroke(.gray))
                        }
                        
                        Image("croppedpfp")
                            .resizable()
                            .frame(width:50, height:50)
                    }

                }
                .frame(width: UIScreen.main.bounds.width)
                .padding(.trailing, 40)
                
                Spacer()
                
                ZStack{
                    VStack {
                        // The list of items
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(viewModel.tasks) { task in
                                    TaskCardView(taskItem: task)
                                }
                            }
                            .padding(.top, 10)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchTasks()
        }
    }
}

#Preview{
    TasksView()
}
