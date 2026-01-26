import SwiftUI

enum OnboardingTheme {
    static let backgroundGradient = Gradient(colors: [
        Color(hex: "#070200"),
        Color(hex: "#1C0700"),
        Color(hex: "#3B0F00"),
        Color(hex: "#591900")
    ])

    static let accentStart = Color(hex: "#FFB15A")
    static let accentEnd = Color(hex: "#FE6B34")
    static let glassStroke = Color.white.opacity(0.18)

    static var primaryGradient: LinearGradient {
        LinearGradient(colors: [accentStart, accentEnd],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
    }

    static var subtleGradient: LinearGradient {
        LinearGradient(colors: [
            Color.white.opacity(0.12),
            Color.white.opacity(0.02)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct OnboardingBackgroundView: View {
    var body: some View {
        LinearGradient(gradient: OnboardingTheme.backgroundGradient,
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
            .overlay(
                RadialGradient(gradient: Gradient(colors: [
                    Color(hex: "#FFBE7B").opacity(0.5),
                    .clear
                ]),
                               center: .top,
                               startRadius: 40,
                               endRadius: 420)
                    .blur(radius: 60)
                    .blendMode(.screen)
            )
            .overlay(
                RadialGradient(gradient: Gradient(colors: [
                    Color(hex: "#FF7A18").opacity(0.35),
                    .clear
                ]),
                               center: .bottomTrailing,
                               startRadius: 10,
                               endRadius: 500)
                    .blur(radius: 100)
            )
            .ignoresSafeArea()
    }
}

struct GlowBadgeView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(OnboardingTheme.subtleGradient)
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(-12))
                .shadow(color: .black.opacity(0.45), radius: 30, x: 0, y: 20)

            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(OnboardingTheme.primaryGradient)
                .frame(width: 150, height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: OnboardingTheme.accentEnd.opacity(0.4), radius: 40, x: 0, y: 25)
                .overlay(alignment: .center) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
                }
        }
        .padding(.bottom, 20)
    }
}

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder var content: Content

    init(cornerRadius: CGFloat = 28, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(
                .clear,
                in: .rect(cornerRadius: 24)
                )
            .shadow(color: Color.black.opacity(0.45), radius: 26, x: 0, y: 18)
    }
}

struct GlassSection<Content: View>: View {
    let titleKey: LocalizedStringKey
    let content: () -> Content

    init(_ titleKey: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
        self.titleKey = titleKey
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titleKey)
                .font(.footnote.smallCaps())
                .foregroundStyle(Color.white.opacity(0.6))
                .tracking(0.5)
            GlassCard {
                VStack(alignment: .leading, spacing: 16, content: content)
            }
        }
    }
}

struct PrimaryGradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .glassEffect(
                .clear.interactive()
            )
            .foregroundStyle(Color.black.opacity(0.9))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct GlassInputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title3.weight(.semibold))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.clear.interactive())
            .shadow(
                color: Color.black.opacity(0.12),
                radius: 20,
                x: 0,
                y: 10
            )
            // .background(
            //     RoundedRectangle(cornerRadius: 20, style: .continuous)
            //         .fill(Color.white.opacity(0.05))
            //         .overlay(
            //             RoundedRectangle(cornerRadius: 20, style: .continuous)
            //                 .stroke(Color.white.opacity(0.15), lineWidth: 1)
            //         )
            // )
    }
}

extension View {
    func glassInputStyle() -> some View {
        modifier(GlassInputFieldModifier())
    }
}

extension Color {
    init(hex: String, alpha: Double = 1) {
        var cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if cleaned.count == 3 {
            let chars = Array(cleaned)
            cleaned = chars.map { "\($0)\($0)" }.joined()
        }
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: alpha)
    }
}
