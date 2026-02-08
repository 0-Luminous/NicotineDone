//
//  CigTrackApp.swift
//  CigTrack
//
//  Created by Yan on 4/11/25.
//

import SwiftUI
import CoreData
import Combine

@main
struct PuffQuestApp: App {
    private let persistenceController = PersistenceController.shared
    private let appEnvironment: AppEnvironment
    @StateObject private var appViewModel: AppViewModel
    @AppStorage("appPreferredColorScheme") private var appPreferredColorSchemeRaw: Int = 0

    init() {
        let environment = AppEnvironment.live(context: persistenceController.container.viewContext)
        self.appEnvironment = environment
        _appViewModel = StateObject(wrappedValue: AppViewModel(environment: environment))
    }
    
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
                .environment(\.appEnvironment, appEnvironment)
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
