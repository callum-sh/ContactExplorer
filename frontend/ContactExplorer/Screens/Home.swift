//
//  Home.swift
//  ContactExplorer
//
//  Created by Harvin Park on 2/23/25.
//

import Foundation
import SwiftUI


struct HomeView: View {
    @StateObject private var viewModel = ContactsViewModel()
    @ObservedObject private var postQuery = PostQuery()
    
    @State private var isEditing = false
    @State private var messageText = ""
    
    @State private var displayedResponse = ""
    @State private var showResponse = false
    
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
                        NavigationLink(destination: TasksView()) {
                            Image(systemName: "bell.fill")
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
                
                // display most recent response from query
                if showResponse {
                    ScrollView {
                        Text(displayedResponse)
                            .font(.custom("HelveticaNeue-Light", size: 34))
                            .frame(width: 362, alignment: .leading)
                            .padding()
                            .animation(.easeInOut(duration: 0.05), value: displayedResponse)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                
                Spacer()
                
                
                ZStack{
                    // Background rectangle
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white)
                        .offset(y:40)
                        .shadow(color: .gray, radius: 5, x: 0, y: 5)
                        .ignoresSafeArea()
                    
                    MessageField(onSend: { message in
                        postQuery.sendQuery(message) { response in
                            showResponseWithTypingAnimation(response)
                        }
                    })
                        .padding(.top, 20)
                        
                    
                }
                .frame(width:UIScreen.main.bounds.width, height: 120)
            }
        }
//        UNCOMMENT ONLY IF YOU WANT TO UPLOAD
//        .onAppear {
//            viewModel.fetchContacts()
//        }
    }
    
    private func showResponseWithTypingAnimation(_ fullText: String) {
        displayedResponse = ""
        showResponse = true

        let characters = Array(fullText)
        var index = 0

        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            if index < characters.count {
                displayedResponse.append(characters[index])
                index += 1
            } else {
                timer.invalidate()

                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        showResponse = false
                    }
                }
            }
        }
    }
}

#Preview{
    HomeView()
}
