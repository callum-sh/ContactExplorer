//
//  ChatViewModel.swift
//  ContactExplorer
//
//  Created by callum on 2025-02-23.
//

import Foundation

class GetChats: ObservableObject {
    @Published var chats: [Chat] = []
    private let apiURL = "https://d486-67-245-209-108.ngrok-free.app/recentQueries"
    
    func fetchChats() {
        guard let url = URL(string: apiURL) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Error fetching chats: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("❌ No data received")
                return
            }
            
            do {
                let decodedChats = try JSONDecoder().decode([Chat].self, from: data)
                
                // update the UI on the main thread
                DispatchQueue.main.async {
                    self.chats = decodedChats
                }
            } catch {
                print("❌ Decoding error: \(error)")
            }
        }.resume()
    }
}
