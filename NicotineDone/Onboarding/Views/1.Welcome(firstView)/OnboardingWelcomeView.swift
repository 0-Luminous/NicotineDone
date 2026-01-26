import SwiftUI
#if os(iOS)
    import UIKit
#endif

struct OnboardingWelcomeView: View {
    let appName: String
    @Binding var selectedMode: OnboardingMode
    let onStart: () -> Void

    private let modes = OnboardingMode.allCases
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            pager(size: proxy.size, safeAreaInsets: proxy.safeAreaInsets)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
    }

    private func pager(size: CGSize, safeAreaInsets: EdgeInsets) -> some View {
        let width = size.width
        let fullHeight = size.height + safeAreaInsets.top + safeAreaInsets.bottom
        let currentIndex = index(for: selectedMode)
        let dragProgress = width == 0 ? 0 : dragOffset / width

        return ZStack {
            backgroundLayer(size: size,
                            fullHeight: fullHeight,
                            currentIndex: currentIndex,
                            dragProgress: dragProgress)

            HStack(spacing: 0) {
                ForEach(modes) { mode in
                    ModeSlide(appName: appName,
                              mode: mode,
                              selectedMode: selectedMode,
                              onStart: onStart,
                              safeAreaInsets: safeAreaInsets)
                        .frame(width: width, height: fullHeight)
                        .scaleEffect(mode == selectedMode ? 1 : 0.96)
                        .opacity(mode == selectedMode ? 1 : 0.72)
                        .animation(.easeInOut(duration: 0.25), value: selectedMode)
                }
            }
            .frame(width: size.width, alignment: .leading)
            .offset(x: -CGFloat(currentIndex) * width + dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let threshold = width * 0.25
                        var newIndex = currentIndex
                        if value.translation.width < -threshold {
                            newIndex = min(currentIndex + 1, modes.count - 1)
                        } else if value.translation.width > threshold {
                            newIndex = max(currentIndex - 1, 0)
                        }
                        guard newIndex != currentIndex else { return }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            selectedMode = modes[newIndex]
                        }
                        provideHapticFeedback()
                    }
            )
        }
    }

    private func index(for mode: OnboardingMode) -> Int {
        modes.firstIndex(of: mode) ?? 0
    }

    private func provideHapticFeedback() {
        #if os(iOS)
            UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    @ViewBuilder
    private func backgroundLayer(size: CGSize,
                                 fullHeight: CGFloat,
                                 currentIndex: Int,
                                 dragProgress: CGFloat) -> some View
    {
        let clamped = max(-1, min(1, dragProgress))
        let baseOpacity = 1 - min(1, abs(clamped))

        backgroundImage(for: selectedMode, size: size, fullHeight: fullHeight)
            .opacity(baseOpacity)

        if clamped != 0 {
            let direction = clamped < 0 ? 1 : -1
            let targetIndex = currentIndex + direction
            if modes.indices.contains(targetIndex) {
                backgroundImage(for: modes[targetIndex], size: size, fullHeight: fullHeight)
                    .opacity(min(1, abs(clamped)))
            }
        }
    }

    private func backgroundImage(for mode: OnboardingMode, size: CGSize, fullHeight: CGFloat) -> some View {
        Image(mode.backgroundImageName)
            .resizable()
            .scaledToFill()
            .frame(width: size.width,
                   height: fullHeight,
                   alignment: .bottom) // keep bottom content visible
            .clipped()
            .ignoresSafeArea()
    }
}

private struct ModeSlide: View {
    let appName: String
    let mode: OnboardingMode
    let selectedMode: OnboardingMode
    let onStart: () -> Void
    let safeAreaInsets: EdgeInsets

    private var isComingSoon: Bool {
        mode == .gradualReduction || mode == .quitNow
    }

    var body: some View {
        ZStack {
            headerLayer
            detailsLayer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }

    private var headerLayer: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(appName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .tracking(2)

                VStack(alignment: .leading, spacing: 6) {
                    Text("onboarding_mode_picker_title")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("onboarding_mode_picker_subtitle")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, safeAreaInsets.top + 28)

            Spacer()
        }
    }

    private var detailsLayer: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(alignment: .center, spacing: 18) {
                VStack(alignment: .center, spacing: 12) {
                    Text(mode.titleKey)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 25)
                        .padding(.top, 12)
                    Text(mode.subtitleKey)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 25)
                        .padding(.bottom, 14)
                }
                .glassEffect(
                    .clear,
                    in: .rect(cornerRadius: 24)
                )

                VStack(alignment: .leading, spacing: 10) {
                    ModeIndicator(selectedMode: selectedMode)
                    HStack {
                        Spacer()
                        Text("onboarding_mode_swipe_hint")
                            .multilineTextAlignment(.center)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                    }
                }
                Button(action: handleStart) {
                    Text(isComingSoon ? "onboarding_mode_coming_soon" : "onboarding_primary_cta")
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
                .accessibilityHint(Text(isComingSoon ? "onboarding_mode_coming_soon" : "onboarding_primary_cta_hint"))
                .disabled(isComingSoon)
                .opacity(isComingSoon ? 0.9 : 1)
            }
            .frame(maxWidth: 520, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, safeAreaInsets.bottom + 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [
                    Color.black.opacity(0.98),
                    Color.black.opacity(0.9),
                    Color.black.opacity(0.65),
                    Color.black.opacity(0.25),
                    Color.black.opacity(0.05),
                ], startPoint: .bottom, endPoint: .top)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    private func handleStart() {
        guard !isComingSoon else { return }
        onStart()
    }

    private var buttonForegroundStyle: AnyShapeStyle {
        if isComingSoon {
            return AnyShapeStyle(OnboardingTheme.primaryGradient)
        } else {
            return AnyShapeStyle(Color.white)
        }
    }

    private var buttonFillStyle: AnyShapeStyle {
        if isComingSoon {
            return AnyShapeStyle(Color.white.opacity(0.12))
        } else {
            return AnyShapeStyle(OnboardingTheme.primaryGradient)
        }
    }

    private var buttonShadowColor: Color {
        isComingSoon ? Color.black.opacity(0.25) : OnboardingTheme.accentEnd.opacity(0.4)
    }
}

private struct ModeIndicator: View {
    let selectedMode: OnboardingMode

    var body: some View {
        HStack(spacing: 10) {
            Spacer()
            ForEach(OnboardingMode.allCases) { mode in
                Capsule()
                    .fill(Color.white.opacity(mode == selectedMode ? 0.95 : 0.3))
                    .frame(width: mode == selectedMode ? 32 : 10, height: 4)
                    .animation(.easeInOut(duration: 0.25), value: selectedMode)
                    .accessibilityHidden(true)
            }
            Spacer()
        }
    }
}

#Preview("Welcome - EN") {
    OnboardingWelcomeView(appName: "SmokeTracker",
                          selectedMode: .constant(.tracking),
                          onStart: {})
        .environment(\.locale, .init(identifier: "en"))
}
