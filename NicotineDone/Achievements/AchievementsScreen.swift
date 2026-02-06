import SwiftUI
import CoreData

struct AchievementsScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var user: User

    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false

    private let achievements: [AchievementItem] = [
        AchievementItem(title: "Чистые утренние часы", subtitle: "Без курения до 12:00", medal: .sunrise),
        AchievementItem(title: "Чистые вечера", subtitle: "Без курения после 20:00", medal: .evening),
        AchievementItem(title: "Первый чистый день", subtitle: "24 часа без никотина", medal: .dayOne),
        AchievementItem(title: "В лимите", subtitle: "Дни без превышения лимита", medal: .limit),
        AchievementItem(title: "Я всё ещё здесь", subtitle: "7 дней подряд с приложением", medal: .streak),
        AchievementItem(title: "Лёгкие утра", subtitle: "3 утра без никотина", medal: .morning),
        AchievementItem(title: "6 часов контроля", subtitle: "Первый устойчивый промежуток", medal: .bronze, rewardTheme: .coralSunset),
        AchievementItem(title: "9 часов без никотина", subtitle: "Тяга уже не рулит", medal: .bronze, rewardTheme: .melloYellow),
        AchievementItem(title: "12 часов осознанности", subtitle: "Половина суток без привычки", medal: .silver, rewardTheme: .ocean),
        AchievementItem(title: "15 часов выбора", subtitle: "Ты продолжаешь", medal: .silver, rewardTheme: .forest),
        AchievementItem(title: "18 часов устойчивости", subtitle: "Тело адаптируется", medal: .silver, rewardTheme: .cosmicPurple),
        AchievementItem(title: "24 часа свободы", subtitle: "Первые сутки без никотина", medal: .gold, rewardTheme: .pinkNebula),
        AchievementItem(title: "30 часов уверенности", subtitle: "Ты прошёл сложный этап", medal: .gold, rewardTheme: .auroraGlow),
        AchievementItem(title: "36 часов восстановления", subtitle: "Организм перестраивается", medal: .gold, rewardTheme: .lavaBurst),
        AchievementItem(title: "42 часа фокуса", subtitle: "Привычка ослабевает", medal: .platinum, rewardTheme: .iceCrystal),
        AchievementItem(title: "48 часов без никотина", subtitle: "Серьёзный шаг вперёд", medal: .platinum, rewardTheme: .frescoCrush),
        AchievementItem(title: "60 часов контроля", subtitle: "Почти 2,5 дня", medal: .platinum, rewardTheme: .сyberSplash),
        AchievementItem(title: "72 часа свободы", subtitle: "Три дня подряд", medal: .diamond, rewardTheme: .oceanDeep),
        AchievementItem(title: "84 часа устойчивости", subtitle: "Тяга заметно слабее", medal: .diamond),
        AchievementItem(title: "96 часов ясности", subtitle: "Четыре дня выбора", medal: .diamond),
        AchievementItem(title: "108 часов спокойствия", subtitle: "Новая норма формируется", medal: .aurora),
        AchievementItem(title: "180 часов осознанности", subtitle: "Больше недели", medal: .aurora),
        AchievementItem(title: "192 часа устойчивости", subtitle: "8 дней подряд", medal: .aurora),
        AchievementItem(title: "200 часов свободы", subtitle: "Ты реально изменил паттерн", medal: .aurora)
    ]

    var body: some View {
        ZStack {
            backgroundStyle.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    ForEach(achievements) { achievement in
                        AchievementCard(item: achievement, primaryTextColor: primaryTextColor)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
        .onAppear(perform: ensureAppearanceMigration)
    }
}

private extension AchievementsScreen {
    var backgroundStyle: DashboardBackgroundStyle {
        let index = colorScheme == .dark ? backgroundIndexDark : backgroundIndexLight
        return DashboardBackgroundStyle(rawValue: index) ?? DashboardBackgroundStyle.default(for: colorScheme)
    }

    var primaryTextColor: Color {
        backgroundStyle.primaryTextColor(for: colorScheme)
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Achievements")
                .font(.title2.weight(.bold))
                .foregroundStyle(primaryTextColor)
            Text("Отмечай прогресс и открывай новые вехи.")
                .font(.callout)
                .foregroundStyle(primaryTextColor.opacity(0.75))
        }
    }

    func ensureAppearanceMigration() {
        guard !appearanceStylesMigrated else { return }
        backgroundIndexLight = legacyBackgroundIndex
        backgroundIndexDark = legacyBackgroundIndex
        appearanceStylesMigrated = true
    }
}

private struct AchievementItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let medal: MedalStyle
    let rewardTheme: DashboardBackgroundStyle?

    init(title: String, subtitle: String, medal: MedalStyle, rewardTheme: DashboardBackgroundStyle? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.medal = medal
        self.rewardTheme = rewardTheme
    }
}

private struct AchievementCard: View {
    let item: AchievementItem
    let primaryTextColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            MedalBadgeView(style: item.medal)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(primaryTextColor)
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(primaryTextColor.opacity(0.7))
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .glassEffect(.clear, in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
        .overlay(alignment: .bottomTrailing) {
            if let rewardTheme = item.rewardTheme {
                ThemeRewardBadge(style: rewardTheme, primaryTextColor: primaryTextColor)
                    .padding(12)
            }
        }
    }
}

