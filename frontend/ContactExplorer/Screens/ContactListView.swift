//
//  ContactListView.swift
//  ContactExplorer
//
//  Created by callum on 2025-02-22.
//

import SwiftUI

struct ContactRow: View {
    let contact: MyContact
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(contact.name)
                .font(.headline)
            if !contact.phoneNumbers.isEmpty {
                Text(contact.phoneNumbers.first ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ContactListView: View {
    let contacts: [MyContact]
    
    var body: some View {
        List(contacts) { contact in
            NavigationLink(destination: ContactDetailView(contact: contact)) {
                ContactRow(contact: contact)
            }
        }
    }
}
