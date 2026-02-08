import SwiftUI
import CoreData
import Combine
import UIKit

struct MainDashboardView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var user: User

    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false

    @State private var todayCount: Int = 0
    @State private var nextSuggestedDate: Date?
    @State private var showSettings = false
    @State private var now = Date()
    @State private var weekEntryCounts: [Date: Int] = [:]
    @State private var lastEntryDate: Date?
    @State private var bestAbstinenceInterval: TimeInterval = 0

    // Hold-to-log interaction state
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var holdTimerCancellable: AnyCancellable?
    @State private var holdCompleted = false
    @State private var hapticTrigger: Int = 0
    @State private var breathingScale: CGFloat = 1.0
    @State private var didStartBreathing = false
    @State private var breathingTask: Task<Void, Never>?
    @State private var holdHapticCancellable: AnyCancellable?
    @State private var holdHapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @State private var pendingDecrementTap = false
    @State private var isCurrentHoldDecrement = false
    @State private var pendingDecrementResetWorkItem: DispatchWorkItem?
    @State private var currentMethod: NicotineMethod?

    private var entryType: EntryType { user.product.entryType }
    private var dailyLimit: Int { max(Int(user.dailyLimit), 0) }
    private var backgroundStyle: DashboardBackgroundStyle {
        style(for: colorScheme)
    }
    private var primaryTextColor: Color {
        backgroundStyle.primaryTextColor(for: colorScheme)
    }

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let holdDuration: TimeInterval = 1.1
    private let holdTick: TimeInterval = 0.02
    private let decrementIntentWindow: TimeInterval = 1.0

    private static let nextTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale.current
        return formatter
    }()

    private static let abstinenceFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 3
        formatter.zeroFormattingBehavior = [.dropAll]
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    abstinenceStatsCard

                    holdButton

                    Spacer()

                    consumptionStatusBar
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 32)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(user: user)
            }
            .onAppear {
                now = Date()
                refreshToday(reference: now)
                refreshCurrentMethod()
                startBreathingAnimation()
            }
            .onDisappear {
                didStartBreathing = false
                breathingTask?.cancel()
                breathingTask = nil
                stopHoldHaptics()
                discardPendingDecrementIntent()
                isCurrentHoldDecrement = false
            }
            .onReceive(clock) { time in
                let previousDay = Calendar.current.startOfDay(for: now)
                let currentDay = Calendar.current.startOfDay(for: time)
                now = time
                if currentDay != previousDay {
                    refreshToday(reference: time)
                }
            }
            .onChange(of: showSettings) { isPresented in
                if !isPresented {
                    refreshCurrentMethod()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    NavigationLink {
                        CalendarScreen(user: user)
                    } label: {
                        Label("Calendar", systemImage: "calendar")
                    }

                    NavigationLink {
                        StatsScreen(user: user)
                    } label: {
                        Label("Stats", systemImage: "chart.bar.xaxis")
                    }

//                    NavigationLink {
//                        AchievementsScreen(user: user)
//                    } label: {
//                        Label("Achievements", systemImage: "medal")
//                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }
}

// MARK: - Subviews

private extension MainDashboardView {
    var holdButton: some View {
        ZStack {

            Circle()
                .fill(holdOverlayColor)
                .scaleEffect(max(holdProgress, 0.001))
                .opacity(holdProgress > 0 ? 0.9 : 0)
                .blendMode(isDecrementHoldIntent ? .normal : .plusLighter)

            Circle()
                .glassEffect(
                    .clear.interactive()
                )
                
            Text("\(todayCount)")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundStyle(primaryTextColor)
                .allowsHitTesting(false)
        }
        .frame(width: 260, height: 260)
        .scaleEffect(buttonScale)
        .animation(.easeInOut(duration: 0.12), value: isHolding)
        .contentShape(Circle())
        .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 80, pressing: { pressing in
            if pressing {
                startHold()
            } else {
                stopHoldIfNeeded()
            }
        }, perform: {
            completeHold()
        })
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    registerDecrementIntent()
                }
        )
        .sensoryFeedback(.impact(weight: .heavy, intensity: 0.95), trigger: hapticTrigger)
    }

    var abstinenceStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            abstinenceStatBlock(title: NSLocalizedString("Time since last use", comment: "elapsed timer title"),
                                value: abstinenceTimerValue,
                                isActive: hasLoggedEntries)

            Divider()
                .background(statCardBorderColor.opacity(0.6))

            abstinenceStatBlock(title: NSLocalizedString("Best nicotine-free streak", comment: "record timer title"),
                                value: abstinenceRecordValue,
                                isActive: bestRecordIsActive)

            if !hasLoggedEntries {
                Text(NSLocalizedString("Start logging to enable the timer", comment: "timer empty state hint"))
                    .font(.footnote)
                    .foregroundStyle(primaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(
            .clear,
            in: .rect(cornerRadius: 24)
        )
        .shadow(color: statCardShadowColor, radius: 12, x: 0, y: 8)
    }

    func abstinenceStatBlock(title: String, value: String, isActive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(primaryTextColor)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(primaryTextColor)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var consumptionStatusBar: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                let width = max(proxy.size.width, 1)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(primaryTextColor.opacity(0.15))

                    Capsule()
                        .fill(consumptionStatusColor)
                        .frame(width: width * nextEntryProgress)
                        .animation(.easeInOut(duration: 0.35), value: nextEntryProgress)
                }
            }
            .frame(height: 14)

            Text(consumptionStatusText.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(primaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(consumptionStatusAccessibilityLabel)
    }
}

