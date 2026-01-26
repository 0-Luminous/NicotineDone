import SwiftUI
import CoreData

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

    private var entryType: EntryType { user.product.entryType }
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
                    MonthSlider(months: monthsOfYear,
                                selection: $monthAnchor,
                                selectedColor: primaryTextColor,
                                unselectedColor: secondaryTextColor)
                        .foregroundStyle(primaryTextColor)

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
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.02))
                                    .frame(height: 84)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                    .glassEffect(.clear)
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
                Button {
                    pendingYearSelection = currentYear
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
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: monthAnchor)
        .sheet(item: $selectedDay) { selection in
            DailyDetailSheet(user: user, date: selection.date, entryType: entryType)
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
        let calendar = Calendar.current
        let creationYear = calendar.component(.year, from: user.createdAt ?? Date())
        let currentYear = calendar.component(.year, from: Date())
        let anchorYear = calendar.component(.year, from: monthAnchor)
        let start = [creationYear, currentYear, anchorYear].min() ?? currentYear
        let endBaseline = [creationYear, anchorYear].max() ?? currentYear
        let end = max(currentYear + 1, endBaseline)
        return Array(start...end)
    }

    private func applySelectedYear() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            updateYear(to: pendingYearSelection)
        }
        isYearPickerPresented = false
    }

    private func updateYear(to year: Int) {
        var components = Calendar.current.dateComponents([.month], from: monthAnchor)
        components.year = year
        components.day = 1
        guard let date = Calendar.current.date(from: components) else { return }
        monthAnchor = Calendar.current.startOfMonth(for: date)
    }

    private func count(for date: Date) -> Int {
        let service = StatsService(context: context)
        return service.countForDay(user: user, date: date, type: entryType)
    }

    private var yearTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("y")
        return formatter.string(from: monthAnchor)
    }

    private var monthsOfYear: [Date] {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year], from: monthAnchor)
        components.month = 1
        components.day = 1
        let startOfYear = calendar.date(from: components) ?? monthAnchor
        return (0..<12).compactMap { calendar.date(byAdding: .month, value: $0, to: startOfYear) }
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
        let index = Calendar.current.component(.month, from: selection) - 1
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
    let entryType: EntryType
    private let methodLabel: String?
    private let methodIconName: String?

    @FetchRequest private var entries: FetchedResults<Entry>
    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false

    init(user: User, date: Date, entryType: EntryType) {
        self.user = user
        self.date = date
        self.entryType = entryType
        self.methodLabel = DailyDetailSheet.resolveMethodLabel()
        self.methodIconName = DailyDetailSheet.resolveMethodIconName()

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date) as NSDate
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))! as NSDate

        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND createdAt >= %@ AND createdAt < %@ AND type == %d",
                                        user, start, end, entryType.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: true)]
        _entries = FetchRequest(fetchRequest: request, animation: .default)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                if entries.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()

                        Image("men")
                            .resizable()
                            .scaledToFit()
                            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 22))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .frame(maxWidth:.infinity)
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
                                    if let iconName = methodIconName {
                                        Image(iconName)
                                            .resizable()
                                            .scaledToFit()
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .frame(width: 50, height: 50)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
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
            .navigationTitle("Day details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: dismiss.callAsFunction)
                }
            }
        }
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
        if let methodLabel {
            return methodLabel
        }

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

    private static func resolveMethodLabel() -> String? {
        let store = InMemorySettingsStore()
        guard let method = store.loadProfile()?.method else { return nil }
        return NSLocalizedString(method.localizationKey, comment: "nicotine method label")
    }

    private static func resolveMethodIconName() -> String? {
        let store = InMemorySettingsStore()
        return store.loadProfile()?.method.iconAssetName
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
