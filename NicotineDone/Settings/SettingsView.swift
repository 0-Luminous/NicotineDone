import CoreData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appViewModel: AppViewModel
    @ObservedObject var user: User

    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false
    @State private var selectedMethod: NicotineMethod = .cigarettes
    @State private var latestProfile: NicotineProfile?
    @State private var dailyLimit: Double = 10
    @State private var showMethodPicker = false
    @State private var showModePicker = false
    @State private var showAppearancePicker = false
    @State private var selectedMode: OnboardingMode = .tracking
    @State private var appearancePickerMode: ColorScheme? = nil
    @State private var storedProfiles: [NicotineProfile] = []
    @AppStorage("appPreferredColorScheme") private var appPreferredColorSchemeRaw: Int = 0
    @State private var editingProfile: NicotineProfile?

    @State private var showMethodManager = false
    private let savedMethodsStore = SavedMethodsStore()
    private let onboardingStore = InMemorySettingsStore()
    private var backgroundStyle: DashboardBackgroundStyle {
        style(for: colorScheme)
    }

    private var cardStrokeColor: Color {
        switch backgroundStyle {
        case .sunrise, .melloYellow, .classic, .сyberSplash, .iceCrystal, .coralSunset, .auroraGlow, .frescoCrush:
            return Color.black.opacity(0.12)
        default:
            return Color.white.opacity(0.15)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundStyle.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        trackingSection
                        guidanceSection
                        appearanceSection
                        resetSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
        }
        .onAppear {
            synchronizeForm()
            ensureAppearanceMigration()
        }
        .fullScreenCover(isPresented: $showMethodPicker) {
            SettingsMethodPickerView(selectedMethod: selectedMethod,
                                     editingProfile: editingProfile) { profile in
                applyProfileSelection(profile)
                editingProfile = nil
            }
        }
        .fullScreenCover(isPresented: $showMethodManager) {
            SettingsMethodSelectionView(
                backgroundStyle: backgroundStyle,
                profiles: storedProfiles,
                selectedMethod: selectedMethod,
                onSelect: { profile in
                    applyProfileSelection(profile)
                    showMethodManager = false
                },
                onAdd: {
                    editingProfile = nil
                    showMethodManager = false
                    showMethodPicker = true
                },
                onEdit: { profile in
                    editingProfile = profile
                    showMethodManager = false
                    showMethodPicker = true
                },
                onDelete: { profile in
                    deleteProfile(profile)
                }
            )
        }
        .fullScreenCover(isPresented: $showModePicker) {
            modePickerScreen
        }
        .sheet(isPresented: $showAppearancePicker) {
            SettingsAppearancePickerSheet(
                appearancePickerMode: $appearancePickerMode,
                showAppearancePicker: $showAppearancePicker,
                backgroundIndexLight: $backgroundIndexLight,
                backgroundIndexDark: $backgroundIndexDark,
                appPreferredColorSchemeRaw: $appPreferredColorSchemeRaw
            )
        }
    }

    private func synchronizeForm() {
        refreshStoredProfiles()
        if let profile = storedProfiles.first {
            selectedMethod = profile.method
        } else {
            selectedMethod = nicotineMethod(for: ProductType(rawValue: user.productType) ?? .cigarette)
        }
        dailyLimit = Double(user.dailyLimit)
        selectedMode = .tracking
    }

    private func save() {
        user.productType = productType(for: selectedMethod).rawValue
        user.dailyLimit = Int32(dailyLimit)

        if let profile = latestProfile {
            user.packSize = Int16(clamping: packSize(for: profile))
            user.packCost = packCost(for: profile)
            user.currencyCode = profile.selectedCurrency.code
        }

        context.saveIfNeeded()
        dismiss()
    }
}

private extension SettingsView {
    private var primaryTextColor: Color {
        backgroundStyle.primaryTextColor(for: colorScheme)
    }
    private func style(for scheme: ColorScheme) -> DashboardBackgroundStyle {
        ensureAppearanceMigration()
        let index = backgroundIndex(for: scheme)
        return DashboardBackgroundStyle(rawValue: index) ?? DashboardBackgroundStyle.default(for: scheme)
    }

    private func backgroundIndex(for scheme: ColorScheme) -> Int {
        scheme == .dark ? backgroundIndexDark : backgroundIndexLight
    }

    private func updateBackgroundIndex(_ newValue: Int, for scheme: ColorScheme) {
        if scheme == .dark {
            backgroundIndexDark = newValue
        } else {
            backgroundIndexLight = newValue
        }
    }

    private func ensureAppearanceMigration() {
        guard !appearanceStylesMigrated else { return }
        backgroundIndexLight = legacyBackgroundIndex
        backgroundIndexDark = legacyBackgroundIndex
        appearanceStylesMigrated = true
    }

