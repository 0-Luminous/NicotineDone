import SwiftUI
import CoreData
import Charts

struct StatsScreen: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var user: User
    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false

    private let metricColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)

    @State private var trendData: [TrendRange: [DailyPoint]] = [:]
    @State private var selectedTrendRange: TrendRange = .today
    @State private var availableTrendRanges: [TrendRange] = [.today]
    @State private var average: Double = 0
    @State private var financialOverviewByRange: [TrendRange: FinancialOverview] = [:]

    private var backgroundStyle: DashboardBackgroundStyle {
        style(for: colorScheme)
    }

    private func style(for scheme: ColorScheme) -> DashboardBackgroundStyle {
        ensureAppearanceMigration()
        let index = scheme == .dark ? backgroundIndexDark : backgroundIndexLight
        return DashboardBackgroundStyle(rawValue: index) ?? DashboardBackgroundStyle.default(for: scheme)
    }

    private func ensureAppearanceMigration() {
        guard !appearanceStylesMigrated else { return }
        backgroundIndexLight = legacyBackgroundIndex
        backgroundIndexDark = legacyBackgroundIndex
        appearanceStylesMigrated = true
    }

    private var currentTrendData: [DailyPoint] {
        trendData[selectedTrendRange] ?? []
    }

    private var currentFinancialOverview: FinancialOverview {
        financialOverviewByRange[selectedTrendRange]
            ?? financialOverviewByRange[.today]
            ?? .placeholder
    }

    var body: some View {
        ZStack {
            backgroundStyle.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    chartSection
                    financialSection
                    metricsSection
                }
                .padding(24)
            }
        }
        .navigationTitle("Stats")
        .onAppear(perform: refresh)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats_chart_trend")
                .font(.headline)

            Picker("Trend range", selection: $selectedTrendRange) {
                ForEach(availableTrendRanges) { range in
                    Text(LocalizedStringKey(range.labelKey))
                        .tag(range)
                }
            }
            .pickerStyle(.segmented)

            if currentTrendData.isEmpty {
                Text("stats_chart_more_data_needed")
                    .frame(maxWidth: .infinity, minHeight: 200, alignment: .center)
                    .foregroundStyle(.secondary)
            } else {
                let showsLine = currentTrendData.count > 1
                let axisKey = selectedTrendRange == .today ? "stats_chart_axis_hour" : "stats_chart_axis_day"
                let axisUnit: Calendar.Component = selectedTrendRange == .today ? .hour : .day
                Chart(currentTrendData) { point in
                    if showsLine {
                        LineMark(
                            x: .value(localized(axisKey), point.date, unit: axisUnit),
                            y: .value(localized("stats_chart_axis_count"), point.count)
                        )
                        .foregroundStyle(Color.accentColor)

                        AreaMark(
                            x: .value(localized(axisKey), point.date, unit: axisUnit),
                            y: .value(localized("stats_chart_axis_count"), point.count)
                        )
                        .foregroundStyle(LinearGradient(colors: [.accentColor.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom))
                    }

                    PointMark(
                        x: .value(localized(axisKey), point.date, unit: axisUnit),
                        y: .value(localized("stats_chart_axis_count"), point.count)
                    )
                    .symbolSize(showsLine ? 30 : 70)
                    .foregroundStyle(Color.accentColor)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .statsLiquidGlassCard()
    }

    private var financialSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("stats_financial_title")
                        .font(.headline)
                    Text(LocalizedStringKey(financialSubtitleKey))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(LocalizedStringKey(financialLimitLabelKey))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(formatCurrency(currentFinancialOverview.baselineMonthlyBudget))
                        .font(.subheadline.weight(.semibold))
                }
            }

            HStack(spacing: 16) {
                MoneyMetricCard(title: LocalizedStringKey(financialSpentTitleKey),
                                amount: formatCurrency(currentFinancialOverview.monthlySpend),
                                caption: spentSubtitle,
                                tint: .white)

                MoneyMetricCard(title: LocalizedStringKey(financialSavedTitleKey),
                                amount: formatCurrency(currentFinancialOverview.monthlySavings),
                                caption: savingsSubtitle,
                                tint: .white)
            }
        }
        .padding()
        .statsLiquidGlassCard()
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats_metrics_title")
                .font(.headline)

            LazyVGrid(columns: metricColumns, spacing: 16) {
                MetricCard(title: "stats_metrics_average_title",
                           value: String(format: "%.1f", average),
                           caption: "stats_metrics_average_caption",
                           tint: .white)

                MetricCard(title: "Daily limit",
                           value: "\(user.dailyLimit)",
                           caption: "stats_metrics_goal_caption",
                           tint: .white)
            }
        }
        .padding()
        .statsLiquidGlassCard()
    }

    private func refresh() {
        let stats = StatsService(context: context)
        let entryType = user.product.entryType
        let anchor = Date()
        let todayCount = stats.countForDay(user: user, date: anchor, type: entryType)
        let todayHourlyTotals = stats.totalsForHoursInDay(user: user, date: anchor, type: entryType)
        let weekTotals = stats.totalsForLastDays(user: user, days: 7, type: entryType)
        let monthTotals = stats.totalsForLastDays(user: user, days: 30, type: entryType)
        let yearTotals = stats.totalsForLastDays(user: user, days: 365, type: entryType)

        var nextTrendData: [TrendRange: [DailyPoint]] = [
            .today: pointsForHoursInDay(totals: todayHourlyTotals, anchor: anchor, fallbackCount: todayCount)
        ]
        var nextAvailableRanges: [TrendRange] = [.today]

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
            selectedTrendRange = .today
        }

        if let weekData = trendData[.week], !weekData.isEmpty {
            average = Double(weekData.map(\.count).reduce(0, +)) / Double(weekData.count)
        } else {
            average = 0
        }

        let gamification = GamificationService(context: context)
        var nextFinancialOverviewByRange: [TrendRange: FinancialOverview] = [:]
        for range in TrendRange.allCases {
            nextFinancialOverviewByRange[range] = gamification.financialOverview(for: user, days: range.lookbackDays)
        }
        financialOverviewByRange = nextFinancialOverviewByRange
    }

    private func pointsForLastDays(days: Int, totals: [Date: Int], anchor: Date) -> [DailyPoint] {
        guard days > 0 else { return [] }
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: anchor)
        guard let start = calendar.date(byAdding: .day, value: -days + 1, to: end) else { return [] }

        var normalizedTotals: [Date: Int] = [:]
        for (date, count) in totals {
            normalizedTotals[calendar.startOfDay(for: date)] = count
        }

        return (0..<days).compactMap { offset -> DailyPoint? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let day = calendar.startOfDay(for: date)
            return DailyPoint(date: day, count: normalizedTotals[day, default: 0])
        }
    }

    private func pointsForHoursInDay(totals: [Date: Int], anchor: Date, fallbackCount: Int) -> [DailyPoint] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: anchor)

        var normalizedTotals: [Date: Int] = [:]
        for (date, count) in totals {
            let hour = calendar.component(.hour, from: date)
            guard let hourDate = calendar.date(byAdding: .hour, value: hour, to: start) else { continue }
            normalizedTotals[hourDate] = count
        }

        var points: [DailyPoint] = []
        points.reserveCapacity(24)
        for hour in 0..<24 {
            guard let date = calendar.date(byAdding: .hour, value: hour, to: start) else { continue }
            points.append(DailyPoint(date: date, count: normalizedTotals[date, default: 0]))
        }

        if points.allSatisfy({ $0.count == 0 }) && fallbackCount > 0 {
            return [DailyPoint(date: start, count: fallbackCount)]
        }

        return points
    }

    private func formatCurrency(_ amount: Double) -> String {
        let code = currentFinancialOverview.currencyCode.isEmpty ? (Locale.current.currencyCode ?? "USD") : currentFinancialOverview.currencyCode
        return CurrencyFormatterFactory.string(from: Decimal(amount), currencyCode: code)
    }

    private var spentSubtitle: String {
        guard currentFinancialOverview.baselineMonthlyBudget > 0 else {
            return localized("stats_financial_set_limit_hint")
        }
        let ratio = currentFinancialOverview.monthlySpend / max(currentFinancialOverview.baselineMonthlyBudget, 1)
        let percent = max(0, min(999, Int((ratio * 100).rounded())))
        return String.localizedStringWithFormat(
            NSLocalizedString("stats_financial_spent_percent", comment: ""),
            percent
        )
    }

    private var savingsSubtitle: String {
        currentFinancialOverview.monthlySavings > 0
            ? localized("stats_financial_savings_positive")
            : localized("stats_financial_savings_negative")
    }

    private var financialSubtitleKey: String {
        switch selectedTrendRange {
        case .today: return "stats_financial_subtitle_today"
        case .week: return "stats_financial_subtitle_week"
        case .month: return "stats_financial_subtitle_month"
        case .year: return "stats_financial_subtitle_year"
        }
    }

    private var financialLimitLabelKey: String {
        switch selectedTrendRange {
        case .today: return "stats_financial_limit_label_today"
        case .week: return "stats_financial_limit_label_week"
        case .month: return "stats_financial_limit_label_month"
        case .year: return "stats_financial_limit_label_year"
        }
    }

    private var financialSpentTitleKey: String {
        switch selectedTrendRange {
        case .today: return "stats_financial_spent_title_today"
        case .week: return "stats_financial_spent_title_week"
        case .month: return "stats_financial_spent_title_month"
        case .year: return "stats_financial_spent_title_year"
        }
    }

    private var financialSavedTitleKey: String {
        switch selectedTrendRange {
        case .today: return "stats_financial_saved_title_today"
        case .week: return "stats_financial_saved_title_week"
        case .month: return "stats_financial_saved_title_month"
        case .year: return "stats_financial_saved_title_year"
        }
    }

    private func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}

private struct MoneyMetricCard: View {
    let title: LocalizedStringKey
    let amount: String
    let caption: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(amount)
                .font(.title3.weight(.semibold))
            Text(verbatim: caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint.opacity(0.5))
        )
    }
}

private struct MetricCard: View {
    let title: LocalizedStringKey
    let value: String
    let caption: LocalizedStringKey
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint.opacity(0.5))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

private struct DailyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

private extension View {
    func statsLiquidGlassCard(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: cornerRadius))
    }
}

private enum TrendRange: String, CaseIterable, Identifiable {
    case today
    case week
    case month
    case year

    var id: String { rawValue }

    var labelKey: String {
        switch self {
        case .today: return "stats_chart_range_today"
        case .week: return "stats_chart_range_week"
        case .month: return "stats_chart_range_month"
        case .year: return "stats_chart_range_year"
        }
    }

    var lookbackDays: Int {
        switch self {
        case .today: return 1
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }
}

#Preview {
    if let user = try? PersistenceController.preview.container.viewContext.fetch(User.fetchRequest()).first {
        StatsScreen(user: user)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppViewModel(context: PersistenceController.preview.container.viewContext))
    }
}
