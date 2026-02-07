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
    private let iconShape = RoundedRectangle(cornerRadius: 20, style: .continuous)

    private var isLightBackground: Bool {
        switch backgroundStyle {
        case .sunrise, .melloYellow:
            return true
        default:
            return false
        }
    }

    private var iconStrokeColor: Color {
        isLightBackground ? Color.black.opacity(0.05) : Color.white.opacity(0.2)
    }
    
    private var selectedBorderColor: Color {
        primaryTextColor.opacity(isLightBackground ? 0.35 : 0.45)
    }

    var body: some View {
        GlassCard {
            HStack(alignment: .center, spacing: 20) {
                iconShape
                    .fill(backgroundStyle.circleGradient)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(method.iconAssetName)
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 66, height: 66)
                            .clipShape(iconShape)
                    )
                    .overlay(
                        iconShape
                            .stroke(iconStrokeColor, lineWidth: 1)
                    )
                    .overlay(
                        iconShape
                            .stroke(isSelected ? selectedBorderColor : .clear, lineWidth: 1)
                    )

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
            .clear,
            in: .rect(cornerRadius: 24)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isSelected ? selectedBorderColor : .clear, lineWidth: 1)
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
