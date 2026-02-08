import CoreData

protocol StatsRepository {
    func fetchDailyStat(user: User, date: Date, type: EntryType) -> DailyStat?
    func fetchDailyStats(user: User, start: Date, end: Date, type: EntryType?) -> [DailyStat]
    func createDailyStat(user: User, date: Date, type: EntryType) -> DailyStat
    func deleteDailyStat(_ stat: DailyStat)
}

final class CoreDataStatsRepository: StatsRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchDailyStat(user: User, date: Date, type: EntryType) -> DailyStat? {
        let request: NSFetchRequest<DailyStat> = DailyStat.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "user == %@ AND date == %@ AND type == %d",
                                        user, date as NSDate, type.rawValue)
        return try? context.fetch(request).first
    }

    func fetchDailyStats(user: User, start: Date, end: Date, type: EntryType?) -> [DailyStat] {
        let request: NSFetchRequest<DailyStat> = DailyStat.fetchRequest()
        var predicates: [NSPredicate] = [NSPredicate(format: "user == %@", user),
                                         NSPredicate(format: "date >= %@", start as NSDate),
                                         NSPredicate(format: "date <= %@", end as NSDate)]
        if let type {
            predicates.append(NSPredicate(format: "type == %d", type.rawValue))
        }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return (try? context.fetch(request)) ?? []
    }

    func createDailyStat(user: User, date: Date, type: EntryType) -> DailyStat {
        let stat = DailyStat(context: context)
        stat.id = UUID()
        stat.date = date
        stat.count = 0
        stat.type = type.rawValue
        stat.user = user
        return stat
    }

    func deleteDailyStat(_ stat: DailyStat) {
        context.delete(stat)
    }
}
