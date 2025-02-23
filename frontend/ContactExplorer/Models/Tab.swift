//
//  TabModel.swift
//  ContactExplorer
//
//  Created by Harvin Park on 2/23/25.
//

import SwiftUI

enum TabModel: String, CaseIterable {
    
    case chat = "house"
    case contacts = "magnifyingglass"
    
    var title: String{
        switch self{
        case .chat: "Chat"
        case .contacts: "Contacts"
        }
    }
}
