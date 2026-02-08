import XCTest
@testable import NicotineDone

final class StatsViewModelTests: XCTestCase {
    @MainActor
    func testTrendRangesIncludeWeekWithRecentData() {
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

        let environment = AppEnvironment.live(context: context)
        let tracker = environment.trackingService
        let calendar = Calendar.current
        let base = Date()

        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: base) {
                tracker.addEntry(for: user, type: .cig, date: date)
            }
        }

        let viewModel = StatsViewModel(user: user, environment: environment)
        viewModel.refresh()

        XCTAssertTrue(viewModel.availableTrendRanges.contains(.week))
    }
}