// MARK: - Computed Values

private extension MainDashboardView {
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

    var buttonScale: CGFloat {
        let holdScale: CGFloat = isHolding ? 0.95 : 1.0
        return breathingScale * holdScale
    }

    var backgroundGradient: LinearGradient {
        backgroundStyle.backgroundGradient(for: colorScheme)
    }

    var circleGradient: RadialGradient {
        backgroundStyle.circleGradient
    }

    var statCardBackgroundColor: Color {
        switch backgroundStyle {
        case .sunrise, .melloYellow, .classic, .сyberSplash, .iceCrystal, .coralSunset, .auroraGlow, .frescoCrush:
            return Color.white.opacity(0.55)
        default:
            return Color.white.opacity(0.12)
        }
    }

    var statCardBorderColor: Color {
        switch backgroundStyle {
        case .sunrise, .melloYellow, .classic, .сyberSplash, .iceCrystal, .coralSunset, .auroraGlow, .frescoCrush:
            return Color.black.opacity(0.08)
        default:
            return Color.white.opacity(0.28)
        }
    }

    var statCardShadowColor: Color {
        switch backgroundStyle {
        case .sunrise, .melloYellow, .classic, .сyberSplash, .iceCrystal, .coralSunset, .auroraGlow, .frescoCrush:
            return Color.black.opacity(0.15)
        default:
            return Color.black.opacity(0.35)
        }
    }

    var isDecrementHoldIntent: Bool {
        isCurrentHoldDecrement || pendingDecrementTap
    }

    var holdOverlayColor: Color {
        isDecrementHoldIntent ? .black : .white
    }

    var nextEntryLabel: String {
        guard dailyLimit > 0 else {
            return NSLocalizedString("Next at: anytime", comment: "No limit fallback")
        }

        guard let nextSuggestedDate else {
            return NSLocalizedString("Next at: now", comment: "No entries yet fallback")
        }

        if nextSuggestedDate <= now {
            return NSLocalizedString("Next at: now", comment: "Ready now fallback")
        }

        let formatted = Self.nextTimeFormatter.string(from: nextSuggestedDate)
        return String.localizedStringWithFormat(
            NSLocalizedString("Next at: %@", comment: "Next entry time"),
            formatted
        )
    }

    var remainingCount: Int {
        max(dailyLimit - todayCount, 0)
    }

    var canConsumeNow: Bool {
        guard dailyLimit > 0 else { return true }
        if remainingCount == 0 { return false }
        guard let nextSuggestedDate else { return true }
        return nextSuggestedDate <= now
    }

