import SwiftUI

struct OnboardingWelcomeView: View {
    let appName: String
    @Binding var selectedMode: OnboardingMode
    let onStart: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundLayer(size: proxy.size)
                WelcomeSlide(appName: appName,
                             onStart: onStart,
                             safeAreaInsets: proxy.safeAreaInsets)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
    }

    private func backgroundLayer(size: CGSize) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            WaveBackdropView(size: size)
        }
    }
}

private struct WelcomeSlide: View {
    let appName: String
    let onStart: () -> Void
    let safeAreaInsets: EdgeInsets

    private var welcomeTitle: String {
        String(format: NSLocalizedString("onboarding_welcome_title", comment: ""), appName)
    }

    var body: some View {
        ZStack {
            detailsLayer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }

    private var detailsLayer: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(alignment: .center, spacing: 18) {
                VStack(alignment: .center, spacing: 10) {
                    Text(welcomeTitle)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text("onboarding_welcome_subtitle")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 28)

                Button(action: handleStart) {
                    Text("onboarding_primary_cta")
                        .font(.headline)
                        .foregroundStyle(buttonForegroundStyle)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                }
                .glassEffect(.clear.interactive())
                .background(
                    Capsule()
                        .fill(buttonFillStyle)
                )
                .shadow(color: buttonShadowColor, radius: 18, x: 0, y: 10)
                .accessibilityHint(Text("onboarding_primary_cta_hint"))
            }
            .frame(maxWidth: 520, alignment: .center)
            .padding(.horizontal, 24)
            .padding(.bottom, safeAreaInsets.bottom + 24)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func handleStart() {
        onStart()
    }

    private var buttonForegroundStyle: AnyShapeStyle {
        AnyShapeStyle(Color.white)
    }

    private var buttonFillStyle: AnyShapeStyle {
        AnyShapeStyle(LinearGradient(colors: [
            Color(hex: "#6E63FF"),
            Color(hex: "#5C56F3")
        ], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private var buttonShadowColor: Color {
        Color(hex: "#6E63FF").opacity(0.35)
    }
}

private struct WaveBackdropView: View {
    let size: CGSize

    var body: some View {
        ZStack {
            waveLine(color: Color(hex: "#f08d0c"), lineWidth: 4, phase: 0.2, amplitude: 22, verticalOffset: -20)
            waveLine(color: Color(hex: "#11e17c"), lineWidth: 4, phase: 1.5, amplitude: 60, verticalOffset: 24)
            waveLine(color: Color(hex: "#11b8e1"), lineWidth: 4, phase: 1.1, amplitude: 30, verticalOffset: 14)
            waveLine(color: Color(hex: "#b1b1b1"), lineWidth: 4, phase: 2.0, amplitude: 18, verticalOffset: 44)
        }
        .frame(width: size.width, height: size.height, alignment: .center)
        .allowsHitTesting(false)
    }

    private func waveLine(color: Color,
                          lineWidth: CGFloat,
                          phase: CGFloat,
                          amplitude: CGFloat,
                          verticalOffset: CGFloat) -> some View
    {
        Path { path in
            let width = size.width + 40
            let midY = size.height * 0.32 + verticalOffset
            let startX: CGFloat = -20
            let step: CGFloat = 16
            path.move(to: CGPoint(x: startX, y: midY))
            var x = startX
            while x <= width {
                let progress = x / size.width
                let y = midY + sin((progress * .pi * 2) + phase) * amplitude
                path.addLine(to: CGPoint(x: x, y: y))
                x += step
            }
        }
        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        .shadow(color: color.opacity(0.25), radius: 6, x: 0, y: 4)
    }
}

#Preview("Welcome - EN") {
    OnboardingWelcomeView(appName: "NicotineDone",
                          selectedMode: .constant(.tracking),
                          onStart: {})
        .environment(\.locale, .init(identifier: "en"))
}
