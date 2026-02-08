import SwiftUI
import CoreData
import Charts

struct CalendarScreen: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var user: User
    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false

    @State private var monthAnchor: Date = Calendar.current.startOfMonth(for: Date())
    @State private var selectedDay: DaySelection?
    @State private var isYearPickerPresented = false
    @State private var pendingYearSelection: Int = Calendar.current.component(.year, from: Date())

    private var limit: Int { Int(user.dailyLimit) }
    private var backgroundStyle: DashboardBackgroundStyle {
        style(for: colorScheme)
    }
    private var backgroundGradient: LinearGradient {
        backgroundStyle.backgroundGradient(for: colorScheme)
    }
    private var primaryTextColor: Color {
        backgroundStyle.primaryTextColor(for: colorScheme)
    }
    private var secondaryTextColor: Color { backgroundStyle.secondaryTextColor(for: colorScheme) }
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
            backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if !monthsOfYear.isEmpty {
                        MonthSlider(months: monthsOfYear,
                                    selection: $monthAnchor,
                                    selectedColor: primaryTextColor,
                                    unselectedColor: secondaryTextColor)
                            .foregroundStyle(primaryTextColor)
                    }

                    WeekdayHeader(textColor: secondaryTextColor)
                        .foregroundStyle(primaryTextColor)
                        .padding(.vertical, 8)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .glassEffect(.clear)
                        .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
                        ForEach(Array(gridDays.enumerated()), id: \.offset) { _, day in
                            if let date = day {
                                let dayCount = count(for: date)
                                let isAvailable = isDayAvailable(date)
                                Button {
                                    selectedDay = DaySelection(date: date)
                                } label: {
                                    CalendarDayCell(date: date,
                                                    count: dayCount,
                                                    limit: limit,
                                                    isToday: Calendar.current.isDateInToday(date),
                                                    isInCurrentMonth: Calendar.current.isDate(date, equalTo: monthAnchor, toGranularity: .month),
                                                    labelColor: primaryTextColor,
                                                    isAvailable: isAvailable)
                                }
                                .buttonStyle(.plain)
                                .disabled(!isAvailable)
                            } else {
                                RoundedRectangle(cornerRadius: 100, style: .continuous)
                                    .fill(Color.white.opacity(0.03))
                                    .frame(height: 84)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !yearOptions.isEmpty {
                    Button {
                        pendingYearSelection = yearOptions.contains(currentYear) ? currentYear : (yearOptions.last ?? currentYear)
                        isYearPickerPresented = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(yearTitle)
                                .font(.headline)
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        // .background(Color.white.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .tint(primaryTextColor)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: monthAnchor)
        .sheet(item: $selectedDay) { selection in
            DailyDetailSheet(user: user, date: selection.date)
                .presentationBackground(.ultraThinMaterial)
                .presentationCornerRadius(36)
        }
        .sheet(isPresented: $isYearPickerPresented) {
            NavigationStack {
                VStack {
                    Picker("Year", selection: $pendingYearSelection) {
                        ForEach(yearOptions, id: \.self) { year in
                            Text(String(year)) // Avoid locale-based digit grouping like 2.025
                                .tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .navigationTitle(Text("Select Year"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isYearPickerPresented = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            applySelectedYear()
                        }
                    }
                }
            }
            .presentationDetents([.fraction(0.35)])
        }
        .onAppear {
            alignMonthAnchorToAvailableData()
        }
    }

    private var gridDays: [Date?] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: monthAnchor) ?? 1..<32

        // All days in the current month
        let monthDays: [Date] = range.compactMap { day -> Date? in
            var components = calendar.dateComponents([.year, .month], from: monthAnchor)
            components.day = day
            return calendar.date(from: components)
        }

        // Number of leading placeholders based on the first weekday in locale
        let firstOfMonth = calendar.startOfMonth(for: monthAnchor)
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leading = (weekday - calendar.firstWeekday + 7) % 7

        // Fill with trailing placeholders to complete rows (5–6 weeks)
        let total = leading + monthDays.count
        let rows = Int(ceil(Double(total) / 7.0))
        let target = rows * 7
        let trailing = max(0, target - total)

        return Array(repeating: nil, count: leading) + monthDays.map { Optional.some($0) } + Array(repeating: nil, count: trailing)
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: monthAnchor)
    }

    private var yearOptions: [Int] {
        yearsWithData()
    }

    private func applySelectedYear() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            updateYear(to: pendingYearSelection)
        }
        isYearPickerPresented = false
    }

    private func updateYear(to year: Int) {
        let calendar = Calendar.current
        let targetMonth = calendar.component(.month, from: monthAnchor)
        let availableMonths = monthsWithData(in: year)

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

    private func count(for date: Date) -> Int {
        let service = StatsService(context: context)
        return service.countForDayAllTypes(user: user, date: date)
    }

    private var yearTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("y")
        return formatter.string(from: monthAnchor)
    }

    private var monthsOfYear: [Date] {
        monthsWithData(in: currentYear)
    }

    private func monthsWithData(in year: Int) -> [Date] {
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

    private func yearsWithData() -> [Int] {
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

    private func alignMonthAnchorToAvailableData() {
        let currentMonth = Calendar.current.component(.month, from: monthAnchor)
        let currentYear = Calendar.current.component(.year, from: monthAnchor)

        if monthsOfYear.isEmpty {
            guard let fallbackYear = closestYear(to: currentYear, in: yearOptions) else { return }
            let monthsInFallbackYear = monthsWithData(in: fallbackYear)
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

    private var creationStartDate: Date {
        Calendar.current.startOfDay(for: user.createdAt ?? Date())
    }

    private var todayStart: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private func isDayAvailable(_ date: Date) -> Bool {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return startOfDay >= creationStartDate && startOfDay <= todayStart
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let count: Int
    let limit: Int
    let isToday: Bool
    let isInCurrentMonth: Bool
    let labelColor: Color
    let isAvailable: Bool

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: 30, style: .continuous)

        return VStack(spacing: 8) {
            HStack {
                Text(dayString)
                    .font(.caption)
                    .fontWeight(isToday ? .semibold : .regular)
                    .foregroundStyle(isInCurrentMonth ? labelColor.opacity(0.9) : labelColor.opacity(0.4))
            }

            VStack(spacing: 6) {
                Text("\(count)")
                    .font(.headline)
                    .foregroundStyle(color)
                    // .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 3)
                    .background(
                        LinearGradient(
                            colors: [color.opacity(0.14), color.opacity(0.28)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .clipShape(Capsule())

                // Subtle progress bar against limit
                ProgressView(value: min(Double(count), Double(max(limit, 1))), total: Double(max(limit, 1)))
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(color)
                    .scaleEffect(x: 1, y: 0.75, anchor: .center)
                    .padding(.horizontal, 5)
            }
        }
        // .padding(12)
        .frame(height: 96)
        .background(
            cardShape
                .fill(Color.white.opacity(isInCurrentMonth ? 0.14 : 0.04))
        )
        .overlay(
            cardShape
                .strokeBorder(isToday ? Color.white : Color.white.opacity(0.12), lineWidth: isToday ? 2 : 1)
        )
        .clipShape(cardShape)
        .glassEffect(.clear)
        .shadow(color: .black.opacity(0.25 * (isInCurrentMonth ? 0.15 : 0.05)), radius: 6, x: 0, y: 4)
        .opacity(overallOpacity)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    private var dayString: String {
        let day = Calendar.current.component(.day, from: date)
        return "\(day)"
    }

    private var color: Color {
        if count == 0 { return .secondary }
        if count <= limit { return .green }
        if count <= Int(Double(limit) * 1.25) { return .orange }
        return .red
    }

    private var overallOpacity: Double {
        let monthOpacity = isInCurrentMonth ? 1.0 : 0.5
        let availabilityOpacity = isAvailable ? 1.0 : 0.35
        return monthOpacity * availabilityOpacity
    }

    private var accessibilityText: Text {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        let dateStr = formatter.string(from: date)
        let status: String
        if count == 0 { status = "no entries" }
        else if count <= limit { status = "within limit" }
        else { status = "over limit" }
        return Text("\(dateStr), count \(count), \(status)")
    }
}

// Horizontal slider to jump between months within the selected year
private struct MonthSlider: View {
    let months: [Date]
    @Binding var selection: Date
    let selectedColor: Color
    let unselectedColor: Color

    var body: some View {
        ScrollViewReader { proxy in
            sliderScrollView
                .padding(.vertical, 8)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .glassEffect(.clear)
                .padding(.horizontal)
                .onAppear { scrollToSelection(proxy) }
                .onChange(of: selection) { _, _ in
                    scrollToSelection(proxy)
                }
        }
    }

    private var sliderScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(months.indices, id: \.self) { index in
                    let month = months[index]
                    MonthChip(label: monthLabel(for: month),
                              isSelected: isSelected(month),
                              selectedColor: selectedColor,
                              unselectedColor: unselectedColor,
                              action: { select(month) })
                        .id(index)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: selection, toGranularity: .month)
    }

    private func select(_ date: Date) {
        let month = Calendar.current.startOfMonth(for: date)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            selection = month
        }
    }

    private func scrollToSelection(_ proxy: ScrollViewProxy) {
        guard !months.isEmpty else { return }
        let index = months.firstIndex(where: isSelected) ?? 0
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                proxy.scrollTo(index, anchor: .center)
            }
        }
    }

    private func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        return formatter.string(from: date).capitalized
    }
}

private struct MonthChip: View {
    let label: String
    let isSelected: Bool
    let selectedColor: Color
    let unselectedColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .monospacedDigit()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minWidth: 52)
                .foregroundStyle(isSelected ? selectedColor : unselectedColor.opacity(0.85))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 2)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
        .overlay(
            Capsule()
                .strokeBorder(borderColor, lineWidth: isSelected ? 1.5 : 1)
        )
        .clipShape(Capsule())
        .glassEffect(.clear)
    }

    private var backgroundColor: Color {
        isSelected ? Color.white.opacity(0.18) : Color.white.opacity(0.07)
    }

    private var borderColor: Color {
        isSelected ? Color.white.opacity(0.65) : Color.white.opacity(0.2)
    }
}

