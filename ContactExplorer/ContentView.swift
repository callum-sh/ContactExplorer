import SwiftUI
import Contacts
import CoreData

struct ContentView: View {
    @State private var contacts: [MyContact] = []
    @State private var isFetching = true
    
    // Access the environment context if you need it directly
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            Group {
                if isFetching {
                    ProgressView("Fetching contacts...")
                } else {
                    // Displaying fetched contacts from CNContactStore
                    // or from Core Data
                    ContactListView(contacts: contacts)
                }
            }
            .navigationTitle("Contacts")
        }
        .onAppear {
            // First try loading from Core Data (if you want immediate display):
            loadContactsFromCoreData()
            
            // Then optionally fetch from device contacts (overwriting if permission is granted).
            fetchContacts()
        }
    }
    
    private func fetchContacts() {
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
                            let displayName = "\(contact.givenName) \(contact.familyName)"
                                .trimmingCharacters(in: .whitespaces)
                            let newContact = MyContact(
                                id: contact.identifier,
                                name: displayName.isEmpty ? "No Name" : displayName,
                                note: "no notes",
                                phoneNumbers: contact.phoneNumbers.map { $0.value.stringValue }
                            )
                            fetchedContacts.append(newContact)
                        }
                        
                        // Once done fetching, save to Core Data
                        DispatchQueue.main.async {
                            saveContactsToCoreData(fetchedContacts)
                            self.contacts = fetchedContacts
                            self.isFetching = false
                        }
                    } catch {
                        print("Error fetching contacts: \(error)")
                        DispatchQueue.main.async {
                            self.isFetching = false
                        }
                    }
                }
            } else {
                print("Contacts permission denied: \(error?.localizedDescription ?? "")")
                DispatchQueue.main.async {
                    self.isFetching = false
                }
            }
        }
    }
    
    private func saveContactsToCoreData(_ contacts: [MyContact]) {
        // Clear existing first (optional)
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ContactEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(deleteRequest)
        } catch {
            print("Failed to clear Core Data: \(error)")
        }
        
        // Now insert fresh data
        for contact in contacts {
            let entity = ContactEntity(context: viewContext)
            entity.id = contact.id
            entity.name = contact.name
            entity.note = contact.note
            entity.phoneNumbers = contact.phoneNumbers.joined(separator: ",")
        }
        
        // Save
        do {
            try viewContext.save()
        } catch {
            print("Error saving to Core Data: \(error)")
        }
    }
    
    private func loadContactsFromCoreData() {
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        do {
            let entities = try viewContext.fetch(request)
            let storedContacts = entities.map { entity -> MyContact in
                MyContact(
                    id: entity.id ?? UUID().uuidString,
                    name: entity.name ?? "No Name",
                    note: entity.note ?? "",
                    phoneNumbers: entity.phoneNumbers?
                        .components(separatedBy: ",") ?? []
                )
            }
            self.contacts = storedContacts
            self.isFetching = false
        } catch {
            print("Failed to fetch from Core Data: \(error)")
        }
    }
}
