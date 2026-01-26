import SwiftUI

enum DashboardBackgroundStyle: Int, CaseIterable, Identifiable {
    case sunrise
    case melloYellow
    case ocean
    case forest
    case classic
    case oceanDeep
    case cosmicPurple
    case сyberSplash
    case lavaBurst
    case iceCrystal
    case coralSunset
    case auroraGlow
    case virentia
    case frescoCrush
    case pinkNebula

    static let `default`: DashboardBackgroundStyle = .iceCrystal
    static let defaultDark: DashboardBackgroundStyle = .iceCrystal
    static func `default`(for scheme: ColorScheme) -> DashboardBackgroundStyle {
        scheme == .dark ? defaultDark : `default`
    }

    static let appearanceOptions: [DashboardBackgroundStyle] =
        DashboardBackgroundStyle.allCases.sorted { $0.colorSortOrder < $1.colorSortOrder }

    var id: Int { rawValue }

    // Sort by dominant hue so the picker groups similar gradients together.
    private var colorSortOrder: Int {
        switch self {
        case .coralSunset: return 20
        case .sunrise: return 40
        case .frescoCrush: return 60
        case .forest: return 140
        case .melloYellow: return 145
        case .auroraGlow: return 160
        case .virentia: return 175
        case .сyberSplash: return 181
        case .oceanDeep: return 195
        case .ocean: return 208
        case .iceCrystal: return 216
        case .cosmicPurple: return 270
        case .pinkNebula: return 331
        case .lavaBurst: return 347
        case .classic: return 1000
        }
    }

    var name: String {
        switch self {
        case .iceCrystal: return NSLocalizedString("Ice Crystal", comment: "Dashboard background option")
        case .sunrise: return NSLocalizedString("Sunrise", comment: "Dashboard background option")
        case .melloYellow: return NSLocalizedString("Mello", comment: "Dashboard background option")
        case .classic: return NSLocalizedString("Classic", comment: "Dashboard background option")
        case .coralSunset: return NSLocalizedString("Coral Sunset", comment: "Dashboard background option")
        case .ocean: return NSLocalizedString("Ocean", comment: "Dashboard background option")
        case .frescoCrush: return NSLocalizedString("Fresco", comment: "Dashboard background option")
        case .forest: return NSLocalizedString("Forest", comment: "Dashboard background option")
        case .oceanDeep: return NSLocalizedString("Sky", comment: "Dashboard background option")
        case .сyberSplash: return NSLocalizedString("Cyber", comment: "Dashboard background option")
        case .lavaBurst: return NSLocalizedString("Lava Burst", comment: "Dashboard background option")
        case .auroraGlow: return NSLocalizedString("Aurora Glow", comment: "Dashboard background option")
        case .virentia: return NSLocalizedString("Virentia", comment: "Dashboard background option")
        case .pinkNebula: return NSLocalizedString("Pink Nebula", comment: "Dashboard background option")
        case .cosmicPurple: return NSLocalizedString("Cosmic", comment: "Dashboard background option")
        }
    }

    var previewGradient: LinearGradient {
        previewGradient(for: .light)
    }

    func previewGradient(for scheme: ColorScheme) -> LinearGradient {
        LinearGradient(colors: gradientColors(for: scheme),
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
    }

    var backgroundGradient: LinearGradient {
        backgroundGradient(for: .light)
    }

    func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        LinearGradient(colors: gradientColors(for: scheme), startPoint: .top, endPoint: .bottom)
    }

    var circleGradient: RadialGradient {
        RadialGradient(colors: circleColors, center: .center, startRadius: 40, endRadius: 170)
    }

