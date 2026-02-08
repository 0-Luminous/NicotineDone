import CoreData

final class StatsService {
    private let statsRepository: StatsRepository
    private let entryRepository: EntryRepository
    private let calendar: Calendar

    init(statsRepository: StatsRepository,
         entryRepository: EntryRepository,
         calendar: Calendar = .current) {
        self.statsRepository = statsRepository
        self.entryRepository = entryRepository
        self.calendar = calendar
    }

    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    func endOfDay(for date: Date) -> Date {
        calendar.date(byAdding: .day, value: 1, to: startOfDay(for: date))!
    }

    func bumpDailyCount(for user: User, at date: Date, type: EntryType) {
        let sod = startOfDay(for: date)
        let stat = statsRepository.fetchDailyStat(user: user, date: sod, type: type)
            ?? statsRepository.createDailyStat(user: user, date: sod, type: type)
        stat.count += 1
    }

    func decrementDailyCount(for user: User, at date: Date, type: EntryType) {
        let sod = startOfDay(for: date)
        guard let stat = statsRepository.fetchDailyStat(user: user, date: sod, type: type) else { return }
        stat.count = max(stat.count - 1, Int32(0))
        if stat.count == 0 {
            statsRepository.deleteDailyStat(stat)
        }
    }

    func countForDay(user: User, date: Date, type: EntryType) -> Int {
        let sod = startOfDay(for: date)
        return Int(statsRepository.fetchDailyStat(user: user, date: sod, type: type)?.count ?? 0)
    }

    func countForDayAllTypes(user: User, date: Date) -> Int {
        let sod = startOfDay(for: date)
        let stats = statsRepository.fetchDailyStats(user: user, start: sod, end: sod, type: nil)
        return stats.reduce(0) { $0 + Int($1.count) }
    }

    func totalsForLastDays(user: User, days: Int, type: EntryType) -> [Date: Int] {
        guard days > 0 else { return [:] }
        let end = startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -days + 1, to: end)!

        let stats = statsRepository.fetchDailyStats(user: user, start: start, end: end, type: type)
        var map: [Date: Int] = [:]
        stats.forEach { map[$0.date ?? Date()] = Int($0.count) }
        return map
    }

    func totalsForHoursInDay(user: User, date: Date, type: EntryType) -> [Date: Int] {
        let start = startOfDay(for: date)
        let end = endOfDay(for: date)

        let entries = entryRepository.fetchEntries(user: user, type: type, start: start, end: end)
        var map: [Date: Int] = [:]
        for entry in entries {
            guard let createdAt = entry.createdAt else { continue }
            let hour = calendar.component(.hour, from: createdAt)
            guard let hourDate = calendar.date(byAdding: .hour, value: hour, to: start) else { continue }
            map[hourDate, default: 0] += 1
        }
        return map
    }
}
