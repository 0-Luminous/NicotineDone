import SwiftUI

struct OnboardingMethodPickerView: View {
    let selectedMethod: NicotineMethod?
    let onMethodSelected: (NicotineMethod) -> Void
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false

    private let columns = [GridItem(.adaptive(minimum: 220), spacing: 20)]
    private var backgroundStyle: DashboardBackgroundStyle { style(for: colorScheme) }
    private var backgroundGradient: LinearGradient { backgroundStyle.backgroundGradient(for: colorScheme) }
    private var primaryTextColor: Color { backgroundStyle.primaryTextColor(for: colorScheme) }
    private var secondaryTextColor: Color { backgroundStyle.secondaryTextColor(for: colorScheme) }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("onboarding_step_two")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(secondaryTextColor.opacity(0.9))
                        Text("onboarding_method_card_hint_copy")
                            .font(.callout)
                            .foregroundStyle(primaryTextColor.opacity(0.85))
                    }
                    .padding(.top, 130)

                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(NicotineMethod.allCases) { method in
                            Button {
                                onMethodSelected(method)
                            } label: {
                                MethodCardView(method: method, isSelected: method == selectedMethod)
                            }
                            .buttonStyle(.plain)
                            .haptic()
                            .accessibilityHint(Text("onboarding_method_card_hint"))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 36)
            }
        }
        .ignoresSafeArea()
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

#Preview("Methods - RU") {
    OnboardingMethodPickerView(selectedMethod: .cigarettes, onMethodSelected: { _ in })
        .environment(\.locale, .init(identifier: "ru"))
}