    func primaryTextColor(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.95)
            : Color.black.opacity(0.9)
    }

    func secondaryTextColor(for scheme: ColorScheme) -> Color {
        switch self {
        case .melloYellow, .сyberSplash, .frescoCrush:
            return scheme == .dark ? Color.white.opacity(0.78) : Color.black.opacity(0.7)
        case .sunrise, .classic, .iceCrystal, .coralSunset, .auroraGlow:
            return Color.black.opacity(0.7)
        case .ocean, .forest, .oceanDeep, .cosmicPurple, .lavaBurst, .virentia, .pinkNebula:
            return Color.white.opacity(0.78)
        }
    }

    var circleTextColor: Color {
        switch self {
        case .sunrise, .melloYellow, .classic, .сyberSplash, .iceCrystal, .coralSunset, .auroraGlow, .frescoCrush:
            return Color.black.opacity(0.85)
        case .ocean, .forest, .oceanDeep, .cosmicPurple, .lavaBurst, .virentia, .pinkNebula:
            return Color.white.opacity(0.95)
        }
    }

    private func gradientColors(for scheme: ColorScheme) -> [Color] {
        scheme == .dark ? darkBackgroundColors : backgroundColors
    }

    private var backgroundColors: [Color] {
        switch self {
        case .sunrise:
            return [
                Color(red: 1.00, green: 0.74, blue: 0.22),
                Color(red: 0.98, green: 0.58, blue: 0.16),
            ]
        case .melloYellow:
            return [
                Color(red: 0.341, green: 0.78, blue: 0.522), // #57c785
                Color(red: 0.949, green: 1, blue: 0), // #f2ff00
            ]
        case .ocean:
            return [
                Color(red: 0.21, green: 0.58, blue: 0.90),
                Color(red: 0.02, green: 0.33, blue: 0.60),
            ]
        case .forest:
            return [
                Color(red: 0.33, green: 0.71, blue: 0.47),
                Color(red: 0.11, green: 0.40, blue: 0.24),
            ]
        case .classic:
            return [
                Color(red: 0.749, green: 0.733, blue: 0.733), // #bfbbbb
                Color(red: 0.902, green: 0.902, blue: 0.902), // #e6e6e6
                Color(red: 0.529, green: 0.529, blue: 0.529), // #878787
            ]
        case .oceanDeep:
            return [
                Color(red: 0, green: 0.588, blue: 0.8),
                Color(red: 0.11, green: 1.00, blue: 1.00),
            ]
        case .cosmicPurple:
            return [
                Color(red: 0.50, green: 0.00, blue: 1.00),
                Color(red: 0.88, green: 0.00, blue: 1.00),
            ]
        case .сyberSplash:
            return [
                Color(red: 0.282, green: 0.957, blue: 0.969), // #48f4f7 
                Color(red: 0.878, green: 0.282, blue: 0.969), // #e048f7
            ]
        case .lavaBurst:
            return [
                Color(red: 0.99, green: 0.27, blue: 0.42),
                Color(red: 0.25, green: 0.37, blue: 0.98),
            ]
        case .iceCrystal:
            return [
                Color(red: 0.63, green: 0.77, blue: 0.99),
                Color(red: 0.76, green: 0.91, blue: 0.98),
            ]
        case .coralSunset:
            return [
                Color(red: 1.00, green: 0.60, blue: 0.40),
                Color(red: 1.00, green: 0.37, blue: 0.38),
            ]
        case .auroraGlow:
            return [
                Color(red: 0.00, green: 0.96, blue: 0.63),
                Color(red: 0.00, green: 0.85, blue: 0.96),
            ]
        case .virentia:
            return [
                Color(red: 0.07, green: 0.60, blue: 0.56),
                Color(red: 0.22, green: 0.94, blue: 0.49),
            ]
        case .frescoCrush:
            return [
                Color(red: 1, green: 0.867, blue: 0), // #ffdd00
                Color(red: 0.569, green: 0.259, blue: 0.839), // #9142d6
            ]
        case .pinkNebula:
            return [
                Color(red: 0.97, green: 0.34, blue: 0.65),
                Color(red: 1.00, green: 0.35, blue: 0.35),
            ]
        }
    }

    private var darkBackgroundColors: [Color] {
        switch self {
        case .sunrise:
            return [
                Color(red: 0.60, green: 0.44, blue: 0.13),
                Color(red: 0.59, green: 0.35, blue: 0.10),
            ]
        case .melloYellow:
            return [
                Color(red: 0.20, green: 0.52, blue: 0.39),
                Color(red: 0.72, green: 0.55, blue: 0.10),
            ]
        case .ocean:
            return [
                Color(red: 0.13, green: 0.35, blue: 0.54),
                Color(red: 0.01, green: 0.20, blue: 0.36),
            ]
        case .forest:
            return [
                Color(red: 0.20, green: 0.43, blue: 0.28),
                Color(red: 0.07, green: 0.24, blue: 0.14),
            ]
        case .classic:
            return [
                Color(red: 0.2, green: 0.173, blue: 0.173), // #332c2c
                Color(red: 0.349, green: 0.341, blue: 0.341), // #595757
                Color(red: 0.102, green: 0.102, blue: 0.102), // #1a1a1a
            ]
        case .oceanDeep:
            return [
                Color(red: 0.11, green: 0.11, blue: 0.34),
                Color(red: 0.07, green: 0.60, blue: 0.60),
            ]
        case .cosmicPurple:
            return [
                Color(red: 0.30, green: 0.00, blue: 0.60),
                Color(red: 0.53, green: 0.00, blue: 0.60),
            ]
        case .сyberSplash:
            return [
                Color(red: 0.05, green: 0.42, blue: 0.52),
                Color(red: 0.13, green: 0.14, blue: 0.40),
                Color(red: 0.36, green: 0.10, blue: 0.47),
            ]
        case .lavaBurst:
            return [
                Color(red: 0.59, green: 0.16, blue: 0.25),
                Color(red: 0.15, green: 0.22, blue: 0.59),
            ]
        case .iceCrystal:
            return [
                Color(red: 0.38, green: 0.46, blue: 0.59),
                Color(red: 0.46, green: 0.55, blue: 0.59),
            ]
        case .coralSunset:
            return [
                Color(red: 0.60, green: 0.36, blue: 0.24),
                Color(red: 0.60, green: 0.22, blue: 0.23),
            ]
        case .auroraGlow:
            return [
                Color(red: 0.00, green: 0.58, blue: 0.38),
                Color(red: 0.00, green: 0.51, blue: 0.58),
            ]
        case .virentia:
            return [
                Color(red: 0.04, green: 0.36, blue: 0.34),
                Color(red: 0.13, green: 0.56, blue: 0.29),
            ]
        case .frescoCrush:
            return [
                Color(red: 0.18, green: 0.12, blue: 0.31),
                Color(red: 0.73, green: 0.49, blue: 0.13),
            ]
        case .pinkNebula:
            return [
                Color(red: 0.58, green: 0.20, blue: 0.39),
                Color(red: 0.60, green: 0.21, blue: 0.21),
            ]
        }
    }

    private var circleColors: [Color] {
        switch self {
        case .sunrise:
            return [
                Color(red: 1.00, green: 0.66, blue: 0.20),
                Color(red: 0.98, green: 0.53, blue: 0.13),
            ]
        case .melloYellow:
            return [
                Color(red: 1.00, green: 0.48, blue: 0.18),
                Color(red: 0.98, green: 0.30, blue: 0.14),
            ]
        case .ocean:
            return [
                Color(red: 0.41, green: 0.77, blue: 0.95),
                Color(red: 0.09, green: 0.45, blue: 0.78),
            ]
        case .forest:
            return [
                Color(red: 0.63, green: 0.87, blue: 0.58),
                Color(red: 0.20, green: 0.55, blue: 0.35),
            ]
        case .classic:
            return [
                Color(red: 1.00, green: 0.46, blue: 0.52),
                Color(red: 1.00, green: 0.80, blue: 0.52),
            ]
        case .oceanDeep:
            return [
                Color(red: 0.23, green: 0.33, blue: 0.70),
                Color(red: 0.00, green: 0.85, blue: 0.92),
            ]
        case .cosmicPurple:
            return [
                Color(red: 0.64, green: 0.10, blue: 1.00),
                Color(red: 0.96, green: 0.36, blue: 1.00),
            ]
        case .сyberSplash:
            return [
                Color(red: 0.51, green: 0.94, blue: 0.80),
                Color(red: 0.29, green: 0.85, blue: 0.63),
            ]
        case .lavaBurst:
            return [
                Color(red: 0.98, green: 0.36, blue: 0.52),
                Color(red: 0.32, green: 0.46, blue: 0.99),
            ]
        case .iceCrystal:
            return [
                Color(red: 0.71, green: 0.84, blue: 0.99),
                Color(red: 0.85, green: 0.94, blue: 0.99),
            ]
        case .coralSunset:
            return [
                Color(red: 1.00, green: 0.63, blue: 0.44),
                Color(red: 1.00, green: 0.40, blue: 0.38),
            ]
        case .auroraGlow:
            return [
                Color(red: 0.05, green: 0.98, blue: 0.69),
                Color(red: 0.00, green: 0.80, blue: 0.86),
            ]
        case .virentia:
            return [
                Color(red: 0.12, green: 0.66, blue: 0.58),
                Color(red: 0.31, green: 0.93, blue: 0.58),
            ]
        case .frescoCrush:
            return [
                Color(red: 0.41, green: 0.74, blue: 1.00),
                Color(red: 0.09, green: 0.86, blue: 0.99),
            ]
        case .pinkNebula:
            return [
                Color(red: 0.98, green: 0.45, blue: 0.71),
                Color(red: 1.00, green: 0.45, blue: 0.45),
            ]
        }
    }
}
