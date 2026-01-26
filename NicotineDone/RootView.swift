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

    var body: some View {
        Group {
            if appViewModel.shouldShowOnboarding {
                OnboardingView()
            } else if let user = appViewModel.user {
                MainDashboardView(user: user)
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
        .environmentObject(AppViewModel(context: PersistenceController.preview.container.viewContext))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