private struct ThemeRewardBadge: View {
    let style: DashboardBackgroundStyle
    let primaryTextColor: Color

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(style.previewGradient(for: .dark))
                .frame(width: 44, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Награда")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(primaryTextColor.opacity(0.85))
                Text("Тема \(style.name)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(primaryTextColor)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

private enum MedalStyle: CaseIterable {
    case bronze
    case silver
    case gold
    case platinum
    case diamond
    case sunrise
    case evening
    case dayOne
    case limit
    case streak
    case morning
    case aurora

    var gradient: LinearGradient {
        switch self {
        case .bronze:
            return LinearGradient(colors: [Color(hex: "#C47A3B"), Color(hex: "#9B4F1E")],
                                  startPoint: .topLeading,
                                  endPoint: .bottomTrailing)
        case .silver:
            return LinearGradient(colors: [Color(hex: "#E5E7EB"), Color(hex: "#9CA3AF")],
                                  startPoint: .topLeading,
                                  endPoint: .bottomTrailing)
        case .gold:
            return LinearGradient(colors: [Color(hex: "#FFD56A"), Color(hex: "#E09C1B")],
                                  startPoint: .topLeading,
                                  endPoint: .bottomTrailing)
        case .platinum:
            return LinearGradient(colors: [Color(hex: "#B8F3FF"), Color(hex: "#6BC7FF")],
                                  startPoint: .topLeading,
                                  endPoint: .bottomTrailing)
        case .diamond:
            return LinearGradient(colors: [Color(hex: "#9AE6FF"), Color(hex: "#5C6CFF")],
                                  startPoint: .topLeading,
                                  endPoint: .bottomTrailing)
        case .sunrise:
            return LinearGradient(colors: [Color(hex: "#FFB15A"), Color(hex: "#FF6B5A")],
                                  startPoint: .topLeading,
                                  endPoint: .bottomTrailing)
        case .evening:
            return LinearGradient(colors: [Color(hex: "#7B61FF"), Color(hex: "#3B1F78")],
                                  startPoint: .topLeading,
                                  endPoint: .bottomTrailing)
        case .dayOne:
            return LinearGradient(colors: [Color(hex: "#66E2FF"), Color(hex: "#2D7BFF")],
                                  startPoint: .topLeading,
                                  endPoint: .bottomTrailing)
        case .limit:
            return LinearGradient(colors: [Color(hex: "#7ED957"), Color(hex: "#3E7A2F")],
                                  startPoint: .topLeading,
                                  endPoint: .bottomTrailing)
        case .streak:
            return LinearGradient(colors: [Color(hex: "#FF7A7A"), Color(hex: "#C43A3A")],
                                  startPoint: .topLeading,
                                  endPoint: .bottomTrailing)
        case .morning:
            return LinearGradient(colors: [Color(hex: "#FFE08A"), Color(hex: "#FF9B54")],
                                  startPoint: .topLeading,
                                  endPoint: .bottomTrailing)
        case .aurora:
            return LinearGradient(colors: [Color(hex: "#6EE7B7"), Color(hex: "#3B82F6")],
                                  startPoint: .topLeading,
                                  endPoint: .bottomTrailing)
        }
    }

    var ribbonColor: Color {
        switch self {
        case .bronze: return Color(hex: "#8C4A1E")
        case .silver: return Color(hex: "#7C8AA5")
        case .gold: return Color(hex: "#D48806")
        case .platinum: return Color(hex: "#5BA5D6")
        case .diamond: return Color(hex: "#3B6BFF")
        case .sunrise: return Color(hex: "#FF8C4B")
        case .evening: return Color(hex: "#4C2A85")
        case .dayOne: return Color(hex: "#2D7BFF")
        case .limit: return Color(hex: "#2E6B27")
        case .streak: return Color(hex: "#B83939")
        case .morning: return Color(hex: "#FFB15A")
        case .aurora: return Color(hex: "#1FAF8C")
        }
    }

    var glyph: String {
        switch self {
        case .sunrise, .morning: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        case .dayOne: return "sparkles"
        case .limit: return "gauge.with.dots.needle.50percent"
        case .streak: return "flame.fill"
        case .bronze, .silver, .gold, .platinum, .diamond, .aurora:
            return "medal.fill"
        }
    }
}

private struct MedalBadgeView: View {
    let style: MedalStyle

    var body: some View {
        ZStack {
            RibbonShape()
                .fill(style.ribbonColor)
                .frame(width: 34, height: 22)
                .offset(y: -14)

            Circle()
                .fill(style.gradient)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)

            Image(systemName: style.glyph)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 2)
        }
        .frame(width: 48, height: 56)
    }
}

private struct RibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: midX + rect.width * 0.2, y: rect.maxY))
        path.addLine(to: CGPoint(x: midX, y: rect.maxY - rect.height * 0.25))
        path.addLine(to: CGPoint(x: midX - rect.width * 0.2, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    if let user = try? PersistenceController.preview.container.viewContext.fetch(User.fetchRequest()).first {
        AchievementsScreen(user: user)
            .environmentObject(AppViewModel(context: PersistenceController.preview.container.viewContext))
    }
}
