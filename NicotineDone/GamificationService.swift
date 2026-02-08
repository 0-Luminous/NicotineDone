import Foundation
import CoreData

final class GamificationService {
    private let context: NSManagedObjectContext
    private let stats: StatsService
    private let achievementRepository: AchievementRepository
    private lazy var calendar = Calendar.current

    init(context: NSManagedObjectContext,
         stats: StatsService,
         achievementRepository: AchievementRepository) {
        self.context = context
        self.stats = stats
        self.achievementRepository = achievementRepository
    }

    static func level(forXP xp: Int64) -> Int {
        max(1, Int(floor(sqrt(Double(xp) / 100.0)) + 1))
    }

    func bootstrapCatalogIfNeeded() {
        achievementCatalog.forEach { _ = createIfNeeded(definition: $0) }
    }

    func onEntryAdded(user: User, at date: Date) {
        // Placeholder for real-time reactions (animations, haptics, etc.)
        _ = stats.countForDay(user: user, date: date, type: user.product.entryType)
    }

    func nightlyRecalc(user: User, date: Date) {
        let type = user.product.entryType
        let count = stats.countForDay(user: user, date: date, type: type)
        let limit = Int(user.dailyLimit)

        var xpGain: Int64 = 0
        var coinsGain: Int64 = 0

        if count <= limit {
            xpGain += 30
            coinsGain += 5
            incrementStreak(for: user)
        } else {
            resetStreak(for: user)
            let delta = max(0, count - limit)
            xpGain += max(5, Int64(15 - delta))
        }

        user.xp += xpGain
        user.coins += coinsGain

        updateAchievements(for: user, date: date)
        context.saveIfNeeded()
    }

    private func incrementStreak(for user: User) {
        let streak = ensureStreak(for: user)
        streak.currentLength += 1
        streak.bestLength = max(streak.bestLength, streak.currentLength)
        streak.updatedAt = Date()
    }

    private func resetStreak(for user: User) {
        let streak = ensureStreak(for: user)
        streak.currentLength = 0
        streak.updatedAt = Date()
    }

    private func ensureStreak(for user: User) -> Streak {
        if let streak = user.streak {
            return streak
        }
        let streak = Streak(context: context)
        streak.id = UUID()
        streak.currentLength = 0
        streak.bestLength = 0
        streak.updatedAt = Date()
        streak.user = user
        return streak
    }

    private func updateAchievements(for user: User, date: Date) {
        achievementCatalog.forEach { definition in
            let achievement = createIfNeeded(definition: definition)
            let userAchievement = achievementRepository.fetchUserAchievement(user: user, achievement: achievement)
                ?? achievementRepository.createUserAchievement(user: user, achievement: achievement)

            let newProgress: Int64
            switch definition.kind {
            case .streak:
                newProgress = Int64(user.streak?.bestLength ?? 0)
            case .daysWithinLimit:
                newProgress = progressForDaysWithinLimit(user: user)
            case .totalSaved:
                newProgress = estimatedMoneySaved(user: user)
            }

            userAchievement.progress = max(userAchievement.progress, newProgress)
            if userAchievement.achievedAt == nil && userAchievement.progress >= achievement.threshold {
                userAchievement.achievedAt = date
                user.coins += 20
                user.xp += 100
            }
        }
    }

    private func createIfNeeded(definition: AchievementDefinition) -> Achievement {
        if let existing = achievementRepository.fetchAchievement(code: definition.code) {
            return existing
        }
        return achievementRepository.createAchievement(code: definition.code,
                                                       title: NSLocalizedString(definition.title, comment: "achievement title"),
                                                       description: NSLocalizedString(definition.description, comment: "achievement description"),
                                                       icon: definition.icon,
                                                       threshold: definition.threshold,
                                                       kind: definition.kind)
    }

    private func progressForDaysWithinLimit(user: User) -> Int64 {
        let type = user.product.entryType
        let streak = ensureStreak(for: user)
        let withinLimitDays = streak.currentLength
        let totals = stats.totalsForLastDays(user: user, days: 30, type: type)
        let goodDays = totals.filter { $0.value <= Int(user.dailyLimit) }.count
        return max(Int64(withinLimitDays), Int64(goodDays))
    }

    func financialOverview(for user: User, days: Int = 30) -> FinancialOverview {
        let periodDays = max(1, days)
        let entryType = user.product.entryType
        let totals = stats.totalsForLastDays(user: user, days: periodDays, type: entryType)
        let totalUnits = totals.values.reduce(0, +)
        let samples = max(1, totals.count)
        let averagePerDay = Double(totalUnits) / Double(samples)

        let unitCost = inferredCostPerUnit(for: user, entryType: entryType)
        let periodMultiplier = Double(periodDays)

        let actualMonthly = max(0, averagePerDay * unitCost * periodMultiplier)
        let baselineMonthly = max(0, Double(user.dailyLimit) * unitCost * periodMultiplier)
        let savings = max(0, baselineMonthly - actualMonthly)

        let currencyCode = user.currencyCode ?? Locale.current.currencyCode ?? "USD"

        return FinancialOverview(currencyCode: currencyCode,
                                 monthlySpend: actualMonthly,
                                 monthlySavings: savings,
                                 baselineMonthlyBudget: baselineMonthly)
    }

    func estimatedMoneySaved(user: User) -> Int64 {
        let overview = financialOverview(for: user)
        return Int64(overview.monthlySavings)
    }

    private func inferredCostPerUnit(for user: User, entryType: EntryType) -> Double {
        if user.packSize > 0, user.packCost > 0 {
            return user.packCost / Double(user.packSize)
        }

        switch entryType {
        case .cig:
            return 15.0
        case .puff:
            return 8.0
        }
    }

    private struct AchievementDefinition {
        let code: String
        let title: String
        let description: String
        let icon: String
        let threshold: Int64
        let kind: AchievementKind
    }

    private let achievementCatalog: [AchievementDefinition] = [
        AchievementDefinition(code: "first_day",
                              title: "First Step",
                              description: "Track at least one day to begin your journey.",
                              icon: "flame",
                              threshold: 1,
                              kind: .daysWithinLimit),
        AchievementDefinition(code: "week_control",
                              title: "Control x7",
                              description: "Stay within your limit for 7 days in a row.",
                              icon: "calendar",
                              threshold: 7,
                              kind: .streak),
        AchievementDefinition(code: "savings_1000",
                              title: "Savings 1000",
                              description: "Save 1000 currency units compared to your baseline.",
                              icon: "banknote",
                              threshold: 1000,
                              kind: .totalSaved)
    ]
}

struct FinancialOverview {
    let currencyCode: String
    let monthlySpend: Double
    let monthlySavings: Double
    let baselineMonthlyBudget: Double
}

extension FinancialOverview {
    static var placeholder: FinancialOverview {
        FinancialOverview(currencyCode: Locale.current.currencyCode ?? "USD",
                          monthlySpend: 0,
                          monthlySavings: 0,
                          baselineMonthlyBudget: 0)
    }
}
