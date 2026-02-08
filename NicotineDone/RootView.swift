//
//  ContentView.swift
//  CigTrack
//
//  Created by Yan on 4/11/25.
//

import SwiftUI
import CoreData

struct RootView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.appEnvironment) private var appEnvironment

    var body: some View {
        Group {
            if appViewModel.shouldShowOnboarding {
                OnboardingView()
            } else if let user = appViewModel.user {
                MainDashboardView(user: user, environment: appEnvironment)
            } else {
                ProgressView()
                    .onAppear(perform: appViewModel.loadUser)
            }
        }
        .animation(.easeInOut, value: appViewModel.shouldShowOnboarding)
    }
}

#Preview {
    RootView()
        .environment(\.appEnvironment, AppEnvironment.preview)
        .environmentObject(AppViewModel(environment: AppEnvironment.preview))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
