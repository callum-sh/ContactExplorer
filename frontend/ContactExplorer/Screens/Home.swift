//
//  Home.swift
//  ContactExplorer
//
//  Created by Harvin Park on 2/23/25.
//

import Foundation
import SwiftUI


struct HomeView: View {
    @StateObject private var viewModel = GetChatItems()
    
    @State private var activeTab: TabModel = .chat
    
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
                .fill(.white.opacity(0.4))
                .ignoresSafeArea()
            
            Rectangle()
                .fill(.black.opacity(0.1))
                .ignoresSafeArea()
            
            //content layer
            VStack{
                HStack{
                    HStack{
                        ToggleView(activeTab: $activeTab)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    
                    HStack(spacing: 18){
                        Image("croppedpfp")
                            .resizable()
                            .frame(width:50, height:50)
                        
                        Image("croppedpfp")
                            .resizable()
                            .frame(width:50, height:50)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 20)
                }
                .frame(width: UIScreen.main.bounds.width)
                
                if activeTab == .chat {
                    Spacer()
                    
                    
                    ZStack{
                        // Background rectangle
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white)
                            .offset(y:40)
                            .shadow(color: .gray, radius: 5, x: 0, y: 5)
                            .ignoresSafeArea()
                        
                        MessageField()
                            .padding(.top, 20)
                            
                        
                    }
                    .frame(width:UIScreen.main.bounds.width, height: 120)
                } else {
                    
                    Spacer()
                    
                    ZStack{
                        VStack {
                            // The list of items
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.chats) { chat in
                                        ChatCardView(chatItem: chat)
                                    }
                                }
                                .padding(.top, 10)
                            }
                        }
                    }
                }
            }
            .onAppear {
                viewModel.fetchChats()
            }
        }
    }
}

#Preview{
    HomeView()
}
