import SwiftUI
import Contacts
import Speech
import AVFoundation

struct ContactDetailView: View {
    let contact: MyContact
    @State private var noteText: String = "" // Local state for the note
    @State private var isRecognizing: Bool = false // Tracks if speech recognition is active
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var audioEngine = AVAudioEngine()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    
    var body: some View {
        ZStack {
            // Existing Form content
            Form {
                // Name Section
                Section(header: Text("Name")) {
                    Text(contact.name)
                }
                
                // Note Section
                Section(header: Text("Note")) {
                    TextField("Note", text: $noteText) // Editable note field
                }
                
                // Phone Numbers Section
                Section(header: Text("Phone Numbers")) {
                    if contact.phoneNumbers.isEmpty {
                        Text("No phone numbers")
                    } else {
                        ForEach(contact.phoneNumbers, id: \.self) { phone in
                            Text(phone)
                        }
                    }
                }
            }
            
            // Pulsing green button at the bottom center
            VStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(isRecognizing ? Color.green : Color.blue)
                    Text(isRecognizing ? "Listening..." : "Hold to Speak")
                        .foregroundColor(.white)
                }
                .frame(width: 100, height: 100) // Button size
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isRecognizing {
                                SFSpeechRecognizer.requestAuthorization { authStatus in
                                    DispatchQueue.main.async {
                                        if authStatus == .authorized {
                                            self.startSpeechRecognition()
                                            self.isRecognizing = true
                                        } else {
                                            print("Speech recognition not authorized")
                                        }
                                    }
                                }
                            }
                        }
                        .onEnded { _ in
                            self.isRecognizing = false
                            self.stopSpeechRecognition()
                        }
                )
                .padding(.bottom, 20)
            }
        }
        .navigationTitle(contact.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveNote()
                }
            }
        }
        .onAppear {
            noteText = contact.note
        }
        .onDisappear {
            stopSpeechRecognition()
        }
    }
    
    // MARK: - Speech Recognition Functions
    
    /// Starts the speech recognition process
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
                    self.noteText = result.bestTranscription.formattedString // Update note text
                }
            }
            if error != nil || result?.isFinal == true {
                self.stopSpeechRecognition()
                self.isRecognizing = false
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
    
    // MARK: - Note Saving Function
    
    /// Saves the updated note to the contact store
    private func saveNote() {
        let store = CNContactStore()
        do {
            let keys = [CNContactNoteKey as CNKeyDescriptor]
            let mutableContact = try store.unifiedContact(withIdentifier: contact.id, keysToFetch: keys).mutableCopy() as! CNMutableContact
            mutableContact.note = noteText
            let saveRequest = CNSaveRequest()
            saveRequest.update(mutableContact)
            try store.execute(saveRequest)
            print("Note saved successfully")
        } catch {
            print("Error saving note: \(error)")
        }
    }
}
