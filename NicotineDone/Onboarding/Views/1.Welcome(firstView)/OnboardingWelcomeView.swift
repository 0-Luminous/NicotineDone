import SwiftUI

struct OnboardingWelcomeView: View {
    let appName: String
    @Binding var selectedMode: OnboardingMode
    let onStart: () -> Void
    let linesNamespace: Namespace.ID

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundLayer(size: proxy.size)
                OnboardingLinesView(size: proxy.size, layout: .center, namespace: linesNamespace)
                transitionSourceAnchor(size: proxy.size)
                WelcomeSlide(appName: appName,
                             onStart: onStart,
                             safeAreaInsets: proxy.safeAreaInsets)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
    }

    private func backgroundLayer(size: CGSize) -> some View {
        Color.black.ignoresSafeArea()
    }

    @ViewBuilder
    private func transitionSourceAnchor(size: CGSize) -> some View {
        if #available(iOS 17.0, *) {
            Circle()
                .fill(Color.clear)
                .frame(width: 12, height: 12)
                .position(x: size.width - 20, y: size.height * 0.26)
                .matchedTransitionSource(id: "linesZoomAnchor", in: linesNamespace)
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

#Preview("Welcome - EN") {
    OnboardingWelcomeView(appName: "NicotineDone",
                          selectedMode: .constant(.tracking),
                          onStart: {},
                          linesNamespace: Namespace().wrappedValue)
        .environment(\.locale, .init(identifier: "en"))
}