    var nextEntryProgress: Double {
        if canConsumeNow { return 1 }
        guard dailyLimit > 0 else { return 1 }
        guard let lastEntryDate, let nextSuggestedDate else { return 0 }
        let interval = max(24 * 60 * 60 / Double(max(dailyLimit, 1)), 1)
        let elapsed = max(now.timeIntervalSince(lastEntryDate), 0)
        if nextSuggestedDate <= now { return 1 }
        return min(max(elapsed / interval, 0), 1)
    }

    var consumptionStatusColor: Color {
        canConsumeNow ? Color.green.opacity(0.85) : Color.red.opacity(0.85)
    }

    var consumptionStatusText: String {
        if canConsumeNow {
            return NSLocalizedString("Allowed now", comment: "Status label when can consume")
        }
        return NSLocalizedString("Not yet", comment: "Status label when cannot consume yet")
    }

    var consumptionStatusAccessibilityLabel: String {
        if canConsumeNow {
            return NSLocalizedString("You can consume now", comment: "Accessibility status when can consume")
        }
        return String.localizedStringWithFormat(
            NSLocalizedString("Not allowed yet. Next at: %@", comment: "Accessibility status when cannot consume"),
            nextEntryLabel
        )
    }

    var entryTypeLabel: String {
        switch entryType {
        case .cig: return NSLocalizedString("CIGARETTES", comment: "cigarettes label")
        case .puff: return NSLocalizedString("PUFFS", comment: "puffs label")
        }
    }

    var nicotineMethodLabel: String {
        guard let method = currentMethod else { return entryTypeLabel }
        if method == .disposableVape || method == .refillableVape {
            return "осталось затяжек".uppercased()
        }
        let key: String
        switch method {
        case .cigarettes:
            key = "onboarding_method_cigarettes"
        case .hookah:
            key = "onboarding_method_hookah"
        case .heatedTobacco:
            key = "onboarding_method_heated_tobacco"
        case .snusOrPouches:
            key = "onboarding_method_snus_or_pouches"
        case .disposableVape, .refillableVape:
            key = "onboarding_method_disposable_vape"
        }
        return NSLocalizedString(key, comment: "nicotine method label").uppercased()
    }

    func refreshCurrentMethod() {
        currentMethod = InMemorySettingsStore().loadProfile()?.method
    }

    var trialStatusText: String {
        guard let createdAt = user.createdAt else {
            return NSLocalizedString("TRIAL ENDS SOON", comment: "Trial fallback")
        }
        let trialDurationHours: Double = 72
        let elapsedSeconds = max(now.timeIntervalSince(createdAt), 0)
        let elapsedHours = elapsedSeconds / 3600
        let remaining = max(Int(trialDurationHours - floor(elapsedHours)), 0)
        if remaining == 0 {
            return NSLocalizedString("TRIAL ENDED", comment: "Trial ended label")
        }
        return String(format: NSLocalizedString("TRIAL ENDS IN %d HOURS", comment: "Trial countdown label"), remaining)
    }

    var weekDays: [WeekDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }

        return (0..<7).compactMap { offset -> WeekDay? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let number = calendar.component(.day, from: date)
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let label = Self.weekdayFormatter.string(from: date)
            let key = calendar.startOfDay(for: date)
            let count = weekEntryCounts[key] ?? 0
            return WeekDay(date: date,
                           displayNumber: "\(number)",
                           displayLabel: isToday ? NSLocalizedString("Today", comment: "today label") : label,
                           isToday: isToday,
                           count: count,
                           limit: dailyLimit)
        }
    }
}

// MARK: - Abstinence Helpers

private extension MainDashboardView {
    var hasLoggedEntries: Bool {
        lastEntryDate != nil || bestAbstinenceInterval > 0
    }

    var bestRecordIsActive: Bool {
        bestAbstinenceInterval > 0 || (currentAbstinenceInterval ?? 0) > 0
    }

    var currentAbstinenceInterval: TimeInterval? {
        guard let lastEntryDate else { return nil }
        return max(now.timeIntervalSince(lastEntryDate), 0)
    }

    var abstinenceTimerValue: String {
        guard let interval = currentAbstinenceInterval else {
            return "--"
        }
        return formattedDuration(interval)
    }