    var trackingSection: some View {
        settingsCard(title: "Tracking") {
            VStack(alignment: .leading, spacing: 16) {
                methodSelectionCard

                Stepper(value: $dailyLimit, in: 1...60, step: 1) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily limit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(dailyLimit)) per day")
                            .font(.body.weight(.semibold))
                    }
                }
            }
        }
    }

    var appearanceSection: some View {
        settingsCard(title: "Appearance") {
            Button {
                showAppearancePicker = true
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                             .frame(width: 64, height: 64)
                             .shadow(color: .black.opacity(0.2), radius: 12, y: 6)

                        Image(systemName: "paintpalette.fill")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(primaryTextColor)
                            .shadow(color: .white.opacity(0.5), radius: 12)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Application theme")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(primaryTextColor)
                        Text(backgroundStyle.name)
                            .font(.caption)
                            .foregroundStyle(primaryTextColor)
                    }
            
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 24))
                .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 8)
            }
            .overlay(alignment: .trailing) {
                Circle()
                        .glassEffect(.clear)           
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(primaryTextColor)
                        )
                        .padding(12)
            }
            .buttonStyle(.plain)
        }
    }

    var guidanceSection: some View {
        settingsCard(title: "App mode") {
            VStack(alignment: .leading, spacing: 16) {
                ModeSpotlightCardView(mode: selectedMode,
                                      arrowColor: primaryTextColor) {
                    showModePicker = true
                }
                .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 8)
            }
        }
    }

    var resetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(role: .destructive) {
                appViewModel.resetOnboarding()
                dismiss()
            } label: {
                HStack {
                    Spacer()
                    Text("Reset onboarding")
                        .font(.body.weight(.semibold))
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.red.opacity(0.3))
            )

            Text("You can re-run the onboarding to change more details or start a new journey.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var modePickerScreen: some View {
        ZStack(alignment: .topTrailing) {
            OnboardingWelcomeView(appName: "SmokeTracker",
                                  selectedMode: $selectedMode) {
                showModePicker = false
            }
            .preferredColorScheme(.dark)

            Button {
                showModePicker = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
                    .padding(10)
                    .glassEffect(.clear.interactive())
            }
            .padding(.trailing, 20)
        }
    }

    var methodSelectionCard: some View {
        Button {
            showMethodManager = true
        } label: {
            SettingsMethodCardView(method: selectedMethod,
                                   backgroundStyle: backgroundStyle)
        }
        .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 8)
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func settingsCard<Content: View>(title: LocalizedStringKey,
                                     @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.clear, in: .rect(cornerRadius: 24))
    }

    func nicotineMethod(for product: ProductType) -> NicotineMethod {
        switch product {
        case .cigarette:
            return .cigarettes
        case .vape:
            return .refillableVape
        }
    }

    func productType(for method: NicotineMethod) -> ProductType {
        switch method {
        case .cigarettes, .heatedTobacco, .snusOrPouches:
            return .cigarette
        case .disposableVape, .refillableVape:
            return .vape
        }
    }

    func dailyLimit(for profile: NicotineProfile) -> Int {
        switch profile.method {
        case .cigarettes:
            return profile.cigarettes?.cigarettesPerDay ?? 10
        case .disposableVape:
            guard let config = profile.disposableVape else { return 150 }
            let computed = max(80, config.puffsPerDevice / 5)
            return min(computed, config.puffsPerDevice)
        case .refillableVape:
            guard let config = profile.refillableVape else { return 200 }
            return max(100, config.estimatedPuffsPerMl * 5)
        case .heatedTobacco:
            return profile.heatedTobacco?.dailySticks ?? 15
        case .snusOrPouches:
            return profile.snus?.dailyPouches ?? 10
        }
    }

    func packSize(for profile: NicotineProfile) -> Int {
        switch profile.method {
        case .cigarettes:
            return profile.cigarettes?.cigarettesPerPack ?? 20
        case .disposableVape:
            return profile.disposableVape?.puffsPerDevice ?? 600
        case .refillableVape:
            return profile.refillableVape?.liquidBottleMl ?? 30
        case .heatedTobacco:
            return profile.heatedTobacco?.sticksPerPack ?? 20
        case .snusOrPouches:
            return profile.snus?.pouchesPerCan ?? 20
        }
    }

    func packCost(for profile: NicotineProfile) -> Double {
        switch profile.method {
        case .cigarettes:
            guard let price = profile.cigarettes?.packPrice else { return 0 }
            return NSDecimalNumber(decimal: price).doubleValue
        case .disposableVape:
            guard let price = profile.disposableVape?.devicePrice else { return 0 }
            return NSDecimalNumber(decimal: price).doubleValue
        case .refillableVape:
            guard let config = profile.refillableVape else { return 0 }
            let total = config.liquidPrice + (config.coilPrice ?? 0)
            return NSDecimalNumber(decimal: total).doubleValue
        case .heatedTobacco:
            guard let price = profile.heatedTobacco?.packPrice else { return 0 }
            return NSDecimalNumber(decimal: price).doubleValue
        case .snusOrPouches:
            guard let price = profile.snus?.canPrice else { return 0 }
            return NSDecimalNumber(decimal: price).doubleValue
        }
    }

    private func refreshStoredProfiles() {
        let latestOnboardingProfile = onboardingStore.loadProfile()
        storedProfiles = savedMethodsStore.mergeLatestOnboardingProfile(latestOnboardingProfile)
    }

    private func applyProfileSelection(_ profile: NicotineProfile, persist: Bool = true) {
        latestProfile = profile
        selectedMethod = profile.method
        dailyLimit = Double(dailyLimit(for: profile))
        if persist {
            savedMethodsStore.save(profile: profile)
        }
        try? onboardingStore.save(profile: profile)
        refreshStoredProfiles()
    }

    private func deleteProfile(_ profile: NicotineProfile) {
        savedMethodsStore.delete(method: profile.method)
        refreshStoredProfiles()
        if selectedMethod == profile.method {
            if let fallback = storedProfiles.first {
                // Apply without re-saving since store already updated.
                applyProfileSelection(fallback, persist: false)
            } else {
                selectedMethod = nicotineMethod(for: ProductType(rawValue: user.productType) ?? .cigarette)
                dailyLimit = Double(user.dailyLimit)
                latestProfile = nil
            }
        }
    }

}

#Preview {
    if let user = try? PersistenceController.preview.container.viewContext.fetch(User.fetchRequest()).first {
        SettingsView(user: user)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppViewModel(context: PersistenceController.preview.container.viewContext))
    }
}
