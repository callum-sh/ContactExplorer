import Foundation
import SwiftUI
import Speech
import AVFoundation


struct HomeView: View {
    @StateObject private var viewModelChat = GetChats()
    @StateObject private var viewModel = ContactsViewModel()
    @ObservedObject private var postQuery = PostQuery()
    
    @State private var isListening = false
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var audioEngine = AVAudioEngine()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    
    
    @State private var activeTab: TabModel = .chat
    @State private var showTasksView = false
    
    @State private var displayedResponse = ""
    @State private var messageText = ""
    @State private var showResponse = false
    
    @State private var keyboardHeight: CGFloat = 0
    
    // Add FocusState to handle keyboard
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack {
            //background orb
            Image("orb1")
                .resizable()
                .frame(width: 750, height: 750)
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .blur(radius: isListening ? 0 : 5)
                .offset(x: 150, y: -10)
                .animation(.easeInOut(duration: 0.3), value: isListening)
            
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
                
                //main chat interface
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
                    
                    // chat field at bottom of page
                    ZStack{
                        // background rectangle
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white)
                            .offset(y:40)
                            .shadow(color: .gray, radius: 5, x: 0, y: 5)
                            .ignoresSafeArea()
                        
                        //text field
                        MessageField(message: $messageText, onSend: { message in
                            postQuery.sendQuery(message) { response in
                                showResponseWithTypingAnimation(response)
                            }
                        }, isFocused: $isInputFocused)
                        .padding(.top, 40)

                    }
                    .frame(width:UIScreen.main.bounds.width, height: 120)
                    .offset(y: -keyboardHeight + 40)
                    .animation(.easeOut(duration: 0.25), value: keyboardHeight)
                    
                } else {
                    // display recent chat logs
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
        }
        .onTapGesture {
            isInputFocused = false
        }
        .fullScreenCover(isPresented: $showTasksView) {
            TasksView(showTasksView: $showTasksView)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if (activeTab == .chat) {
                        withAnimation {
                            if !isListening {
                                SFSpeechRecognizer.requestAuthorization { authStatus in
                                    DispatchQueue.main.async {
                                        if authStatus == .authorized {
                                            self.startSpeechRecognition()
                                            self.isListening = true
                                        } else {
                                            print("Speech recognition not authorized")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .onEnded { _ in
                    if (activeTab == .chat) {
                        withAnimation {
                            self.isListening = false
                            self.stopSpeechRecognition()
                        }
                    }
                }
        )
    }
    
    //Keyboard Handling
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            keyboardHeight = keyboardFrame.height - 40
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
    
    private func startSpeechRecognition() {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Set up audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }
        
        // Prepare audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0) // Remove any existing tap
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start failed: \(error)")
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    // Update messageText with recognized text
                    self.messageText = result.bestTranscription.formattedString
                }
            }
            if error != nil || result?.isFinal == true {
                self.stopSpeechRecognition()
                self.isListening = false
            }
        }
    }
        
    /// Stops the speech recognition process and cleans up
    private func stopSpeechRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

#Preview {
    HomeView()
}
