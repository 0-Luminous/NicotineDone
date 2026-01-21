//
//  NicotineDoneApp.swift
//  NicotineDone
//
//  Created by Yan Nosov on 21/1/2569 BE.
//

import SwiftUI
import CoreData

@main
struct NicotineDoneApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
