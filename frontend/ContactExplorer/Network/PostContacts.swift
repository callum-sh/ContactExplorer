//
//  PostContacts.swift
//  ContactExplorer
//
//  Created by callum on 2025-02-23.
//
import Foundation
import Contacts

class ContactsViewModel: ObservableObject {
    @Published var contacts: [MyContact] = []
    private let apiURL = "https://d486-67-245-209-108.ngrok-free.app/embedContact"

    /// Fetch contacts from the device and send to API
    func fetchContacts() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            if granted {
                DispatchQueue.global(qos: .userInitiated).async {
                    let keys: [CNKeyDescriptor] = [
                        CNContactGivenNameKey as CNKeyDescriptor,
                        CNContactFamilyNameKey as CNKeyDescriptor,
                        CNContactPhoneNumbersKey as CNKeyDescriptor
                    ]
                    
                    let fetchRequest = CNContactFetchRequest(keysToFetch: keys)
                    var fetchedContacts: [MyContact] = []
                    
                    do {
                        try store.enumerateContacts(with: fetchRequest) { contact, _ in
                            let displayName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                            let newContact = MyContact(
                                id: contact.identifier,
                                name: displayName.isEmpty ? "No Name" : displayName,
                                note: "No notes",
                                phoneNumbers: contact.phoneNumbers.map { $0.value.stringValue },
                                embedding: nil
                            )
                            fetchedContacts.append(newContact)
                        }
                        
                        DispatchQueue.main.async {
                            self.contacts = fetchedContacts
                            self.sendContactsToAPI(fetchedContacts)
                        }
                        
                    } catch {
                        print("❌ Error fetching contacts: \(error)")
                    }
                }
            } else {
                print("❌ Contacts permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    /// Sends each fetched contact to the API
    private func sendContactsToAPI(_ contacts: [MyContact]) {
        guard let url = URL(string: apiURL) else {
            print("❌ Invalid API URL")
            return
        }

        for contact in contacts {
            let contactPayload = ContactPayload(
                name: contact.name,
                email: "",
                company: "",
                notes: contact.note,
                meta: contact.phoneNumbers
            )
            
            guard let jsonData = try? JSONEncoder().encode(contactPayload) else {
                print("❌ Failed to encode contact: \(contact.name)")
                continue
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Error sending contact \(contact.name): \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("✅ Successfully sent contact: \(contact.name)")
                } else {
                    print("⚠️ Failed to send contact \(contact.name), response: \(response.debugDescription)")
                }
            }.resume()
        }
    }
}

/// Struct for API JSON request
struct ContactPayload: Codable {
    let name: String
    let email: String
    let company: String
    let notes: String
    let meta: [String]
}