    var abstinenceRecordValue: String {
        let record = max(bestAbstinenceInterval, currentAbstinenceInterval ?? 0)
        guard record > 0 else {
            return NSLocalizedString("No record yet", comment: "record placeholder")
        }
        return formattedDuration(record)
    }

    func formattedDuration(_ interval: TimeInterval) -> String {
        let safeInterval = max(interval, 1)
        if safeInterval < 60 {
            return NSLocalizedString("<1m", comment: "duration shorter than a minute")
        }
        return Self.abstinenceFormatter.string(from: safeInterval) ?? "--"
    }
}

// MARK: - Week Strip Helpers

private extension MainDashboardView {
    func dayBackground(for day: WeekDay) -> Color {
        if day.isToday {
            return Color.white
        }
        if day.count == 0 {
            return Color.white.opacity(0.18)
        }
        return Color.white.opacity(0.24)
    }

    func dayRingColor(for day: WeekDay) -> Color {
        let ratio = day.progress
        if ratio >= 1.0 {
            return Color.red.opacity(0.9)
        } else if ratio >= 0.8 {
            return Color.orange.opacity(0.9)
        } else {
            return Color.green.opacity(0.95)
        }
    }
}

// MARK: - Hold Interaction

private extension MainDashboardView {
    func startBreathingAnimation() {
        guard !didStartBreathing else { return }
        didStartBreathing = true
        breathingScale = 1.0
        breathingTask?.cancel()
        breathingTask = Task {
            var increasing = true
            while !Task.isCancelled {
                let target: CGFloat = increasing ? 1.05 : 0.97
                increasing.toggle()
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 2.2)) {
                        breathingScale = target
                    }
                }
                try? await Task.sleep(nanoseconds: UInt64(2.2 * 1_000_000_000))
            }
        }
    }

    func startHold() {
        guard holdTimerCancellable == nil else { return }
        holdCompleted = false
        isHolding = true
        holdProgress = 0
        isCurrentHoldDecrement = pendingDecrementTap
        if isCurrentHoldDecrement {
            discardPendingDecrementIntent()
        } else {
            cancelDecrementIntentReset()
        }
        startHoldHaptics()

        let step = holdTick / holdDuration
        holdTimerCancellable = Timer.publish(every: holdTick, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                withAnimation(.linear(duration: holdTick)) {
                    holdProgress = min(holdProgress + step, 1)
                }
                if holdProgress >= 1 {
                    stopHoldTimer()
                }
            }
    }

    func stopHoldIfNeeded() {
        guard !holdCompleted else { return }
        cancelHold()
    }

    func cancelHold() {
        stopHoldTimer()
        isHolding = false
        stopHoldHaptics()
        if holdProgress > 0 {
            withAnimation(.easeOut(duration: 0.2)) {
                holdProgress = 0
            }
        }
        isCurrentHoldDecrement = false
    }

    func completeHold() {
        holdCompleted = true
        stopHoldTimer()
        isHolding = false
        stopHoldHaptics()

        withAnimation(.easeOut(duration: 0.25)) {
            holdProgress = 1
        }

        performHoldAction()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 0.3)) {
                holdProgress = 0
            }
            holdCompleted = false
        }
    }

    func stopHoldTimer() {
        holdTimerCancellable?.cancel()
        holdTimerCancellable = nil
    }

    func startHoldHaptics() {
        holdHapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
        holdHapticGenerator.prepare()
        holdHapticCancellable?.cancel()
        holdHapticCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                holdHapticGenerator.impactOccurred(intensity: 0.9)
            }
    }

    func stopHoldHaptics() {
        holdHapticCancellable?.cancel()
        holdHapticCancellable = nil
    }

    func registerDecrementIntent() {
        pendingDecrementTap = true
        cancelDecrementIntentReset()
        let workItem = DispatchWorkItem {
            pendingDecrementTap = false
            pendingDecrementResetWorkItem = nil
        }
        pendingDecrementResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + decrementIntentWindow, execute: workItem)
    }

    func discardPendingDecrementIntent() {
        pendingDecrementTap = false
        cancelDecrementIntentReset()
    }

    func cancelDecrementIntentReset() {
        pendingDecrementResetWorkItem?.cancel()
        pendingDecrementResetWorkItem = nil
    }

    func performHoldAction() {
        let actionSucceeded: Bool
        if isCurrentHoldDecrement {
            actionSucceeded = removeEntry()
        } else {
            actionSucceeded = logEntry()
        }
        if actionSucceeded {
            triggerHoldSuccessHaptic()
        }
        isCurrentHoldDecrement = false
    }

    func triggerHoldSuccessHaptic() {
        hapticTrigger += 1
    }
}

