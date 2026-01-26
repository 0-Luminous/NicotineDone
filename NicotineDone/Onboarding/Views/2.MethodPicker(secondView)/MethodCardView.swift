import SwiftUI

struct MethodCardView: View {
    let method: NicotineMethod
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false

    private var backgroundStyle: DashboardBackgroundStyle {
        style(for: colorScheme)
    }
    private var primaryTextColor: Color {
        backgroundStyle.primaryTextColor(for: colorScheme)
    }

    var body: some View {
        GlassCard {
            HStack(alignment: .center, spacing: 20) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(OnboardingTheme.primaryGradient)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(method.iconAssetName)
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    )
                    .shadow(color: OnboardingTheme.accentEnd.opacity(0.5), radius: 20, x: 0, y: 10)

                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStringKey(method.localizationKey))
                        .font(.headline)
                        .foregroundStyle(primaryTextColor)
                    Text(LocalizedStringKey(method.descriptionKey))
                        .font(.subheadline)
                        .foregroundStyle(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(primaryTextColor)
                        .font(.title2)
                        .accessibilityHidden(true)
                }
            }
        }
        .glassEffect(
            .clear.interactive(),
            in: .rect(cornerRadius: 24)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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
