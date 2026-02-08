import SwiftUI
import CoreData

struct AppEnvironment {
    let context: NSManagedObjectContext
    let calendar: Calendar
    let dateProvider: () -> Date
    let settingsStore: SettingsStore
    let savedMethodsStore: SavedMethodsStore
    let userRepository: UserRepository
    let entryRepository: EntryRepository
    let statsRepository: StatsRepository
    let achievementRepository: AchievementRepository
    let statsService: StatsService
    let trackingService: TrackingService
    let gamificationService: GamificationService

    static func live(context: NSManagedObjectContext) -> AppEnvironment {
        let calendar = Calendar.current
        let settingsStore = InMemorySettingsStore()
        let savedMethodsStore = SavedMethodsStore()
        let userRepository = CoreDataUserRepository(context: context)
        let entryRepository = CoreDataEntryRepository(context: context)
        let statsRepository = CoreDataStatsRepository(context: context)
        let achievementRepository = CoreDataAchievementRepository(context: context)
        let statsService = StatsService(statsRepository: statsRepository,
                                        entryRepository: entryRepository,
                                        calendar: calendar)
        let gamificationService = GamificationService(context: context,
                                                      stats: statsService,
                                                      achievementRepository: achievementRepository)
        let trackingService = TrackingService(context: context,
                                              entryRepository: entryRepository,
                                              statsService: statsService,
                                              gamification: gamificationService)
        return AppEnvironment(context: context,
                              calendar: calendar,
                              dateProvider: Date.init,
                              settingsStore: settingsStore,
                              savedMethodsStore: savedMethodsStore,
                              userRepository: userRepository,
                              entryRepository: entryRepository,
                              statsRepository: statsRepository,
                              achievementRepository: achievementRepository,
                              statsService: statsService,
                              trackingService: trackingService,
                              gamificationService: gamificationService)
    }

    static var preview: AppEnvironment {
        AppEnvironment.live(context: PersistenceController.preview.container.viewContext)
    }
}

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment.live(context: PersistenceController.shared.container.viewContext)
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
