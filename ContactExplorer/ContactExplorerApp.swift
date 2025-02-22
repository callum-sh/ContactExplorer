//
//  ContactExplorerApp.swift
//  ContactExplorer
//
//  Created by callum on 2025-02-22.
//

import SwiftUI

@main
struct ContactManagerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
