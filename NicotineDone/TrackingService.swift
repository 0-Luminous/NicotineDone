import CoreData

final class TrackingService {
    private let context: NSManagedObjectContext
    private let entryRepository: EntryRepository
    private let statsService: StatsService
    private let gamification: GamificationService

    init(context: NSManagedObjectContext,
         entryRepository: EntryRepository,
         statsService: StatsService,
         gamification: GamificationService) {
        self.context = context
        self.entryRepository = entryRepository
        self.statsService = statsService
        self.gamification = gamification
    }

    func addEntry(for user: User, type: EntryType, cost: Double? = nil, date: Date = Date()) {
        let resolved = resolvedCost(for: user, explicitCost: cost, type: type)
        _ = entryRepository.addEntry(user: user, type: type, cost: resolved, date: date)

        statsService.bumpDailyCount(for: user, at: date, type: type)
        gamification.onEntryAdded(user: user, at: date)
        context.saveIfNeeded()
    }

    @discardableResult
    func removeLatestEntry(for user: User, type: EntryType, referenceDate: Date = Date()) -> Bool {
        let startOfDay = statsService.startOfDay(for: referenceDate)
        let endOfDay = statsService.endOfDay(for: referenceDate)

        guard let entry = entryRepository.fetchLatestEntry(user: user,
                                                           type: type,
                                                           start: startOfDay,
                                                           end: endOfDay) else { return false }

        let removalDate = entry.createdAt ?? referenceDate
        entryRepository.deleteEntry(entry)
        statsService.decrementDailyCount(for: user, at: removalDate, type: type)
        context.saveIfNeeded()
        return true
    }

    private func resolvedCost(for user: User, explicitCost: Double?, type: EntryType) -> Double {
        if let explicitCost {
            return explicitCost
        }

        let packSize = max(Int(user.packSize), 0)
        let packCost = user.packCost
        guard packSize > 0, packCost > 0 else {
            return 0
        }
        return packCost / Double(packSize)
    }
}
