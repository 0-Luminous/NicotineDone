import Foundation
import CoreData

struct AchievementState {
    var bestAbstinenceInterval: TimeInterval = 0
    var cleanMorningCount: Int = 0
    var cleanEveningCount: Int = 0
    var bestEntryStreak: Int = 0
    var withinLimitBestStreak: Int = 0
}

struct AchievementStateBuilder {
    let entryRepository: EntryRepository
    let user: User
    let calendar: Calendar
    let dateProvider: () -> Date

    func build() -> AchievementState {
        var state = AchievementState()
        state.withinLimitBestStreak = Int(user.streak?.bestLength ?? 0)

        let entryType = user.product.entryType
        let entries = entryRepository.fetchEntries(user: user, type: entryType, start: nil, end: nil)
        let dates = entries.compactMap(\.createdAt)

        state.bestAbstinenceInterval = bestAbstinenceInterval(from: dates)

        let dayBuckets = bucketByDay(dates)
        state.cleanMorningCount = countCleanMornings(from: dayBuckets)
        state.cleanEveningCount = countCleanEvenings(from: dayBuckets)
        state.bestEntryStreak = bestEntryStreak(from: dayBuckets)

        return state
    }

    private func bestAbstinenceInterval(from dates: [Date]) -> TimeInterval {
        guard !dates.isEmpty else { return 0 }
        var best: TimeInterval = 0
        var last: Date?
        for date in dates {
            if let last {
                best = max(best, date.timeIntervalSince(last))
            }
            last = date
        }
        if let last {
            best = max(best, dateProvider().timeIntervalSince(last))
        }
        return max(best, 0)
    }

    private func bucketByDay(_ dates: [Date]) -> [Date: [Date]] {
        var map: [Date: [Date]] = [:]
        for date in dates {
            let day = calendar.startOfDay(for: date)
            map[day, default: []].append(date)
        }
        return map
    }

    private func countCleanMornings(from buckets: [Date: [Date]]) -> Int {
        buckets.values.reduce(0) { total, dates in
            let earliestHour = dates.map { calendar.component(.hour, from: $0) }.min() ?? 24
            return total + (earliestHour >= 12 ? 1 : 0)
        }
    }

    private func countCleanEvenings(from buckets: [Date: [Date]]) -> Int {
        buckets.values.reduce(0) { total, dates in
            let latestHour = dates.map { calendar.component(.hour, from: $0) }.max() ?? -1
            return total + (latestHour < 20 ? 1 : 0)
        }
    }

    private func bestEntryStreak(from buckets: [Date: [Date]]) -> Int {
        let sortedDays = buckets.keys.sorted()
        guard !sortedDays.isEmpty else { return 0 }
        var best = 1
        var current = 1
        var previous = sortedDays[0]
        for day in sortedDays.dropFirst() {
            let expected = calendar.date(byAdding: .day, value: 1, to: previous) ?? day
            if calendar.isDate(day, inSameDayAs: expected) {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            previous = day
        }
        return best
    }
}
