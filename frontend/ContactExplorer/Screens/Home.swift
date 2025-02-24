//
//  Home.swift
//  ContactExplorer
//
//  Created by Harvin Park on 2/23/25.
//

import Foundation
import SwiftUI


struct HomeView: View {
    @StateObject private var viewModelChat = GetChats()
    @StateObject private var viewModel = ContactsViewModel()
    @ObservedObject private var postQuery = PostQuery()
    
    @State private var activeTab: TabModel = .chat
    @State private var showTasksView = false
    
    @State private var displayedResponse = ""
    @State private var showResponse = false
    
    @State private var keyboardHeight: CGFloat = 0
    
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
                        Button(action: {
                            showTasksView = true
                        }) {
                            Image(systemName: "bell.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.gray)
                                .padding(15)
                        }
                        
                        Image("croppedpfp")
                            .resizable()
                            .frame(width:50, height:50)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 20)
                }
                .frame(width: UIScreen.main.bounds.width)
                
                if (activeTab == .chat) {
                    
                    Spacer()
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
                    
                    // search field at bottom of page
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
                    .offset(y: -keyboardHeight)
                    .animation(.easeOut(duration: 0.25), value: keyboardHeight)
                    
                } else {
                    // display chat logs
                    
                    Spacer()
                    ZStack{
                        VStack {
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(viewModelChat.chats) { chat in
                                        ChatCardView(chatItem: chat)
                                    }
                                }
                                .padding(.top, 10)
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear {
                viewModelChat.fetchChats()
                setupKeyboardNotifications()
            }
            .onDisappear {
                removeKeyboardNotifications()
            }
        }.fullScreenCover(isPresented: $showTasksView) {
            TasksView(showTasksView: $showTasksView)
        }
    }
    
    //Keyboard Handling
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            keyboardHeight = keyboardFrame.height - 40 // Adjust for the bottom safe area if needed
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            keyboardHeight = 0
        }
    }
    
    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
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
