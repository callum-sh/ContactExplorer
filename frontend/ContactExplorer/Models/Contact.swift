//
//  Contact.swift
//  ContactExplorer
//
//  Created by callum on 2025-02-22.
//

import Foundation

class MyContact: Identifiable, ObservableObject {
    let id: String
    var embedding: [Double]?
    @Published var name: String
    @Published var workplace: String?
    @Published var school: String?
    @Published var note: String
    @Published var phoneNumbers: [String]

    init(id: String, name: String, note: String, phoneNumbers: [String], embedding: [Double]? = nil) {
        self.id = id
        self.name = name
        self.note = note
        self.phoneNumbers = phoneNumbers
        self.embedding = embedding
    }
}
