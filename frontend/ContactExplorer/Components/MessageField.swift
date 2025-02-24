//
//  MessageField.swift
//  ContactExplorer
//
//  Created by Harvin Park on 2/23/25.
//

import SwiftUI

struct MessageField: View {
    @Binding var message: String
    var onSend: (String) -> Void
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        HStack {
            CustomTextField(placeholder: Text("or type here to chat"), text: $message, isFocused: $isFocused)
            
            Button {
                guard !message.isEmpty else { return }
                onSend(message)
                message = ""
            } label: {
                Image(systemName: "arrow.up")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color(.gray))
                    .cornerRadius(10)
            }
            .offset(y: -40)
        }
        .padding(.horizontal)
        .padding(10)
    }
}

struct CustomTextField: View {
    var placeholder: Text
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool // Accept FocusState
    
    var editingChanged: (Bool) -> () = {_ in}
    var commit: () -> () = {}

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty{
                placeholder
                    .opacity(0.5)
            }
            
            TextField("", text: $text, onEditingChanged: editingChanged, onCommit: commit)
                .focused($isFocused) // Apply FocusState binding
        }
        .padding()
        .padding(.bottom, 80)
        .background(
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    isFocused = true
                }
        )
    }
}

