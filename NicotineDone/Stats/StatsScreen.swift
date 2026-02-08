import SwiftUI
import Charts
import CoreData

struct StatsScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var user: User
    @StateObject private var viewModel: StatsViewModel
    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false

    private let metricColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)

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

    init(user: User, environment: AppEnvironment) {
        self.user = user
        _viewModel = StateObject(wrappedValue: StatsViewModel(user: user, environment: environment))
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
        .onAppear(perform: viewModel.refresh)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats_chart_trend")
                .font(.headline)

            Picker("Trend range", selection: $viewModel.selectedTrendRange) {
                ForEach(viewModel.availableTrendRanges) { range in
                    Text(LocalizedStringKey(range.labelKey))
                        .tag(range)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.currentTrendData.isEmpty {
                Text("stats_chart_more_data_needed")
                    .frame(maxWidth: .infinity, minHeight: 200, alignment: .center)
                    .foregroundStyle(.secondary)
            } else {
                let showsLine = viewModel.currentTrendData.count > 1
                let axisKey = viewModel.selectedTrendRange == .today ? "stats_chart_axis_hour" : "stats_chart_axis_day"
                let axisUnit: Calendar.Component = viewModel.selectedTrendRange == .today ? .hour : .day
                Chart(viewModel.currentTrendData) { point in
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
                    Text(formatCurrency(viewModel.currentFinancialOverview.baselineMonthlyBudget))
                        .font(.subheadline.weight(.semibold))
                }
            }

            HStack(spacing: 16) {
                MoneyMetricCard(title: LocalizedStringKey(financialSpentTitleKey),
                                amount: formatCurrency(viewModel.currentFinancialOverview.monthlySpend),
                                caption: spentSubtitle,
                                tint: .white)

                MoneyMetricCard(title: LocalizedStringKey(financialSavedTitleKey),
                                amount: formatCurrency(viewModel.currentFinancialOverview.monthlySavings),
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
                           value: String(format: "%.1f", viewModel.average),
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

    private func formatCurrency(_ amount: Double) -> String {
        let overview = viewModel.currentFinancialOverview
        let code = overview.currencyCode.isEmpty ? (Locale.current.currencyCode ?? "USD") : overview.currencyCode
        return CurrencyFormatterFactory.string(from: Decimal(amount), currencyCode: code)
    }

    private var spentSubtitle: String {
        let overview = viewModel.currentFinancialOverview
        guard overview.baselineMonthlyBudget > 0 else {
            return localized("stats_financial_set_limit_hint")
        }
        let ratio = overview.monthlySpend / max(overview.baselineMonthlyBudget, 1)
        let percent = max(0, min(999, Int((ratio * 100).rounded())))
        return String.localizedStringWithFormat(
            NSLocalizedString("stats_financial_spent_percent", comment: ""),
            percent
        )
    }

    private var savingsSubtitle: String {
        viewModel.currentFinancialOverview.monthlySavings > 0
            ? localized("stats_financial_savings_positive")
            : localized("stats_financial_savings_negative")
    }

    private var financialSubtitleKey: String {
        switch viewModel.selectedTrendRange {
        case .today: return "stats_financial_subtitle_today"
        case .week: return "stats_financial_subtitle_week"
        case .month: return "stats_financial_subtitle_month"
        case .year: return "stats_financial_subtitle_year"
        }
    }

    private var financialLimitLabelKey: String {
        switch viewModel.selectedTrendRange {
        case .today: return "stats_financial_limit_label_today"
        case .week: return "stats_financial_limit_label_week"
        case .month: return "stats_financial_limit_label_month"
        case .year: return "stats_financial_limit_label_year"
        }
    }

    private var financialSpentTitleKey: String {
        switch viewModel.selectedTrendRange {
        case .today: return "stats_financial_spent_title_today"
        case .week: return "stats_financial_spent_title_week"
        case .month: return "stats_financial_spent_title_month"
        case .year: return "stats_financial_spent_title_year"
        }
    }

    private var financialSavedTitleKey: String {
        switch viewModel.selectedTrendRange {
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

struct DailyPoint: Identifiable {
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

enum TrendRange: String, CaseIterable, Identifiable {
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
        StatsScreen(user: user, environment: AppEnvironment.preview)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environment(\.appEnvironment, AppEnvironment.preview)
            .environmentObject(AppViewModel(environment: AppEnvironment.preview))
    }
}
