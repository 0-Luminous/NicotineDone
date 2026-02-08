import XCTest
@testable import NicotineDone

final class AchievementsViewModelTests: XCTestCase {
    @MainActor
    func testAchievementStateCountsMorningEveningAndStreak() {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext

        let user = User(context: context)
        user.id = UUID()
        user.createdAt = Date()
        user.productType = ProductType.cigarette.rawValue
        user.dailyLimit = 10
        user.packSize = 20
        user.packCost = 10
        user.currencyCode = "USD"
        user.coins = 0
        user.xp = 0
        context.saveIfNeeded()

        let entryRepository = CoreDataEntryRepository(context: context)
        let calendar = Calendar.current
        let baseDay = Date(timeIntervalSince1970: 1_700_200_000)

        let day1 = calendar.startOfDay(for: baseDay)
        let day1Morning = calendar.date(byAdding: .hour, value: 13, to: day1)!
        let day1Evening = calendar.date(byAdding: .hour, value: 19, to: day1)!
        _ = entryRepository.addEntry(user: user, type: .cig, cost: 1, date: day1Morning)
        _ = entryRepository.addEntry(user: user, type: .cig, cost: 1, date: day1Evening)

        let day2 = calendar.date(byAdding: .day, value: 1, to: day1)!
        let day2Early = calendar.date(byAdding: .hour, value: 10, to: day2)!
        let day2Late = calendar.date(byAdding: .hour, value: 21, to: day2)!
        _ = entryRepository.addEntry(user: user, type: .cig, cost: 1, date: day2Early)
        _ = entryRepository.addEntry(user: user, type: .cig, cost: 1, date: day2Late)
        context.saveIfNeeded()

        let builder = AchievementStateBuilder(entryRepository: entryRepository,
                                              user: user,
                                              calendar: calendar,
                                              dateProvider: { day2Late })
        let state = builder.build()

        XCTAssertEqual(state.cleanMorningCount, 1)
        XCTAssertEqual(state.cleanEveningCount, 1)
        XCTAssertEqual(state.bestEntryStreak, 2)
    }
}
