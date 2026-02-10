import SwiftUI

struct SettingsAppearancePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @Binding var appearancePickerMode: ColorScheme?
    @Binding var backgroundIndexLight: Int
    @Binding var backgroundIndexDark: Int
    @Binding var appPreferredColorSchemeRaw: Int
    @State private var selectedAchievement: AchievementItem?
    @AppStorage("unlockedThemesVersion") private var unlockedThemesVersion = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Theme", selection: $appearancePickerMode) {
                            Text("System").tag(ColorScheme?.none)
                            Text("Light").tag(ColorScheme?.some(.light))
                            Text("Dark").tag(ColorScheme?.some(.dark))
                        }
                        .pickerStyle(.segmented)

                        Text(appearancePickerDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3),
                              spacing: 16) {
                        ForEach(sortedAppearanceOptions) { style in
                            let isSelected = self.isSelected(style)
                            let isLocked = !allowedStyles.contains(style)
                            Button {
                                if isLocked {
                                    selectedAchievement = AchievementItem.catalog.first { $0.rewardTheme == style }
                                } else {
                                    backgroundIndexLight = style.rawValue
                                    backgroundIndexDark = style.rawValue
                                }
                            } label: {
                                VStack(spacing: 10) {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(style.previewGradient(for: colorScheme))
                                        .frame(height: 80)
                                        .overlay(alignment: .topTrailing) {
                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.white)
                                                    .shadow(radius: 6)
                                                    .offset(x: -8, y: 8)
                                            }
                                        }
                                        .overlay(alignment: .center) {
                                            if isLocked {
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundStyle(.white)
                                                    .shadow(radius: 6)
                                            }
                                        }
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .fill(Color.black.opacity(isLocked ? 0.35 : 0))
                                        )

                                    Text(style.name)
                                        .font(.footnote.weight(isSelected ? .semibold : .regular))
                                        .foregroundStyle(isSelected ? .primary : .secondary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color.white.opacity(isSelected ? 0.7 : 0.0), lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                            .haptic()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(currentBackgroundStyle.backgroundGradient(for: colorScheme).ignoresSafeArea())
            .navigationTitle("Choose Theme")
        }
        .preferredColorSchemeIfNeeded(appearancePickerMode)
        .onAppear {
            appearancePickerMode = Self.preferredColorScheme(from: appPreferredColorSchemeRaw)
        }
        .onChange(of: appearancePickerMode) { newValue in
            appPreferredColorSchemeRaw = Self.rawValue(from: newValue)
        }
        .sheet(item: $selectedAchievement) { achievement in
            AchievementPreviewSheet(item: achievement,
                                    primaryTextColor: currentBackgroundStyle.primaryTextColor(for: colorScheme),
                                    backgroundStyle: currentBackgroundStyle)
                .presentationBackground(.clear)
        }
    }

    private var appearancePickerDescription: String {
        if appearancePickerMode == nil {
            return NSLocalizedString("Follows System Appearance.", comment: "System appearance description")
        }
        return colorScheme == .dark
            ? NSLocalizedString("Shown when the app is in Dark Mode.", comment: "Dark appearance description")
            : NSLocalizedString("Shown when the app is in Light Mode.", comment: "Light appearance description")
    }

    private var currentBackgroundStyle: DashboardBackgroundStyle {
        let index = colorScheme == .dark ? backgroundIndexDark : backgroundIndexLight
        return DashboardBackgroundStyle(rawValue: index) ?? DashboardBackgroundStyle.default(for: colorScheme)
    }

    private func isSelected(_ style: DashboardBackgroundStyle) -> Bool {
        backgroundIndexLight == style.rawValue && backgroundIndexDark == style.rawValue
    }

    private var allowedStyles: Set<DashboardBackgroundStyle> {
        _ = unlockedThemesVersion
        return ThemeUnlockStore.unlockedStyles()
    }

    private var sortedAppearanceOptions: [DashboardBackgroundStyle] {
        let options = DashboardBackgroundStyle.appearanceOptions
        let available = options.filter { allowedStyles.contains($0) }
        let locked = options.filter { !allowedStyles.contains($0) }
        return available + locked
    }

    private static func preferredColorScheme(from raw: Int) -> ColorScheme? {
        switch raw {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    private static func rawValue(from scheme: ColorScheme?) -> Int {
        switch scheme {
        case .some(.light): return 1
        case .some(.dark): return 2
        default: return 0
        }
    }
}
