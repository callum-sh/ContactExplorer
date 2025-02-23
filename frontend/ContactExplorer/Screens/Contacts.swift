//
//  Contacts.swift
//  ContactExplorer
//
//  Created by callum on 2025-02-23.
//

import Foundation
import SwiftUI

struct ContactsView: View {
    @StateObject private var viewModel = GetChats()
    
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
                        Image("croppedpfp")
                            .resizable()
                            .frame(width:50, height:50)
                        
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

#Preview{
    ContactsView()
}
