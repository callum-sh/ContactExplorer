//
//  Home.swift
//  ContactExplorer
//
//  Created by Harvin Park on 2/23/25.
//

import Foundation
import SwiftUI

struct HomeView: View {
    
    @State private var isEditing = false
    @State private var messageText = ""
    
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
                    // Background rectangle
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                        .frame(height: 100)
                        .offset(y:30)
                    
                    if isEditing {
                        TextField("", text: $messageText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .frame(height: 50)
                            .padding(.horizontal, 20)
                            .background(Color.clear)
                            .foregroundColor(.black)
                            .offset(y: 30)
                    } else {
                        Text("type to chat")
                            .foregroundColor(.secondary)
                            .offset(y: 30)
                            .onTapGesture {
                                isEditing = true
                            }
                    }
                }
                
                
                
            }
        }
    }
}

#Preview{
    HomeView()
}
