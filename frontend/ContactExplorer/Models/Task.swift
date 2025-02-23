//
//  ChatItem.swift
//  ContactExplorer
//
//  Created by callum on 2025-02-23.
//

import Foundation

struct Task: Identifiable, Codable {
    let id: Int
    let date: String
    let task: String
    
    // convert the `date` string into a Swift `Date`
    var formattedDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: date)
    }
}
