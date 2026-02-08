import Foundation
import CoreData
import Combine

@MainActor
final class AchievementsViewModel: ObservableObject {
    @Published var achievementState = AchievementState()

    let user: User
    let achievements: [AchievementItem]

    private let entryRepository: EntryRepository
    private let calendar: Calendar
    private let dateProvider: () -> Date

    init(user: User,
         environment: AppEnvironment,
         achievements: [AchievementItem] = AchievementItem.catalog) {
        self.user = user
        self.achievements = achievements
        self.entryRepository = environment.entryRepository
        self.calendar = environment.calendar
        self.dateProvider = environment.dateProvider
    }

    func refresh() {
        achievementState = AchievementStateBuilder(entryRepository: entryRepository,
                                                   user: user,
                                                   calendar: calendar,
                                                   dateProvider: dateProvider).build()
        unlockRewardThemes()
    }

    private func unlockRewardThemes() {
        let themes: [DashboardBackgroundStyle] = achievements.compactMap { item in
            item.isAchieved(using: achievementState) ? item.rewardTheme : nil
        }
        ThemeUnlockStore.setUnlocked(themes)
    }
}
