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
            HomeView()
        }
    }
}


#Preview {
    ContentView()
}
