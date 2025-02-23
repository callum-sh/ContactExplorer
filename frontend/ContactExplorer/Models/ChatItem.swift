//
//  ChatItem.swift
//  ContactExplorer
//
//  Created by callum on 2025-02-23.
//

import Foundation

struct ChatItem: Identifiable, Codable {
    let id: Int
    let name: String?
    let date: String
    let query: String
    
    // convert the `date` string into a Swift `Date`
    var formattedDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: date)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case date = "created_at"
        case query
    }
}