// Weekday header, localized and ordered by user’s firstWeekday
private struct WeekdayHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    let textColor: Color

    private var effectiveTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var symbols: [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        // Safely unwrap symbols with sensible fallback
        let base = formatter.shortStandaloneWeekdaySymbols ?? formatter.shortWeekdaySymbols ?? [
            "Sun","Mon","Tue","Wed","Thu","Fri","Sat"
        ]
        let start = calendar.firstWeekday - 1 // convert to 0-index
        let rotated = Array(base[start...]) + Array(base[..<start])
        return rotated.map { String($0.prefix(2)).uppercased() }
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(effectiveTextColor.opacity(0.85))
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// Removed external accessibility helper to avoid double counting per cell

private struct DailyDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var user: User
    let date: Date

    @FetchRequest private var entries: FetchedResults<Entry>
    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false

    @State private var selectedMode: DailyDetailMode = .list
    @State private var dailyTrendPoints: [DailyTrendPoint] = []

    init(user: User, date: Date) {
        self.user = user
        self.date = date

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date) as NSDate
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))! as NSDate

        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND createdAt >= %@ AND createdAt < %@",
                                        user, start, end)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: true)]
        _entries = FetchRequest(fetchRequest: request, animation: .default)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    Picker("Daily detail mode", selection: $selectedMode) {
                        ForEach(DailyDetailMode.allCases) { mode in
                            Text(LocalizedStringKey(mode.labelKey))
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    if selectedMode == .list {
                        listContent
                    } else {
                        trendContent
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle("Day details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: dismiss.callAsFunction)
                }
            }
        }
        .onAppear(perform: refreshTrendData)
        .onChange(of: entries.count) { _ in
            refreshTrendData()
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if entries.isEmpty {
            VStack(spacing: 16) {
                Spacer()

                Image("men")
                    .resizable()
                    .scaledToFit()
                    .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 22))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .opacity(0.85)

                Text("Отличная работа!\n Сегодня без никотина.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(primaryTextColor)
                    .padding(.horizontal, 24)

                Spacer()
            }
        } else {
            List {
                Section(header: Text(formattedDate)
                    .foregroundStyle(primaryTextColor)) {
                        ForEach(entries) { entry in
                            HStack(alignment: .center, spacing: 12) {
                                if let iconName = methodIconName(for: entry) {
                                    Image(iconName)
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .frame(height: 40)
                                }

                                VStack(alignment: .center, spacing: 4) {
                                    Text(timeString(for: entry.createdAt ?? Date()))
                                        .font(.headline)
                                        .foregroundStyle(primaryTextColor)
                                    Text(consumptionDescription(for: entry))
                                        .font(.caption)
                                        .foregroundStyle(primaryTextColor)
                                }
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private var trendContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formattedDate)
                .font(.headline)
                .foregroundStyle(primaryTextColor)

            if dailyTrendPoints.isEmpty {
                Text("stats_chart_more_data_needed")
                    .frame(maxWidth: .infinity, minHeight: 200, alignment: .center)
                    .foregroundStyle(primaryTextColor.opacity(0.7))
            } else {
                Chart(dailyTrendPoints) { point in
                    LineMark(
                        x: .value(localized("stats_chart_axis_hour"), point.date, unit: .hour),
                        y: .value(localized("stats_chart_axis_count"), point.count)
                    )
                    .foregroundStyle(Color.accentColor)

                    AreaMark(
                        x: .value(localized("stats_chart_axis_hour"), point.date, unit: .hour),
                        y: .value(localized("stats_chart_axis_count"), point.count)
                    )
                    .foregroundStyle(LinearGradient(colors: [.accentColor.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom))

                    PointMark(
                        x: .value(localized("stats_chart_axis_hour"), point.date, unit: .hour),
                        y: .value(localized("stats_chart_axis_count"), point.count)
                    )
                    .symbolSize(30)
                    .foregroundStyle(Color.accentColor)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 20))
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func consumptionDescription(for entry: Entry) -> String {
        guard let type = EntryType(rawValue: entry.type) else {
            return user.product.title
        }

        switch type {
        case .cig:
            return NSLocalizedString("Cigarettes", comment: "entry detail label")
        case .puff:
            return NSLocalizedString("Vape", comment: "entry detail label")
        }
    }

    private func methodIconName(for entry: Entry) -> String? {
        guard let type = EntryType(rawValue: entry.type) else { return nil }
        switch type {
        case .cig:
            return NicotineMethod.cigarettes.iconAssetName
        case .puff:
            return NicotineMethod.refillableVape.iconAssetName
        }
    }

    private func refreshTrendData() {
        let stats = StatsService(context: context)
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

    private func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    private var backgroundStyle: DashboardBackgroundStyle {
        style(for: colorScheme)
    }

    private var primaryTextColor: Color {
        backgroundStyle.primaryTextColor(for: colorScheme)
    }

    private var backgroundGradient: LinearGradient {
        backgroundStyle.backgroundGradient(for: colorScheme)
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
}

private enum DailyDetailMode: String, CaseIterable, Identifiable {
    case list
    case trend

    var id: String { rawValue }

    var labelKey: String {
        switch self {
        case .list: return "daily_detail_segment_list"
        case .trend: return "daily_detail_segment_trend"
        }
    }
}

private struct DailyTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

private struct DaySelection: Identifiable {
    let date: Date
    var id: Date { date }
}

#Preview {
    if let user = try? PersistenceController.preview.container.viewContext.fetch(User.fetchRequest()).first {
        CalendarScreen(user: user)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppViewModel(context: PersistenceController.preview.container.viewContext))
    }
}
