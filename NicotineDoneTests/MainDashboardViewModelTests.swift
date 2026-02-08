import XCTest
@testable import NicotineDone

final class MainDashboardViewModelTests: XCTestCase {
    @MainActor
    func testNextSuggestedDateComputedFromDailyLimit() {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext

        let user = User(context: context)
        user.id = UUID()
        user.createdAt = Date()
        user.productType = ProductType.cigarette.rawValue
        user.dailyLimit = 12
        user.packSize = 20
        user.packCost = 10
        user.currencyCode = "USD"
        user.coins = 0
        user.xp = 0
        context.saveIfNeeded()

        let environment = AppEnvironment.live(context: context)
        let tracker = environment.trackingService

        let entryDate = Date(timeIntervalSince1970: 1_700_000_000)
        tracker.addEntry(for: user, type: .cig, date: entryDate)

        let viewModel = MainDashboardViewModel(user: user, environment: environment)
        viewModel.refreshToday(reference: entryDate)

        let next = viewModel.nextSuggestedDate
        let expectedInterval = 24.0 * 60.0 * 60.0 / Double(user.dailyLimit)
        XCTAssertNotNil(next)
        XCTAssertEqual(next?.timeIntervalSince(entryDate), expectedInterval, accuracy: 0.5)
    }
}
