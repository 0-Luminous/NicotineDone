import XCTest
@testable import NicotineDone

final class GamificationServiceTests: XCTestCase {
    @MainActor
    func testNightlyRecalcRewardsWithinLimit() {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext

        let user = User(context: context)
        user.id = UUID()
        user.createdAt = Date()
        user.productType = ProductType.cigarette.rawValue
        user.dailyLimit = 5
        user.packSize = 20
        user.packCost = 10
        user.currencyCode = "USD"
        user.coins = 0
        user.xp = 0
        context.saveIfNeeded()

        let environment = AppEnvironment.live(context: context)
        let tracker = environment.trackingService
        let gamification = environment.gamificationService

        let date = Date(timeIntervalSince1970: 1_700_100_000)
        for _ in 0..<3 {
            tracker.addEntry(for: user, type: .cig, date: date)
        }

        gamification.nightlyRecalc(user: user, date: date)

        XCTAssertGreaterThanOrEqual(user.xp, 30)
        XCTAssertGreaterThanOrEqual(user.coins, 5)
    }
}
