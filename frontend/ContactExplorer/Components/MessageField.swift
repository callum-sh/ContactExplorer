//
//  MessageField.swift
//  ContactExplorer
//
//  Created by Harvin Park on 2/23/25.
//

import SwiftUI

struct MessageField: View {
    @State private var message = ""
    var body: some View {
        HStack{
            CustomTextField(placeholder: Text("or type here to chat"), text:$message)
            
            Button{
                print("Message sent!")
                message = ""
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color(.gray))
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
        .padding(10)
        .background(Color("Gray"))
        .cornerRadius(20)
        
        
    }
}

#Preview {
    MessageField()
}

struct CustomTextField: View {
    var placeholder: Text
    @Binding var text: String
    
    var editingChanged: (Bool) -> () = {_ in}
    var commit: () -> () = {}
    
    var body: some View{
        ZStack(alignment: .leading) {
            if text.isEmpty {
                placeholder
                    .opacity(0.5)
            }
            
            TextField("", text: $text, onEditingChanged:
                        editingChanged, onCommit: commit)
        }
    }
    
}
