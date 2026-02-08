import Foundation
import CoreData
import Combine

@MainActor
final class MainDashboardViewModel: ObservableObject {
    @Published var todayCount: Int = 0
    @Published var nextSuggestedDate: Date?
    @Published var now: Date = Date()
    @Published var weekEntryCounts: [Date: Int] = [:]
    @Published var lastEntryDate: Date?
    @Published var bestAbstinenceInterval: TimeInterval = 0
    @Published var currentMethod: NicotineMethod?

    let user: User

    private let calendar: Calendar
    private let dateProvider: () -> Date
    private let statsService: StatsService
    private let trackingService: TrackingService
    private let entryRepository: EntryRepository
    private let settingsStore: SettingsStore

    init(user: User, environment: AppEnvironment) {
        self.user = user
        self.calendar = environment.calendar
        self.dateProvider = environment.dateProvider
        self.statsService = environment.statsService
        self.trackingService = environment.trackingService
        self.entryRepository = environment.entryRepository
        self.settingsStore = environment.settingsStore
    }

    var entryType: EntryType { user.product.entryType }
    var dailyLimit: Int { max(Int(user.dailyLimit), 0) }

    var remainingCount: Int {
        max(dailyLimit - todayCount, 0)
    }

    var canConsumeNow: Bool {
        guard dailyLimit > 0 else { return true }
        if remainingCount == 0 { return false }
        guard let nextSuggestedDate else { return true }
        return nextSuggestedDate <= now
    }

    var nextEntryProgress: Double {
        if canConsumeNow { return 1 }
        guard dailyLimit > 0 else { return 1 }
        guard let lastEntryDate, let nextSuggestedDate else { return 0 }
        let interval = max(24 * 60 * 60 / Double(max(dailyLimit, 1)), 1)
        let elapsed = max(now.timeIntervalSince(lastEntryDate), 0)
        if nextSuggestedDate <= now { return 1 }
        return min(max(elapsed / interval, 0), 1)
    }

    var shouldShowStreak: Bool {
        canConsumeNow && (currentAbstinenceInterval ?? 0) >= 3600
    }

    var abstinenceHours: Int {
        Int(floor((currentAbstinenceInterval ?? 0) / 3600))
    }

    var streakMilestones: [Int] {
        [6, 9, 12, 15, 18, 24, 30, 36, 42, 48, 60, 72, 84, 96, 108, 180, 192, 200]
    }

    var streakHoursTarget: Int {
        let hours = max(abstinenceHours, 1)
        return streakMilestones.first(where: { $0 >= hours }) ?? (streakMilestones.last ?? 6)
    }

    var maxStreakCircles: Int {
        12
    }

    var streakUnitHours: Int {
        let candidates = [1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 20, 25, 30]
        let target = max(streakHoursTarget, 1)
        return candidates.first(where: { Int(ceil(Double(target) / Double($0))) <= maxStreakCircles }) ?? 30
    }

    var streakDisplayTarget: Int {
        let target = max(streakHoursTarget, 1)
        let unit = max(streakUnitHours, 1)
        return Int(ceil(Double(target) / Double(unit))) * unit
    }

    var streakHoursFilled: Int {
        min(max(abstinenceHours, 0), streakDisplayTarget)
    }

    var streakCircleCount: Int {
        Int(ceil(Double(streakDisplayTarget) / Double(streakUnitHours)))
    }

    var streakCirclesFilled: Int {
        let filled = max(streakHoursFilled, 0)
        let fullUnits = filled / streakUnitHours
        let hasPartial = filled % streakUnitHours != 0
        return min(fullUnits + (hasPartial ? 1 : 0), streakCircleCount)
    }

    var streakFullUnits: Int {
        let filled = max(streakHoursFilled, 0)
        return max(min(filled / max(streakUnitHours, 1), streakCircleCount), 0)
    }

    var streakPartialProgress: Double {
        let unit = max(streakUnitHours, 1)
        let partial = max(streakHoursFilled, 0) % unit
        return Double(partial) / Double(unit)
    }

    var streakStatusText: String {
        String.localizedStringWithFormat(
            NSLocalizedString("Streak %1$d/%2$d hours", comment: "Streak status label"),
            streakHoursFilled,
            streakDisplayTarget
        )
    }

    var streakAccessibilityLabel: String {
        String.localizedStringWithFormat(
            NSLocalizedString("Streak progress %1$d of %2$d hours", comment: "Streak accessibility label"),
            streakHoursFilled,
            streakDisplayTarget
        )
    }

    var entryTypeLabel: String {
        switch entryType {
        case .cig:
            return NSLocalizedString("onboarding_method_cigarettes", comment: "cigarettes label").uppercased()
        case .puff:
            return NSLocalizedString("onboarding_method_refillable_vape", comment: "vape label").uppercased()
        case .disposableVape:
            return NSLocalizedString("onboarding_method_disposable_vape", comment: "vape label").uppercased()
        case .heatedTobacco:
            return NSLocalizedString("onboarding_method_heated_tobacco", comment: "heated tobacco label").uppercased()
        case .snusOrPouches:
            return NSLocalizedString("onboarding_method_snus_or_pouches", comment: "snus label").uppercased()
        case .hookah:
            return NSLocalizedString("onboarding_method_hookah", comment: "hookah label").uppercased()
        }
    }

