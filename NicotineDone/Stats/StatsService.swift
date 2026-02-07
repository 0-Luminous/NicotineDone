import CoreData

final class StatsService {
    private let context: NSManagedObjectContext
    private let calendar: Calendar

    init(context: NSManagedObjectContext, calendar: Calendar = .current) {
        self.context = context
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
        let stat = fetchDailyStat(user: user, date: sod, type: type) ?? {
            let stat = DailyStat(context: context)
            stat.id = UUID()
            stat.date = sod
            stat.count = 0
            stat.type = type.rawValue
            stat.user = user
            return stat
        }()
        stat.count += 1
    }

    func decrementDailyCount(for user: User, at date: Date, type: EntryType) {
        let sod = startOfDay(for: date)
        guard let stat = fetchDailyStat(user: user, date: sod, type: type) else { return }
        stat.count = max(stat.count - 1, Int32(0))
        if stat.count == 0 {
            context.delete(stat)
        }
    }

    func countForDay(user: User, date: Date, type: EntryType) -> Int {
        let sod = startOfDay(for: date)
        let req: NSFetchRequest<DailyStat> = DailyStat.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "user == %@ AND date == %@ AND type == %d", user, sod as NSDate, type.rawValue)
        return Int((try? context.fetch(req).first?.count) ?? 0)
    }

    func countForDayAllTypes(user: User, date: Date) -> Int {
        let sod = startOfDay(for: date)
        let req: NSFetchRequest<DailyStat> = DailyStat.fetchRequest()
        req.predicate = NSPredicate(format: "user == %@ AND date == %@", user, sod as NSDate)
        let stats = (try? context.fetch(req)) ?? []
        return stats.reduce(0) { $0 + Int($1.count) }
    }

    func totalsForLastDays(user: User, days: Int, type: EntryType) -> [Date: Int] {
        guard days > 0 else { return [:] }
        let end = startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -days + 1, to: end)!

        let req: NSFetchRequest<DailyStat> = DailyStat.fetchRequest()
        req.predicate = NSPredicate(format: "user == %@ AND date >= %@ AND date <= %@ AND type == %d",
                                    user, start as NSDate, end as NSDate, type.rawValue)

        let stats = (try? context.fetch(req)) ?? []
        var map: [Date: Int] = [:]
        stats.forEach { map[$0.date ?? Date()] = Int($0.count) }
        return map
    }

    func totalsForHoursInDay(user: User, date: Date, type: EntryType) -> [Date: Int] {
        let start = startOfDay(for: date)
        let end = endOfDay(for: date)

        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND type == %d AND createdAt >= %@ AND createdAt < %@",
                                        user, type.rawValue, start as NSDate, end as NSDate)

        let entries = (try? context.fetch(request)) ?? []
        var map: [Date: Int] = [:]
        for entry in entries {
            guard let createdAt = entry.createdAt else { continue }
            let hour = calendar.component(.hour, from: createdAt)
            guard let hourDate = calendar.date(byAdding: .hour, value: hour, to: start) else { continue }
            map[hourDate, default: 0] += 1
        }
        return map
    }

    private func fetchDailyStat(user: User, date: Date, type: EntryType) -> DailyStat? {
        let req: NSFetchRequest<DailyStat> = DailyStat.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "user == %@ AND date == %@ AND type == %d", user, date as NSDate, type.rawValue)
        return try? context.fetch(req).first
    }
}
