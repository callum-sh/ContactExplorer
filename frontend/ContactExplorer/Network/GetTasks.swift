//
//  ChatViewModel.swift
//  ContactExplorer
//
//  Created by callum on 2025-02-23.
//

import Foundation

class GetTasks: ObservableObject {
    @Published var tasks: [Task] = []
    private let apiURL = "https://d486-67-245-209-108.ngrok-free.app/upcomingTasks"
    
    func fetchTasks() {
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
                let decodedTasks = try JSONDecoder().decode([Task].self, from: data)
                
                DispatchQueue.main.async {
                    self.tasks = decodedTasks
                }
            } catch {
                print("❌ Decoding error: \(error)")
            }
        }.resume()
    }
}
