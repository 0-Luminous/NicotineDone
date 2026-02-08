import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appViewModel: AppViewModel
    @ObservedObject var user: User
    @StateObject private var viewModel: SettingsViewModel
    private let environment: AppEnvironment

    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false
    @State private var showMethodPicker = false
    @State private var appearancePickerMode: ColorScheme? = nil
    @AppStorage("appPreferredColorScheme") private var appPreferredColorSchemeRaw: Int = 0
    @State private var editingProfile: NicotineProfile?

    @State private var showMethodManager = false
    private var backgroundStyle: DashboardBackgroundStyle {
        style(for: colorScheme)
    }

    init(user: User, environment: AppEnvironment) {
        self.user = user
        self.environment = environment
        _viewModel = StateObject(wrappedValue: SettingsViewModel(user: user, environment: environment))
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
                        navigationButtonsSection
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
            viewModel.synchronizeForm()
            ensureAppearanceMigration()
        }
        .fullScreenCover(isPresented: $showMethodPicker) {
            SettingsMethodPickerView(selectedMethod: viewModel.selectedMethod,
                                     editingProfile: editingProfile) { profile in
                viewModel.applyProfileSelection(profile)
                editingProfile = nil
            }
        }
        .fullScreenCover(isPresented: $showMethodManager) {
            SettingsMethodSelectionView(
                backgroundStyle: backgroundStyle,
                profiles: viewModel.storedProfiles,
                selectedMethod: viewModel.selectedMethod,
                onSelect: { profile in
                    viewModel.applyProfileSelection(profile)
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
                    viewModel.deleteProfile(profile)
                }
            )
        }
    }

    private func save() {
        viewModel.save()
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

                Stepper(value: $viewModel.dailyLimit, in: 1...60, step: 1) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily limit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(viewModel.dailyLimit)) per day")
                            .font(.body.weight(.semibold))
                    }
                }

            }
        }
    }

    var navigationButtonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            achievementsButton
            appearanceButton
        }
    }

    var achievementsButton: some View {
        NavigationLink {
            AchievementsScreen(user: user, environment: environment)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .frame(width: 64, height: 64)
                        .shadow(color: .black.opacity(0.2), radius: 12, y: 6)

                    Image(systemName: "medal.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(primaryTextColor)
                        .shadow(color: .white.opacity(0.5), radius: 12)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Achievements")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(primaryTextColor)
                    Text("View your progress and unlocked badges.")
                        .font(.caption)
                        .foregroundStyle(primaryTextColor.opacity(0.8))
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

    var appearanceButton: some View {
        NavigationLink {
            SettingsAppearancePickerSheet(
                appearancePickerMode: $appearancePickerMode,
                backgroundIndexLight: $backgroundIndexLight,
                backgroundIndexDark: $backgroundIndexDark,
                appPreferredColorSchemeRaw: $appPreferredColorSchemeRaw
            )
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

    var methodSelectionCard: some View {
        Button {
            showMethodManager = true
        } label: {
            SettingsMethodCardView(method: viewModel.selectedMethod,
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


}

#Preview {
    if let user = try? PersistenceController.preview.container.viewContext.fetch(User.fetchRequest()).first {
        SettingsView(user: user, environment: AppEnvironment.preview)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environment(\.appEnvironment, AppEnvironment.preview)
            .environmentObject(AppViewModel(environment: AppEnvironment.preview))
    }
}
