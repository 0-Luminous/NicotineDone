import CoreData

protocol EntryRepository {
    @discardableResult
    func addEntry(user: User, type: EntryType, cost: Double?, date: Date) -> Entry
    func fetchLatestEntry(user: User, type: EntryType, start: Date, end: Date) -> Entry?
    func fetchEntries(user: User, type: EntryType, start: Date?, end: Date?) -> [Entry]
    func deleteEntry(_ entry: Entry)
}

final class CoreDataEntryRepository: EntryRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    @discardableResult
    func addEntry(user: User, type: EntryType, cost: Double?, date: Date) -> Entry {
        let entry = Entry(context: context)
        entry.id = UUID()
        entry.createdAt = date
        entry.type = type.rawValue
        entry.cost = cost ?? 0
        entry.user = user
        return entry
    }

    func fetchLatestEntry(user: User, type: EntryType, start: Date, end: Date) -> Entry? {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)]
        request.predicate = NSPredicate(format: "user == %@ AND type == %d AND createdAt >= %@ AND createdAt < %@",
                                        user, type.rawValue, start as NSDate, end as NSDate)
        return try? context.fetch(request).first
    }

    func fetchEntries(user: User, type: EntryType, start: Date?, end: Date?) -> [Entry] {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        var predicates: [NSPredicate] = [NSPredicate(format: "user == %@ AND type == %d", user, type.rawValue)]
        if let start {
            predicates.append(NSPredicate(format: "createdAt >= %@", start as NSDate))
        }
        if let end {
            predicates.append(NSPredicate(format: "createdAt < %@", end as NSDate))
        }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return (try? context.fetch(request)) ?? []
    }

    func deleteEntry(_ entry: Entry) {
        context.delete(entry)
    }
}
