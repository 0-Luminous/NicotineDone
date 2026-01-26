import SwiftUI

struct ModeSpotlightCardView: View {
    let mode: OnboardingMode
    let arrowColor: Color
    let action: () -> Void
    

    private let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                focusHeader

                Text(mode.subtitleKey)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                highlightRow
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .trailing) {
                arrowIndicator
            }
            .background(backgroundLayer)
            .clipShape(shape)
            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 26))
            .shadow(color: mode.spotlightAccentGradient.shadow.opacity(0.25), radius: 24, x: 0, y: 16)
        }
        .buttonStyle(.plain)
    }

    private var focusHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            iconBadge

            VStack(alignment: .leading, spacing: 6) {
                Text("Active focus")
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.8)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .glassEffect(.clear)

                Text(mode.titleKey)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }

            Spacer()
        }
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(mode.spotlightAccentGradient.gradient)
                .blur(radius: 16)
                .frame(width: 68, height: 68)
                .opacity(0.9)

            Circle()
                .glassEffect(.clear)
                .frame(width: 56, height: 56)

            Image(systemName: mode.spotlightSymbolName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var highlightRow: some View {
        HStack(spacing: 10) {
            ForEach(mode.spotlightHighlights, id: \.self) { highlight in
                Text(highlight)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassEffect(.clear)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.25))
                    )
            }
        }
    }

    private var overlayLayer: some View {
        LinearGradient(colors: [
            Color.black.opacity(0.9),
            Color.black.opacity(0.6),
            Color.black.opacity(0.15)
        ], startPoint: .bottom, endPoint: .top)
            .allowsHitTesting(false)
    }

    private var backgroundLayer: some View {
        ModeSpotlightBackgroundView(style: mode.spotlightBackground)
            .overlay(overlayLayer)
    }

    private var arrowIndicator: some View {
        Circle()
            .glassEffect(.clear)           
            .frame(width: 46, height: 46)
            .overlay(
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(arrowColor)
            )
            .padding(18)
            .allowsHitTesting(false)
    }
}

private struct ModeSpotlightBackgroundView: View {
    let style: ModeSpotlightBackground

    var body: some View {
        switch style {
        case let .image(name):
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        case let .gradient(gradient):
            gradient.gradient
        }
    }
}

enum ModeSpotlightBackground {
    case image(name: String)
    case gradient(ModeSpotlightGradient)
}

struct ModeSpotlightGradient {
    let colors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint
    let shadow: Color

    init(colors: [Color],
         startPoint: UnitPoint = .topLeading,
         endPoint: UnitPoint = .bottomTrailing,
         shadow: Color? = nil) {
        self.colors = colors.isEmpty ? [Color.white] : colors
        self.startPoint = startPoint
        self.endPoint = endPoint
        if let shadow {
            self.shadow = shadow
        } else {
            self.shadow = colors.last ?? .clear
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: colors,
                       startPoint: startPoint,
                       endPoint: endPoint)
    }
}

extension OnboardingMode {
    var spotlightSymbolName: String {
        switch self {
        case .tracking:
            return "target"
        case .gradualReduction:
            return "speedometer"
        case .quitNow:
            return "flame.fill"
        }
    }

    var spotlightHighlights: [String] {
        switch self {
        case .tracking:
            return ["Awareness", "Flexible pacing"]
        case .gradualReduction:
            return ["Weekly goals", "Gentle cutbacks"]
        case .quitNow:
            return ["High accountability", "Crisis tools"]
        }
    }

    var spotlightBackground: ModeSpotlightBackground {
        switch self {
        case .tracking:
            return .image(name: backgroundImageName)
        case .gradualReduction:
            return .gradient(
                ModeSpotlightGradient(colors: [
                    Color(hex: "#09122B"),
                    Color(hex: "#1F487E"),
                    Color(hex: "#A6B7FF")
                ], shadow: Color(hex: "#060C1A"))
            )
        case .quitNow:
            return .image(name: backgroundImageName)
        }
    }

    var spotlightAccentGradient: ModeSpotlightGradient {
        switch self {
        case .tracking:
            return ModeSpotlightGradient(colors: [
                Color(hex: "#FFE29F"),
                Color(hex: "#FFA99F"),
                Color(hex: "#FF719A")
            ], shadow: Color(hex: "#B95882").opacity(0.6))
        case .gradualReduction:
            return ModeSpotlightGradient(colors: [
                Color(hex: "#8DF3FF"),
                Color(hex: "#68D0FF"),
                Color(hex: "#5D2DE1")
            ], shadow: Color(hex: "#142041").opacity(0.7))
        case .quitNow:
            return ModeSpotlightGradient(colors: [
                Color(hex: "#FF9A8B"),
                Color(hex: "#FF6A88"),
                Color(hex: "#FF99AC")
            ], shadow: Color(hex: "#4F0D23").opacity(0.75))
        }
    }
}
