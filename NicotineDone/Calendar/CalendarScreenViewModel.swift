import Foundation
import CoreData
import Combine

final class CalendarScreenViewModel: ObservableObject {
    @Published var monthAnchor: Date
    @Published var selectedDay: DaySelection?
    @Published var isYearPickerPresented = false
    @Published var pendingYearSelection: Int

    let user: User

    init(user: User, now: Date = Date()) {
        self.user = user
        self.monthAnchor = Calendar.current.startOfMonth(for: now)
        self.pendingYearSelection = Calendar.current.component(.year, from: now)
    }

    var limit: Int {
        Int(user.dailyLimit)
    }

    var currentYear: Int {
        Calendar.current.component(.year, from: monthAnchor)
    }

    func gridDays() -> [Date?] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: monthAnchor) ?? 1..<32

        let monthDays: [Date] = range.compactMap { day -> Date? in
            var components = calendar.dateComponents([.year, .month], from: monthAnchor)
            components.day = day
            return calendar.date(from: components)
        }

        let firstOfMonth = calendar.startOfMonth(for: monthAnchor)
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leading = (weekday - calendar.firstWeekday + 7) % 7

        let total = leading + monthDays.count
        let rows = Int(ceil(Double(total) / 7.0))
        let target = rows * 7
        let trailing = max(0, target - total)

        return Array(repeating: nil, count: leading) + monthDays.map { Optional.some($0) } + Array(repeating: nil, count: trailing)
    }

    func yearTitle() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("y")
        return formatter.string(from: monthAnchor)
    }

    func monthsOfYear(context: NSManagedObjectContext) -> [Date] {
        monthsWithData(in: currentYear, context: context)
    }

    func yearsWithData(context: NSManagedObjectContext) -> [Int] {
        let request: NSFetchRequest<DailyStat> = DailyStat.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyStat.date, ascending: true)]

        let stats = (try? context.fetch(request)) ?? []
        let calendar = Calendar.current
        let years = stats.compactMap { stat -> Int? in
            guard let date = stat.date else { return nil }
            return calendar.component(.year, from: date)
        }

        return Array(Set(years)).sorted()
    }

    func applySelectedYear(context: NSManagedObjectContext) {
        updateYear(to: pendingYearSelection, context: context)
        isYearPickerPresented = false
    }

    func updateYear(to year: Int, context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let targetMonth = calendar.component(.month, from: monthAnchor)
        let availableMonths = monthsWithData(in: year, context: context)

        if let closest = closestMonth(to: targetMonth, in: availableMonths) {
            monthAnchor = closest
            return
        }

        var components = DateComponents()
        components.year = year
        components.month = targetMonth
        components.day = 1
        guard let date = calendar.date(from: components) else { return }
        monthAnchor = calendar.startOfMonth(for: date)
    }

    func alignMonthAnchorToAvailableData(context: NSManagedObjectContext) {
        let currentMonth = Calendar.current.component(.month, from: monthAnchor)
        let yearOptions = yearsWithData(context: context)

        let monthsOfYear = monthsWithData(in: currentYear, context: context)
        if monthsOfYear.isEmpty {
            guard let fallbackYear = closestYear(to: currentYear, in: yearOptions) else { return }
            let monthsInFallbackYear = monthsWithData(in: fallbackYear, context: context)
            guard let fallbackMonth = closestMonth(to: currentMonth, in: monthsInFallbackYear) else { return }
            monthAnchor = fallbackMonth
            return
        }

        guard let closest = closestMonth(to: currentMonth, in: monthsOfYear),
              !Calendar.current.isDate(closest, equalTo: monthAnchor, toGranularity: .month) else {
            return
        }

        monthAnchor = closest
    }

    func count(for date: Date, context: NSManagedObjectContext) -> Int {
        let service = StatsService(statsRepository: CoreDataStatsRepository(context: context),
                                   entryRepository: CoreDataEntryRepository(context: context))
        return service.countForDayAllTypes(user: user, date: date)
    }

    func isDayAvailable(_ date: Date) -> Bool {
        let creationStartDate = Calendar.current.startOfDay(for: user.createdAt ?? Date())
        let todayStart = Calendar.current.startOfDay(for: Date())
        let startOfDay = Calendar.current.startOfDay(for: date)
        return startOfDay >= creationStartDate && startOfDay <= todayStart
    }

    private func monthsWithData(in year: Int, context: NSManagedObjectContext) -> [Date] {
        let calendar = Calendar.current
        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear = calendar.date(byAdding: .year, value: 1, to: startOfYear) else {
            return []
        }

        let request: NSFetchRequest<DailyStat> = DailyStat.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND date >= %@ AND date < %@",
                                        user, startOfYear as NSDate, endOfYear as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyStat.date, ascending: true)]

        let stats = (try? context.fetch(request)) ?? []
        var seenMonths = Set<Date>()
        var months: [Date] = []

        for stat in stats {
            guard let date = stat.date else { continue }
            let monthStart = calendar.startOfMonth(for: date)
            if seenMonths.insert(monthStart).inserted {
                months.append(monthStart)
            }
        }

        return months
    }

    private func closestMonth(to month: Int, in months: [Date]) -> Date? {
        guard !months.isEmpty else { return nil }

        return months.min {
            let lhs = abs(Calendar.current.component(.month, from: $0) - month)
            let rhs = abs(Calendar.current.component(.month, from: $1) - month)
            return lhs < rhs
        }
    }

    private func closestYear(to year: Int, in years: [Int]) -> Int? {
        guard !years.isEmpty else { return nil }
        return years.min { abs($0 - year) < abs($1 - year) }
    }
}

final class DailyDetailViewModel: ObservableObject {
    @Published var selectedMode: DailyDetailMode = .list
    @Published var dailyTrendPoints: [DailyTrendPoint] = []

    let user: User
    let date: Date

    init(user: User, date: Date) {
        self.user = user
        self.date = date
    }

    func refreshTrendData(context: NSManagedObjectContext) {
        let stats = StatsService(statsRepository: CoreDataStatsRepository(context: context),
                                 entryRepository: CoreDataEntryRepository(context: context))
        let entryType = user.product.entryType
        let dayTotals = stats.totalsForHoursInDay(user: user, date: date, type: entryType)
        let dayCount = stats.countForDay(user: user, date: date, type: entryType)
        if dayTotals.isEmpty && dayCount == 0 {
            dailyTrendPoints = []
        } else {
            dailyTrendPoints = pointsForHoursInDay(totals: dayTotals, anchor: date, fallbackCount: dayCount)
        }
    }

    private func pointsForHoursInDay(totals: [Date: Int], anchor: Date, fallbackCount: Int) -> [DailyTrendPoint] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: anchor)

        var normalizedTotals: [Date: Int] = [:]
        for (date, count) in totals {
            let hour = calendar.component(.hour, from: date)
            guard let hourDate = calendar.date(byAdding: .hour, value: hour, to: start) else { continue }
            normalizedTotals[hourDate] = count
        }

        var points: [DailyTrendPoint] = []
        points.reserveCapacity(24)
        for hour in 0..<24 {
            guard let date = calendar.date(byAdding: .hour, value: hour, to: start) else { continue }
            points.append(DailyTrendPoint(date: date, count: normalizedTotals[date, default: 0]))
        }

        if points.allSatisfy({ $0.count == 0 }) && fallbackCount > 0 {
            return [DailyTrendPoint(date: start, count: fallbackCount)]
        }

        return points
    }
}