// MARK: - Actions

private extension MainDashboardView {
    @discardableResult
    func removeEntry() -> Bool {
        let tracker = TrackingService(context: context)
        let removed = tracker.removeLatestEntry(for: user, type: entryType, referenceDate: Date())
        if removed {
            refreshToday(reference: Date())
        }
        return removed
    }

    @discardableResult
    func logEntry() -> Bool {
        let tracker = TrackingService(context: context)
        tracker.addEntry(for: user, type: entryType)
        refreshToday(reference: Date())
        return true
    }

    func refreshToday(reference: Date) {
        let stats = StatsService(context: context)
        todayCount = stats.countForDay(user: user, date: reference, type: entryType)
        weekEntryCounts = fetchWeekCounts(stats: stats, anchor: reference)
        let abstinenceStats = fetchAbstinenceStats(reference: reference)
        lastEntryDate = abstinenceStats.lastEntry
        bestAbstinenceInterval = abstinenceStats.longestInterval
        nextSuggestedDate = calculateNextSuggestedDate(lastEntryDate: abstinenceStats.lastEntry)
    }

    func calculateNextSuggestedDate(lastEntryDate: Date?) -> Date? {
        guard dailyLimit > 0 else { return nil }
        guard let lastEntryDate else { return nil }
        let interval = 24 * 60 * 60 / Double(max(dailyLimit, 1))
        return lastEntryDate.addingTimeInterval(interval)
    }

    func fetchWeekCounts(stats: StatsService, anchor: Date) -> [Date: Int] {
        let calendar = Calendar.current
        let dayAnchor = calendar.startOfDay(for: anchor)
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: dayAnchor)) else {
            return [:]
        }

        var result: [Date: Int] = [:]
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { continue }
            let count = stats.countForDay(user: user, date: date, type: entryType)
            result[calendar.startOfDay(for: date)] = count
        }
        return result
    }

    func fetchAbstinenceStats(reference: Date) -> AbstinenceStats {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: true)]
        request.predicate = NSPredicate(format: "user == %@ AND type == %d",
                                        user, entryType.rawValue)

        guard let entries = try? context.fetch(request) else {
            return AbstinenceStats(lastEntry: nil, longestInterval: 0)
        }

        let dates = entries.compactMap { $0.createdAt }.sorted()
        guard !dates.isEmpty else {
            return AbstinenceStats(lastEntry: nil, longestInterval: 0)
        }

        var longest: TimeInterval = 0
        var previousDate = dates.first

        for date in dates.dropFirst() {
            if let previousDate {
                let gap = max(date.timeIntervalSince(previousDate), 0)
                longest = max(longest, gap)
            }
            previousDate = date
        }

        if let last = dates.last {
            let gap = max(reference.timeIntervalSince(last), 0)
            longest = max(longest, gap)
        }

        return AbstinenceStats(lastEntry: dates.last, longestInterval: max(longest, 0))
    }
}

// MARK: - Models

private struct WeekDay: Identifiable {
    let date: Date
    let displayNumber: String
    let displayLabel: String
    let isToday: Bool
    let count: Int
    let limit: Int

    var id: Date { date }

    var progress: Double {
        guard limit > 0 else { return 0 }
        return Double(count) / Double(limit)
    }
}

private struct AbstinenceStats {
    let lastEntry: Date?
    let longestInterval: TimeInterval
}

#Preview {
    if let user = try? PersistenceController.preview.container.viewContext.fetch(User.fetchRequest()).first {
        MainDashboardView(user: user)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
