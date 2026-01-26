import SwiftUI

struct SettingsAppearancePickerSheet: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var appearancePickerMode: ColorScheme?
    @Binding var showAppearancePicker: Bool
    @Binding var backgroundIndexLight: Int
    @Binding var backgroundIndexDark: Int
    @Binding var appPreferredColorSchemeRaw: Int

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
                        ForEach(DashboardBackgroundStyle.appearanceOptions) { style in
                            let isSelected = self.isSelected(style)
                            Button {
                                backgroundIndexLight = style.rawValue
                                backgroundIndexDark = style.rawValue
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
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(currentBackgroundStyle.backgroundGradient(for: colorScheme).ignoresSafeArea())
            .navigationTitle("Choose Theme")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showAppearancePicker = false }
                }
                // ToolbarItem(placement: .principal) {
                //     Text("Choose Appearance")
                //         .font(.headline)
                // }
            }
        }
        .presentationDetents([.large])
        .preferredColorSchemeIfNeeded(appearancePickerMode)
        .onAppear {
            appearancePickerMode = Self.preferredColorScheme(from: appPreferredColorSchemeRaw)
        }
        .onChange(of: appearancePickerMode) { newValue in
            appPreferredColorSchemeRaw = Self.rawValue(from: newValue)
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
