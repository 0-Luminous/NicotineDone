import SwiftUI
import Combine
import UIKit
import CoreData

struct MainDashboardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var user: User
    @StateObject private var viewModel: MainDashboardViewModel
    private let environment: AppEnvironment

    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false

    @State private var showSettings = false

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

    static let nextTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter
    }()

    static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale.current
        return formatter
    }()

    static let abstinenceFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 3
        formatter.zeroFormattingBehavior = [.dropAll]
        return formatter
    }()

    init(user: User, environment: AppEnvironment) {
        self.user = user
        self.environment = environment
        _viewModel = StateObject(wrappedValue: MainDashboardViewModel(user: user, environment: environment))
    }

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
                SettingsView(user: user, environment: environment)
            }
            .onAppear {
                viewModel.onAppear()
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
                viewModel.updateNow(time)
            }
            .onChange(of: showSettings) { isPresented in
                if !isPresented {
                    viewModel.refreshCurrentMethod()
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
                        StatsScreen(user: user, environment: environment)
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
                    .haptic()
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
                
            Text("\(viewModel.todayCount)")
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
                                value: viewModel.abstinenceTimerValue,
                                isActive: viewModel.hasLoggedEntries)

            Divider()
                .background(statCardBorderColor.opacity(0.6))

            abstinenceStatBlock(title: NSLocalizedString("Best nicotine-free streak", comment: "record timer title"),
                                value: viewModel.abstinenceRecordValue,
                                isActive: viewModel.bestRecordIsActive)

            if !viewModel.hasLoggedEntries {
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
            if viewModel.shouldShowStreak {
                let circleSize: CGFloat = 16
                let spacing: CGFloat = 6
                let fullUnits = viewModel.streakFullUnits
                let partialProgress = viewModel.streakPartialProgress

                GeometryReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: spacing) {
                            ForEach(0..<viewModel.streakCircleCount, id: \.self) { index in
                                Circle()
                                    .fill(streakCircleColor(index: index, fullUnits: fullUnits, partialProgress: partialProgress))
                                    .frame(width: circleSize, height: circleSize)
                            }
                        }
                        .frame(minWidth: proxy.size.width, alignment: .center)
                        .padding(.horizontal, 2)
                    }
                }
                .frame(height: circleSize)

                Text(viewModel.streakStatusText.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.1)
                    .foregroundStyle(primaryTextColor)
            } else {
                GeometryReader { proxy in
                    let width = max(proxy.size.width, 1)
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(primaryTextColor.opacity(0.15))

                        Capsule()
                            .fill(consumptionStatusColor)
                            .frame(width: width * viewModel.nextEntryProgress)
                            .animation(.easeInOut(duration: 0.35), value: viewModel.nextEntryProgress)
                    }
                }
                .frame(height: 14)

                Text(consumptionStatusText.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.1)
                    .foregroundStyle(primaryTextColor)
            }
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
        guard viewModel.dailyLimit > 0 else {
            return NSLocalizedString("Next at: anytime", comment: "No limit fallback")
        }

        guard let nextSuggestedDate = viewModel.nextSuggestedDate else {
            return NSLocalizedString("Next at: now", comment: "No entries yet fallback")
        }

        if nextSuggestedDate <= viewModel.now {
            return NSLocalizedString("Next at: now", comment: "Ready now fallback")
        }

        let formatted = Self.nextTimeFormatter.string(from: nextSuggestedDate)
        return String.localizedStringWithFormat(
            NSLocalizedString("Next at: %@", comment: "Next entry time"),
            formatted
        )
    }

    var consumptionStatusColor: Color {
        viewModel.canConsumeNow ? Color.green.opacity(0.85) : Color.red.opacity(0.85)
    }

    var consumptionStatusText: String {
        if viewModel.canConsumeNow {
            return NSLocalizedString("Allowed now", comment: "Status label when can consume")
        }
        return NSLocalizedString("Not yet", comment: "Status label when cannot consume yet")
    }

    var consumptionStatusAccessibilityLabel: String {
        if viewModel.shouldShowStreak {
            return viewModel.streakAccessibilityLabel
        }
        if viewModel.canConsumeNow {
            return NSLocalizedString("You can consume now", comment: "Accessibility status when can consume")
        }
        return String.localizedStringWithFormat(
            NSLocalizedString("Not allowed yet. Next at: %@", comment: "Accessibility status when cannot consume"),
            nextEntryLabel
        )
    }

    var trialStatusText: String {
        guard let createdAt = user.createdAt else {
            return NSLocalizedString("TRIAL ENDS SOON", comment: "Trial fallback")
        }
        let trialDurationHours: Double = 72
        let elapsedSeconds = max(viewModel.now.timeIntervalSince(createdAt), 0)
        let elapsedHours = elapsedSeconds / 3600
        let remaining = max(Int(trialDurationHours - floor(elapsedHours)), 0)
        if remaining == 0 {
            return NSLocalizedString("TRIAL ENDED", comment: "Trial ended label")
        }
        return String(format: NSLocalizedString("TRIAL ENDS IN %d HOURS", comment: "Trial countdown label"), remaining)
    }

    var weekDays: [WeekDay] {
        viewModel.weekDays
    }

    func streakCircleColor(index: Int, fullUnits: Int, partialProgress: Double) -> Color {
        if index < fullUnits {
            return Color.green.opacity(0.85)
        }
        if index == fullUnits && partialProgress >= 0.5 {
            return Color(red: 1.0, green: 0.55, blue: 0.45).opacity(0.9)
        }
        return primaryTextColor.opacity(0.22)
    }
}

// MARK: - Abstinence Helpers

private extension MainDashboardView {
    var hasLoggedEntries: Bool { viewModel.hasLoggedEntries }
    var bestRecordIsActive: Bool { viewModel.bestRecordIsActive }
    var abstinenceTimerValue: String { viewModel.abstinenceTimerValue }
    var abstinenceRecordValue: String { viewModel.abstinenceRecordValue }
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
                    completeHold()
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
        guard !holdCompleted else { return }
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
            actionSucceeded = viewModel.removeEntry()
        } else {
            actionSucceeded = viewModel.logEntry()
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

#Preview {
    if let user = try? PersistenceController.preview.container.viewContext.fetch(User.fetchRequest()).first {
        MainDashboardView(user: user, environment: AppEnvironment.preview)
            .environment(\.appEnvironment, AppEnvironment.preview)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
