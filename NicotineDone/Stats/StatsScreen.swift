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

    @State private var weeklyData: [DailyPoint] = []
    @State private var average: Double = 0
    @State private var financialOverview: FinancialOverview = .placeholder

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

    var body: some View {
        ZStack {
            backgroundStyle.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    chartSection
                    financialSection
                    metricsSection
                    streakSection
                }
                .padding(24)
            }
        }
        .navigationTitle("Stats")
        .onAppear(perform: refresh)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats_chart_weekly_trend")
                .font(.headline)

            if weeklyData.isEmpty {
                Text("stats_chart_more_data_needed")
                    .frame(maxWidth: .infinity, minHeight: 200, alignment: .center)
                    .foregroundStyle(.secondary)
            } else {
                Chart(weeklyData) { point in
                    LineMark(
                        x: .value(localized("stats_chart_axis_day"), point.date, unit: .day),
                        y: .value(localized("stats_chart_axis_count"), point.count)
                    )
                    .foregroundStyle(Color.accentColor)

                    AreaMark(
                        x: .value(localized("stats_chart_axis_day"), point.date, unit: .day),
                        y: .value(localized("stats_chart_axis_count"), point.count)
                    )
                    .foregroundStyle(LinearGradient(colors: [.accentColor.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private var financialSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("stats_financial_title")
                        .font(.headline)
                    Text("stats_financial_subtitle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("stats_financial_limit_label")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(formatCurrency(financialOverview.baselineMonthlyBudget))
                        .font(.subheadline.weight(.semibold))
                }
            }

            HStack(spacing: 16) {
                MoneyMetricCard(title: "stats_financial_spent_title",
                                amount: formatCurrency(financialOverview.monthlySpend),
                                caption: spentSubtitle,
                                tint: .accentColor)

                MoneyMetricCard(title: "stats_financial_saved_title",
                                amount: formatCurrency(financialOverview.monthlySavings),
                                caption: savingsSubtitle,
                                tint: .green)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats_metrics_title")
                .font(.headline)

            LazyVGrid(columns: metricColumns, spacing: 16) {
                MetricCard(title: "stats_metrics_average_title",
                           value: String(format: "%.1f", average),
                           caption: "stats_metrics_average_caption")

                MetricCard(title: "Daily limit",
                           value: "\(user.dailyLimit)",
                           caption: "stats_metrics_goal_caption")

                MetricCard(title: "Level",
                           value: "\(user.level)",
                           caption: "stats_metrics_level_caption")

                MetricCard(title: "XP",
                           value: "\(user.xp)",
                           caption: "stats_metrics_xp_caption")

                MetricCard(title: "Coins",
                           value: "\(user.coins)",
                           caption: "stats_metrics_coins_caption")
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaks")
                .font(.headline)
            HStack {
                StatRow(title: "stats_streak_current_label", value: "\(user.streak?.currentLength ?? 0)")
                StatRow(title: "stats_streak_best_label", value: "\(user.streak?.bestLength ?? 0)")
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private func refresh() {
        let stats = StatsService(context: context)
        let entryType = user.product.entryType
        let totals = stats.totalsForLastDays(user: user, days: 7, type: entryType)
        weeklyData = totals.map { DailyPoint(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }

        if !weeklyData.isEmpty {
            average = Double(weeklyData.map(\.count).reduce(0, +)) / Double(weeklyData.count)
        } else {
            average = 0
        }

        let gamification = GamificationService(context: context)
        financialOverview = gamification.financialOverview(for: user)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let code = financialOverview.currencyCode.isEmpty ? (Locale.current.currencyCode ?? "USD") : financialOverview.currencyCode
        return CurrencyFormatterFactory.string(from: Decimal(amount), currencyCode: code)
    }

    private var spentSubtitle: String {
        guard financialOverview.baselineMonthlyBudget > 0 else {
            return localized("stats_financial_set_limit_hint")
        }
        let ratio = financialOverview.monthlySpend / max(financialOverview.baselineMonthlyBudget, 1)
        let percent = max(0, min(999, Int((ratio * 100).rounded())))
        return String.localizedStringWithFormat(
            NSLocalizedString("stats_financial_spent_percent", comment: ""),
            percent
        )
    }

    private var savingsSubtitle: String {
        financialOverview.monthlySavings > 0
            ? localized("stats_financial_savings_positive")
            : localized("stats_financial_savings_negative")
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
                .fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint.opacity(0.3))
        )
    }
}

private struct MetricCard: View {
    let title: LocalizedStringKey
    let value: String
    let caption: LocalizedStringKey

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
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

private struct StatRow: View {
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
}

private struct DailyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

#Preview {
    if let user = try? PersistenceController.preview.container.viewContext.fetch(User.fetchRequest()).first {
        StatsScreen(user: user)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppViewModel(context: PersistenceController.preview.container.viewContext))
    }
}
