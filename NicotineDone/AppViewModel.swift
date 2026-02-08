import SwiftUI
import CoreData
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published var user: User?
    @Published var shouldShowOnboarding = false

    private let context: NSManagedObjectContext
    private let userRepository: UserRepository
    private let gamification: GamificationService

    init(environment: AppEnvironment) {
        self.context = environment.context
        self.userRepository = environment.userRepository
        self.gamification = environment.gamificationService
        loadUser()
    }

    func loadUser() {
        if let existing = userRepository.fetchUser() {
            user = existing
            shouldShowOnboarding = false
        } else {
            shouldShowOnboarding = true
        }
    }

    func completeOnboarding(with profile: NicotineProfile) {
        let newUser = userRepository.createUser(from: profile)

        gamification.bootstrapCatalogIfNeeded()
        context.saveIfNeeded()

        user = newUser
        shouldShowOnboarding = false
    }

    func resetOnboarding() {
        user = nil
        shouldShowOnboarding = true
    }

}
