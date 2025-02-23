//
//  PostQuery.swift
//  ContactExplorer
//
//  Created by callum on 2025-02-23.
//
import Foundation

class PostQuery: ObservableObject {
    @Published var responseSummary: String = ""
    private let apiURL = "https://d486-67-245-209-108.ngrok-free.app/query"

    /// send query input to the API
    func sendQuery(_ query: String, onResponse: @escaping (String) -> Void) {
        print("sending", query)
        guard let url = URL(string: apiURL) else {
            print("❌ Invalid API URL")
            return
        }

        let requestBody: [String: String] = ["query": query]
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            print("❌ Failed to encode JSON")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("❌ Error sending query: \(error.localizedDescription)")
                        return
                    }

                    guard let data = data else {
                        print("❌ No data received")
                        return
                    }

                    do {
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let summary = jsonResponse["summary"] as? String {
                            DispatchQueue.main.async {
                                self.responseSummary = summary
                                onResponse(summary)
                                print("✅ Query Summary: \(summary)")
                            }
                        } else {
                            print("❌ 'summary' field not found in response")
                        }
                    } catch {
                        print("❌ Decoding error: \(error)")
                    }
                }.resume()
    }
}

