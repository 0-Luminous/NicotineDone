import SwiftUI

struct SettingsMethodCardView: View {
    let method: NicotineMethod
    let backgroundStyle: DashboardBackgroundStyle
    @Environment(\.colorScheme) private var colorScheme

    private let cardShape = RoundedRectangle(cornerRadius: 26, style: .continuous)
    private let iconShape = RoundedRectangle(cornerRadius: 20, style: .continuous)

    private var primaryTextColor: Color {
        backgroundStyle.primaryTextColor(for: colorScheme)
    }
    private var secondaryTextColor: Color { backgroundStyle.secondaryTextColor(for: colorScheme).opacity(0.9) }

    private var isLightBackground: Bool {
        switch backgroundStyle {
        case .sunrise, .melloYellow:
            return true
        default:
            return false
        }
    }

    // private var cardFillColor: Color {
    //     isLightBackground ? Color.white.opacity(0.65) : Color.white.opacity(0.12)
    // }

    // private var cardShadowColor: Color {
    //     isLightBackground ? Color.black.opacity(0.15) : Color.black.opacity(0.4)
    // }

    private var iconStrokeColor: Color {
        isLightBackground ? Color.black.opacity(0.05) : Color.white.opacity(0.2)
    }

    private var badgeFillColor: Color {
        isLightBackground ? Color.black.opacity(0.08) : Color.white.opacity(0.18)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 16) {
                    methodIcon

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Active method")
                            .font(.caption2.weight(.semibold))
                            .textCase(.uppercase)
                            .tracking(1.8)
                            .foregroundStyle(primaryTextColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .glassEffect(.clear)
                            

                        Text(LocalizedStringKey(method.localizationKey))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(primaryTextColor)
                    }
                }

                Text(LocalizedStringKey(method.descriptionKey))
                    .font(.subheadline)
                    .foregroundStyle(primaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .trailing) {
            arrowIndicator
        }
        // .shadow(color: cardShadowColor, radius: 22, x: 0, y: 14)
        .accessibilityElement(children: .combine)
        .glassEffect(
            .clear.interactive(),
            in: .rect(cornerRadius: 24)
            )
    }

    private var methodIcon: some View {
        iconShape
            .fill(backgroundStyle.circleGradient)
            .frame(width: 72, height: 72)
            .overlay(
                Image(method.iconAssetName)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 68, height: 68)
                    .clipShape(iconShape)
            )
            .overlay(
                iconShape
                    .stroke(iconStrokeColor, lineWidth: 1)
            )
            // .shadow(color: cardShadowColor.opacity(isLightBackground ? 0.7 : 0.5), radius: 16, y: 10)
    }

    private var arrowIndicator: some View {
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
}
