import SwiftUI

struct SettingsMethodPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let selectedMethod: NicotineMethod
    let editingProfile: NicotineProfile?
    let onProfileSelected: (NicotineProfile) -> Void

    init(selectedMethod: NicotineMethod,
         editingProfile: NicotineProfile? = nil,
         onProfileSelected: @escaping (NicotineProfile) -> Void) {
        self.selectedMethod = selectedMethod
        self.editingProfile = editingProfile
        self.onProfileSelected = onProfileSelected
    }

    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @State private var path: [SettingsMethodRoute] = []
    @State private var localSelection: NicotineMethod?
    @State private var didSeedEditingProfile = false

    private let columns = [GridItem(.adaptive(minimum: 260), spacing: 20)]
    private var highlightedMethod: NicotineMethod { localSelection ?? selectedMethod }
    private var primaryTextColor: Color { backgroundStyle.primaryTextColor(for: colorScheme) }
    private var backgroundStyle: DashboardBackgroundStyle { style(for: colorScheme) }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(NicotineMethod.allCases) { method in
                            Button {
                                openDetails(for: method)
                            } label: {
                                MethodCardView(method: method, isSelected: method == highlightedMethod)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(backgroundGradient.ignoresSafeArea())
            // .navigationTitle("Select the method of use")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .navigationDestination(for: SettingsMethodRoute.self) { route in
                switch route {
                case .methodDetails(let method):
                    OnboardingDetailsView(method: method,
                                          viewModel: onboardingViewModel,
                                          supportedCurrencies: onboardingViewModel.currencyOptions,
                                          onboardingCompleted: handleProfileCompletion,
                                          onBack: { path = [] })
                        .navigationBarBackButtonHidden()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { dismiss() }
                            }
                        }
                }
            }
        }
        .onAppear {
            seedEditingProfileIfNeeded()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pick the nicotine method you want to track.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(primaryTextColor)
            Text("This keeps reminders, stats, and budgeting focused on the right product.")
                .font(.subheadline)
                .foregroundStyle(primaryTextColor)
        }
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

    private func openDetails(for method: NicotineMethod) {
        onboardingViewModel.select(method: method)
        localSelection = method
        path = [.methodDetails(method)]
    }

    private func handleProfileCompletion(_ profile: NicotineProfile) {
        localSelection = profile.method
        onProfileSelected(profile)
        path = []
        dismiss()
    }

    private func seedEditingProfileIfNeeded() {
        guard !didSeedEditingProfile, let editingProfile else { return }
        onboardingViewModel.apply(profile: editingProfile)
        localSelection = editingProfile.method
        path = [.methodDetails(editingProfile.method)]
        didSeedEditingProfile = true
    }
}

private enum SettingsMethodRoute: Hashable {
    case methodDetails(NicotineMethod)
}

#Preview {
    let profile = NicotineProfile(method: .cigarettes,
                                  cigarettes: CigarettesConfig(),
                                  disposableVape: nil,
                                  refillableVape: nil,
                                  heatedTobacco: nil,
                                  snus: nil)
    SettingsMethodPickerView(selectedMethod: .cigarettes) { _ in }
        .preferredColorScheme(.dark)
}