    var nicotineMethodLabel: String {
        guard let method = currentMethod else { return entryTypeLabel }
        if method == .disposableVape || method == .refillableVape {
            return "осталось затяжек".uppercased()
        }
        let key: String
        switch method {
        case .cigarettes:
            key = "onboarding_method_cigarettes"
        case .hookah:
            key = "onboarding_method_hookah"
        case .heatedTobacco:
            key = "onboarding_method_heated_tobacco"
        case .snusOrPouches:
            key = "onboarding_method_snus_or_pouches"
        case .disposableVape:
            key = "onboarding_method_disposable_vape"
        case .refillableVape:
            key = "onboarding_method_refillable_vape"
        }
        return NSLocalizedString(key, comment: "nicotine method label").uppercased()
    }

    var weekDays: [WeekDay] {
        let today = calendar.startOfDay(for: now)

        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }

        return (0..<7).compactMap { offset -> WeekDay? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let number = calendar.component(.day, from: date)
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let label = MainDashboardView.weekdayFormatter.string(from: date)
            let key = calendar.startOfDay(for: date)
            let count = weekEntryCounts[key] ?? 0
            return WeekDay(date: date,
                           displayNumber: "\(number)",
                           displayLabel: isToday ? NSLocalizedString("Today", comment: "today label") : label,
                           isToday: isToday,
                           count: count,
                           limit: dailyLimit)
        }
    }

    var hasLoggedEntries: Bool {
        lastEntryDate != nil || bestAbstinenceInterval > 0
    }

    var bestRecordIsActive: Bool {
        bestAbstinenceInterval > 0 || (currentAbstinenceInterval ?? 0) > 0
    }

    var currentAbstinenceInterval: TimeInterval? {
        guard let lastEntryDate else { return nil }
        return max(now.timeIntervalSince(lastEntryDate), 0)
    }

    var abstinenceTimerValue: String {
        guard let interval = currentAbstinenceInterval else {
            return "--"
        }
        return formattedDuration(interval)
    }

    var abstinenceRecordValue: String {
        let record = max(bestAbstinenceInterval, currentAbstinenceInterval ?? 0)
        guard record > 0 else {
            return NSLocalizedString("No record yet", comment: "record placeholder")
        }
        return formattedDuration(record)
    }

    func onAppear() {
        now = dateProvider()
        refreshToday(reference: now)
        refreshCurrentMethod()
    }

    func updateNow(_ time: Date) {
        let previousDay = calendar.startOfDay(for: now)
        let currentDay = calendar.startOfDay(for: time)
        now = time
        if currentDay != previousDay {
            refreshToday(reference: time)
        }
    }

    func refreshCurrentMethod() {
        currentMethod = settingsStore.loadProfile()?.method
    }

    @discardableResult
    func logEntry() -> Bool {
        trackingService.addEntry(for: user, type: entryType)
        refreshToday(reference: dateProvider())
        return true
    }

    @discardableResult
    func removeEntry() -> Bool {
        let removed = trackingService.removeLatestEntry(for: user, type: entryType, referenceDate: dateProvider())
        if removed {
            refreshToday(reference: dateProvider())
        }
        return removed
    }

    func refreshToday(reference: Date) {
        todayCount = statsService.countForDay(user: user, date: reference, type: entryType)
        weekEntryCounts = fetchWeekCounts(anchor: reference)
        let abstinenceStats = fetchAbstinenceStats(reference: reference)
        lastEntryDate = abstinenceStats.lastEntry
        bestAbstinenceInterval = abstinenceStats.longestInterval
        nextSuggestedDate = calculateNextSuggestedDate(lastEntryDate: abstinenceStats.lastEntry)
    }

    func calculateNextSuggestedDate(lastEntryDate: Date?) -> Date? {
        guard dailyLimit > 0 else { return nil }
        guard let lastEntryDate else { return nil }
        let interval = 24 * 60 * 60 / Double(max(dailyLimit, 1))
        return lastEntryDate.addingTimeInterval(interval)
    }

    func fetchWeekCounts(anchor: Date) -> [Date: Int] {
        let dayAnchor = calendar.startOfDay(for: anchor)
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: dayAnchor)) else {
            return [:]
        }

        var result: [Date: Int] = [:]
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { continue }
            let count = statsService.countForDay(user: user, date: date, type: entryType)
            result[calendar.startOfDay(for: date)] = count
        }
        return result
    }

    func fetchAbstinenceStats(reference: Date) -> AbstinenceStats {
        let entries = entryRepository.fetchEntries(user: user, type: entryType, start: nil, end: nil)
        let dates = entries.compactMap { $0.createdAt }.sorted()
        guard !dates.isEmpty else {
            return AbstinenceStats(lastEntry: nil, longestInterval: 0)
        }

        var longest: TimeInterval = 0
        var previousDate = dates.first

        for date in dates.dropFirst() {
            if let previousDate {
                let gap = max(date.timeIntervalSince(previousDate), 0)
                longest = max(longest, gap)
            }
            previousDate = date
        }

        if let last = dates.last {
            let gap = max(reference.timeIntervalSince(last), 0)
            longest = max(longest, gap)
        }

        return AbstinenceStats(lastEntry: dates.last, longestInterval: max(longest, 0))
    }

    func formattedDuration(_ interval: TimeInterval) -> String {
        let safeInterval = max(interval, 1)
        if safeInterval < 60 {
            return NSLocalizedString("<1m", comment: "duration shorter than a minute")
        }
        return MainDashboardView.abstinenceFormatter.string(from: safeInterval) ?? "--"
    }
}

struct WeekDay: Identifiable {
    let date: Date
    let displayNumber: String
    let displayLabel: String
    let isToday: Bool
    let count: Int
    let limit: Int

    var id: Date { date }

    var progress: Double {
        guard limit > 0 else { return 0 }
        return Double(count) / Double(limit)
    }
}

struct AbstinenceStats {
    let lastEntry: Date?
    let longestInterval: TimeInterval
}
