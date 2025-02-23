import SwiftUI
import Contacts
import CoreData
import NaturalLanguage

struct ContentView: View {
    @State private var contacts: [MyContact] = []
    @State private var isFetching = true
    @State private var searchQuery = ""
    @State private var selectedContact: MyContact?
    @State private var isNavigating = false
    @Environment(\.managedObjectContext) private var viewContext
    @FocusState private var isSearchFieldFocused: Bool // Add focus state for better keyboard control



    var body: some View {
        NavigationView {
            VStack {
                TextField("Search contacts", text: $searchQuery, onCommit: {
                    performSearch()
                    isSearchFieldFocused = false // Dismiss keyboard after search
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .focused($isSearchFieldFocused)
                .keyboardType(.asciiCapable)

                if isFetching {
                    ProgressView("Fetching contacts...")
                } else {
                    // Pass a closure to handle tapping a contact.
                    ContactListView(contacts: contacts)
                }
            }
            .navigationTitle("Contacts")
            // Hidden NavigationLink that triggers when isNavigating becomes true.
            .background(
                NavigationLink(
                    destination: destinationView,
                    isActive: $isNavigating,
                    label: { EmptyView() }
                )
                .hidden()
            )
        }
        .onAppear {
            loadContactsFromCoreData()
            fetchContacts()
        }
    }

    // Extracted destination view for clarity.
    @ViewBuilder
    private var destinationView: some View {
        if let contact = selectedContact {
            ContactDetailView(contact: contact)
        } else {
            EmptyView()
        }
    }

    // Rest of your existing functions remain unchanged
    private func generateEmbedding(for text: String) -> [Double]? {
        let embedding = NLEmbedding.sentenceEmbedding(for: .english)
        guard let vector = embedding?.vector(for: text) else { return nil }
        return normalize(vector)
    }
    
    private func performSearch() {
        print("searching... q: \(searchQuery)")
        guard !searchQuery.isEmpty else { return }
        guard let queryEmbedding = generateEmbedding(for: searchQuery) else { return }
        let similarities = contacts.map { contact in
            computeSimilarity(contact.embedding, queryEmbedding)
        }
        if let maxIndex = similarities.firstIndex(of: similarities.max() ?? 0) {
            selectedContact = contacts[maxIndex]
            isNavigating = true
        }
        print("done searching; top result is \(selectedContact?.name ?? "unknown")")
    }
    
    private func computeSimilarity(_ emb1: [Double]?, _ emb2: [Double]?) -> Double {
        guard let e1 = emb1, let e2 = emb2, e1.count == e2.count else { return 0 }
        return zip(e1, e2).map { $0 * $1 }.reduce(0, +)
    }
    
    private func normalize(_ vector: [Double]) -> [Double] {
        let norm = sqrt(vector.map { $0 * $0 }.reduce(0, +))
        guard norm > 0 else { return vector }
        return vector.map { $0 / norm }
    }
    
    private var sortedContacts: [MyContact] {
        if searchQuery.isEmpty {
            return contacts
        }
        guard let queryEmbedding = generateEmbedding(for: searchQuery) else {
            return contacts
        }
        return contacts.sorted { contactA, contactB in
            let simA = computeSimilarity(contactA.embedding, queryEmbedding)
            let simB = computeSimilarity(contactB.embedding, queryEmbedding)
            return simA > simB
        }
    }
    
    private func computeSimilarity(_ emb1: [Float]?, _ emb2: [Float]?) -> Float {
        guard let e1 = emb1, let e2 = emb2, e1.count == e2.count else { return 0 }
        return zip(e1, e2).map { $0 * $1 }.reduce(0, +)
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
        let embedding = NLEmbedding.sentenceEmbedding(for: .english)
        guard embedding != nil else {
            print("Sentence embedding not available for English")
            return
        }
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ContactEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try viewContext.execute(deleteRequest)
        } catch {
            print("Failed to clear Core Data: \(error)")
        }
        for contact in contacts {
            let entity = ContactEntity(context: viewContext)
            entity.id = contact.id
            entity.name = contact.name
            entity.note = contact.note
            entity.phoneNumbers = contact.phoneNumbers.joined(separator: ",")
            let text = "Name: \(contact.name). Notes: \(contact.note)"
            if let vector = embedding?.vector(for: text) {
                let normalizedVector = normalize(vector)
                let floatVector = normalizedVector.map { Float($0) }
                entity.embedding = floatVector.withUnsafeBufferPointer { Data(buffer: $0) }
            } else {
                entity.embedding = nil
            }
        }
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
                let embedding: [Double]? = entity.embedding?.withUnsafeBytes { buffer in
                    Array(buffer.bindMemory(to: Double.self))
                }
                return MyContact(
                    id: entity.id ?? UUID().uuidString,
                    name: entity.name ?? "No Name",
                    note: entity.note ?? "No notes",
                    phoneNumbers: entity.phoneNumbers?.components(separatedBy: ",") ?? [],
                    embedding: embedding
                )
            }
            self.contacts = storedContacts
            self.isFetching = false
        } catch {
            print("Failed to fetch from Core Data: \(error)")
        }
    }
}
