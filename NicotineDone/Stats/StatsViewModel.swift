import Foundation
import CoreData
import Combine

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var trendData: [TrendRange: [DailyPoint]] = [:]
    @Published var selectedTrendRange: TrendRange = .today
    @Published var availableTrendRanges: [TrendRange] = [.today]
    @Published var average: Double = 0
    @Published var financialOverviewByRange: [TrendRange: FinancialOverview] = [:]

    let user: User

    private let statsService: StatsService
    private let gamificationService: GamificationService
    private let calendar: Calendar
    private let dateProvider: () -> Date

    init(user: User, environment: AppEnvironment) {
        self.user = user
        self.statsService = environment.statsService
        self.gamificationService = environment.gamificationService
        self.calendar = environment.calendar
        self.dateProvider = environment.dateProvider
    }

    var currentTrendData: [DailyPoint] {
        trendData[selectedTrendRange] ?? []
    }

    var currentFinancialOverview: FinancialOverview {
        financialOverviewByRange[selectedTrendRange]
            ?? financialOverviewByRange[.today]
            ?? .placeholder
    }

    func refresh() {
        let entryType = user.product.entryType
        let anchor = dateProvider()
        let todayCount = statsService.countForDay(user: user, date: anchor, type: entryType)
        let todayHourlyTotals = statsService.totalsForHoursInDay(user: user, date: anchor, type: entryType)
        let weekTotals = statsService.totalsForLastDays(user: user, days: 7, type: entryType)
        let monthTotals = statsService.totalsForLastDays(user: user, days: 30, type: entryType)
        let yearTotals = statsService.totalsForLastDays(user: user, days: 365, type: entryType)

        let todayPoints = pointsForHoursInDay(totals: todayHourlyTotals, anchor: anchor, fallbackCount: todayCount)
        var nextTrendData: [TrendRange: [DailyPoint]] = [:]
        var nextAvailableRanges: [TrendRange] = []

        if !todayPoints.isEmpty {
            nextTrendData[.today] = todayPoints
            nextAvailableRanges.append(.today)
        }

        if !weekTotals.isEmpty {
            nextTrendData[.week] = pointsForLastDays(days: 7, totals: weekTotals, anchor: anchor)
            nextAvailableRanges.append(.week)
        }

        if !monthTotals.isEmpty {
            nextTrendData[.month] = pointsForLastDays(days: 30, totals: monthTotals, anchor: anchor)
            nextAvailableRanges.append(.month)
        }

        if !yearTotals.isEmpty {
            nextTrendData[.year] = pointsForLastDays(days: 365, totals: yearTotals, anchor: anchor)
            nextAvailableRanges.append(.year)
        }

        trendData = nextTrendData
        availableTrendRanges = nextAvailableRanges

        if !availableTrendRanges.contains(selectedTrendRange) {
            if todayPoints.isEmpty, availableTrendRanges.contains(.week) {
                selectedTrendRange = .week
            } else {
                selectedTrendRange = availableTrendRanges.first ?? .today
            }
        }

        if let weekData = trendData[.week], !weekData.isEmpty {
            average = Double(weekData.map(\.count).reduce(0, +)) / Double(weekData.count)
        } else {
            average = 0
        }

        var nextFinancialOverviewByRange: [TrendRange: FinancialOverview] = [:]
        for range in TrendRange.allCases {
            nextFinancialOverviewByRange[range] = gamificationService.financialOverview(for: user, days: range.lookbackDays)
        }
        financialOverviewByRange = nextFinancialOverviewByRange
    }

    private func pointsForLastDays(days: Int, totals: [Date: Int], anchor: Date) -> [DailyPoint] {
        guard days > 0 else { return [] }
        let end = calendar.startOfDay(for: anchor)
        guard let start = calendar.date(byAdding: .day, value: -days + 1, to: end) else { return [] }

        var normalizedTotals: [Date: Int] = [:]
        for (date, count) in totals {
            normalizedTotals[calendar.startOfDay(for: date)] = count
        }

        return (0..<days).compactMap { offset -> DailyPoint? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let normalized = calendar.startOfDay(for: day)
            let count = normalizedTotals[normalized] ?? 0
            return DailyPoint(date: normalized, count: count)
        }
    }

    private func pointsForHoursInDay(totals: [Date: Int], anchor: Date, fallbackCount: Int) -> [DailyPoint] {
        let dayStart = calendar.startOfDay(for: anchor)
        var results: [DailyPoint] = []

        if totals.isEmpty {
            guard fallbackCount > 0 else { return [] }
            let hour = calendar.component(.hour, from: anchor)
            if let hourDate = calendar.date(byAdding: .hour, value: hour, to: dayStart) {
                results.append(DailyPoint(date: hourDate, count: fallbackCount))
            }
            return results
        }

        for hour in 0..<24 {
            guard let hourDate = calendar.date(byAdding: .hour, value: hour, to: dayStart) else { continue }
            let count = totals[hourDate] ?? 0
            results.append(DailyPoint(date: hourDate, count: count))
        }
        return results
    }
}
