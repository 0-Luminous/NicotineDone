import SwiftUI

struct OnboardingThemePickerView: View {
    let linesNamespace: Namespace.ID
    let onContinue: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 16)]
    private let availableThemes: [DashboardBackgroundStyle] = [
        .classic,
        .oceanDeep,
        .sunrise,
        .virentia
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()
                OnboardingLinesView(size: proxy.size, layout: .side, namespace: linesNamespace)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        header

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(availableThemes) { style in
                                Button {
                                    select(style)
                                } label: {
                                    ThemeCardView(style: style,
                                                  isSelected: isSelected(style),
                                                  colorScheme: colorScheme)
                                }
                                .buttonStyle(.plain)
                                .haptic()
                            }
                        }

                        Button(action: onContinue) {
                            Text("onboarding_theme_cta")
                                .font(.headline)
                                .foregroundStyle(Color.white)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                        }
                        .haptic()
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [
                                    Color(hex: "#6E63FF"),
                                    Color(hex: "#5C56F3")
                                ], startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        .shadow(color: Color(hex: "#6E63FF").opacity(0.35), radius: 18, x: 0, y: 10)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 140)
                    .padding(.bottom, 40)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear(perform: ensureAppearanceMigration)
        .applyLinesZoomTransition(linesNamespace: linesNamespace)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("onboarding_theme_title")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.white)
            Text("onboarding_theme_subtitle")
                .font(.callout)
                .foregroundStyle(Color.white.opacity(0.65))
        }
    }

    private func isSelected(_ style: DashboardBackgroundStyle) -> Bool {
        backgroundIndexLight == style.rawValue && backgroundIndexDark == style.rawValue
    }

    private func select(_ style: DashboardBackgroundStyle) {
        backgroundIndexLight = style.rawValue
        backgroundIndexDark = style.rawValue
    }

    private func ensureAppearanceMigration() {
        guard !appearanceStylesMigrated else { return }
        backgroundIndexLight = legacyBackgroundIndex
        backgroundIndexDark = legacyBackgroundIndex
        appearanceStylesMigrated = true
    }
}

private extension View {
    @ViewBuilder
    func applyLinesZoomTransition(linesNamespace: Namespace.ID) -> some View {
        if #available(iOS 17.0, *) {
            self.navigationTransition(.zoom(sourceID: "linesZoomAnchor", in: linesNamespace))
        } else {
            self
        }
    }
}

private struct ThemeCardView: View {
    let style: DashboardBackgroundStyle
    let isSelected: Bool
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(style.previewGradient(for: colorScheme))
                .frame(height: 90)
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                            .shadow(radius: 6)
                            .offset(x: -8, y: 8)
                    }
                }

            Text(style.name)
                .font(.footnote.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.7))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(isSelected ? 0.7 : 0.15), lineWidth: 1)
        )
    }
}

#Preview("Theme Picker") {
    OnboardingThemePickerView(linesNamespace: Namespace().wrappedValue, onContinue: {})
        .environment(\.locale, .init(identifier: "en"))
}
