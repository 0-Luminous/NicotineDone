//
//  CigTrackApp.swift
//  CigTrack
//
//  Created by Yan on 4/11/25.
//

import SwiftUI
import CoreData

@main
struct PuffQuestApp: App {
    private let persistenceController = PersistenceController.shared
    @StateObject private var appViewModel = AppViewModel(context: PersistenceController.shared.container.viewContext)
    @AppStorage("appPreferredColorScheme") private var appPreferredColorSchemeRaw: Int = 0
    
    private var preferredColorScheme: ColorScheme? {
        switch appPreferredColorSchemeRaw {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorSchemeIfNeeded(preferredColorScheme)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appViewModel)
        }
    }
}

extension View {
    @ViewBuilder
    func preferredColorSchemeIfNeeded(_ scheme: ColorScheme?) -> some View {
        if let scheme {
            preferredColorScheme(scheme)
        } else {
            self
        }
    }
}
