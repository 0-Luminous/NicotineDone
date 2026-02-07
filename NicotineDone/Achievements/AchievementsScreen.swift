import SwiftUI
import CoreData

struct AchievementsScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var user: User

    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false
    @State private var selectedAchievement: AchievementItem?

    private let achievements: [AchievementItem] = AchievementItem.catalog

    var body: some View {
        ZStack {
            backgroundStyle.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    ForEach(achievements) { achievement in
                        AchievementCard(item: achievement,
                                        primaryTextColor: primaryTextColor,
                                        onTap: { selectedAchievement = achievement })
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
        .onAppear(perform: ensureAppearanceMigration)
        .sheet(item: $selectedAchievement) { achievement in
            AchievementPreviewSheet(item: achievement,
                                    primaryTextColor: primaryTextColor,
                                    backgroundStyle: backgroundStyle)
                .presentationBackground(.clear)
        }
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
            Text("View your progress and unlocked badges.")
                .font(.callout)
                .foregroundStyle(primaryTextColor.opacity(0.75))
        }
        .padding(.bottom, 8)
    }

    func ensureAppearanceMigration() {
        guard !appearanceStylesMigrated else { return }
        backgroundIndexLight = legacyBackgroundIndex
        backgroundIndexDark = legacyBackgroundIndex
        appearanceStylesMigrated = true
    }
}

struct AchievementItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let cardDescription: String
    let healthBenefit: String
    let medal: MedalStyle
    let rewardTheme: DashboardBackgroundStyle?
    static let catalog: [AchievementItem] = [
        AchievementItem(title: "Чистые утренние часы",
                        subtitle: "Без курения до 12:00",
                        cardDescription: "Свободное утро и лёгкий старт дня.",
                        healthBenefit: "Утренний пульс и давление стабильнее, легче дышать.",
                        medal: .sunrise),
        AchievementItem(title: "Чистые вечера",
                        subtitle: "Без курения после 20:00",
                        cardDescription: "Вечер спокойнее и без лишних триггеров.",
                        healthBenefit: "Сон глубже, меньше ночных пробуждений.",
                        medal: .evening),
        AchievementItem(title: "Первый чистый день",
                        subtitle: "24 часа без никотина",
                        cardDescription: "Первый день — важная точка опоры.",
                        healthBenefit: "Снижается уровень CO, кровь насыщается кислородом.",
                        medal: .dayOne),
        AchievementItem(title: "В лимите",
                        subtitle: "Неделя без превышения лимита",
                        cardDescription: "Дисциплина и контроль изо дня в день.",
                        healthBenefit: "Меньше нагрузка на сердце и дыхательную систему.",
                        medal: .limit),
        AchievementItem(title: "Я всё ещё здесь",
                        subtitle: "7 дней подряд с приложением",
                        cardDescription: "Неделя стабильного ритма и внимания к себе.",
                        healthBenefit: "Устойчивый ритм помогает мозгу снижать тягу.",
                        medal: .streak),
        AchievementItem(title: "Лёгкие утра",
                        subtitle: "3 утра без никотина до 12:00",
                        cardDescription: "Три спокойных утра — сильный старт.",
                        healthBenefit: "Лёгкие очищаются активнее, дыхание ровнее.",
                        medal: .morning),
        AchievementItem(title: "6 часов контроля",
                        subtitle: "6 часов без никотина",
                        cardDescription: "Первый устойчивый отрезок в твою пользу.",
                        healthBenefit: "Снижается частота позывов, появляется контроль.",
                        medal: .bronze,
                        rewardTheme: .coralSunset),
        AchievementItem(title: "9 часов без никотина",
                        subtitle: "9 часов без никотина",
                        cardDescription: "Тяга слабеет, ты держишь темп.",
                        healthBenefit: "Организм начинает стабилизировать уровень кислорода.",
                        medal: .bronze,
                        rewardTheme: .melloYellow),
        AchievementItem(title: "12 часов осознанности",
                        subtitle: "12 часов без никотина",
                        cardDescription: "Половина суток под твоим контролем.",
                        healthBenefit: "Пульс и давление ближе к норме.",
                        medal: .silver,
                        rewardTheme: .ocean),
        AchievementItem(title: "15 часов выбора",
                        subtitle: "15 часов без никотина",
                        cardDescription: "Ты сохраняешь фокус и продолжаешь.",
                        healthBenefit: "Снижается раздражительность, внимание яснее.",
                        medal: .silver,
                        rewardTheme: .forest),
        AchievementItem(title: "18 часов устойчивости",
                        subtitle: "18 часов без никотина",
                        cardDescription: "Организм адаптируется, устойчивость растёт.",
                        healthBenefit: "Улучшается циркуляция крови.",
                        medal: .silver,
                        rewardTheme: .cosmicPurple),
        AchievementItem(title: "24 часа свободы",
                        subtitle: "24 часа без никотина",
                        cardDescription: "Сутки свободы — серьёзный рубеж.",
                        healthBenefit: "Риск сердечного приступа начинает снижаться.",
                        medal: .gold,
                        rewardTheme: .pinkNebula),
        AchievementItem(title: "30 часов уверенности",
                        subtitle: "30 часов без никотина",
                        cardDescription: "Уверенность крепнет с каждым часом.",
                        healthBenefit: "Организм активнее выводит продукты распада.",
                        medal: .gold,
                        rewardTheme: .auroraGlow),
        AchievementItem(title: "36 часов восстановления",
                        subtitle: "36 часов без никотина",
                        cardDescription: "Тело перестраивается на новый ритм.",
                        healthBenefit: "Обоняние и вкус становятся ярче.",
                        medal: .gold,
                        rewardTheme: .lavaBurst),
        AchievementItem(title: "42 часа фокуса",
                        subtitle: "42 часа без никотина",
                        cardDescription: "Фокус на здоровье становится сильнее.",
                        healthBenefit: "Лёгкие постепенно избавляются от слизи.",
                        medal: .platinum,
                        rewardTheme: .iceCrystal),
        AchievementItem(title: "48 часов без никотина",
                        subtitle: "48 часов без никотина",
                        cardDescription: "Два дня подряд — серьёзный шаг.",
                        healthBenefit: "Нервные окончания восстанавливаются.",
                        medal: .platinum,
                        rewardTheme: .frescoCrush),
        AchievementItem(title: "60 часов контроля",
                        subtitle: "60 часов без никотина",
                        cardDescription: "Почти 2,5 дня устойчивого контроля.",
                        healthBenefit: "Дыхание глубже, выносливость выше.",
                        medal: .platinum,
                        rewardTheme: .сyberSplash),
        AchievementItem(title: "72 часа свободы",
                        subtitle: "72 часа без никотина",
                        cardDescription: "Три дня — привычка уже ослабевает.",
                        healthBenefit: "Лёгкие заметно очищаются, кашель уменьшается.",
                        medal: .diamond,
                        rewardTheme: .oceanDeep),
        AchievementItem(title: "84 часа устойчивости",
                        subtitle: "84 часа без никотина",
                        cardDescription: "Устойчивость растёт и становится заметной.",
                        healthBenefit: "Снижается зависимость, стабильнее настроение.",
                        medal: .diamond),
        AchievementItem(title: "96 часов ясности",
                        subtitle: "96 часов без никотина",
                        cardDescription: "Четыре дня ясного выбора.",
                        healthBenefit: "Кровообращение улучшается, больше энергии.",
                        medal: .diamond),
        AchievementItem(title: "108 часов спокойствия",
                        subtitle: "108 часов без никотина",
                        cardDescription: "Новая норма формируется день за днём.",
                        healthBenefit: "Сон глубже, меньше тревожности.",
                        medal: .aurora),
        AchievementItem(title: "180 часов осознанности",
                        subtitle: "180 часов без никотина",
                        cardDescription: "Больше недели стабильности и уверенности.",
                        healthBenefit: "Сердечно‑сосудистая нагрузка ниже.",
                        medal: .aurora),
        AchievementItem(title: "192 часа устойчивости",
                        subtitle: "192 часа без никотина",
                        cardDescription: "Сильная серия и уверенный прогресс.",
                        healthBenefit: "Устойчивость к триггерам заметно выше.",
                        medal: .aurora),
        AchievementItem(title: "200 часов свободы",
                        subtitle: "200 часов без никотина",
                        cardDescription: "Новая привычка закрепляется уверенно.",
                        healthBenefit: "Формируется новая привычка без никотина.",
                        medal: .aurora)
    ]

    init(title: String,
         subtitle: String,
         cardDescription: String,
         healthBenefit: String,
         medal: MedalStyle,
         rewardTheme: DashboardBackgroundStyle? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.cardDescription = cardDescription
        self.healthBenefit = healthBenefit
        self.medal = medal
        self.rewardTheme = rewardTheme
    }
}

private struct AchievementCard: View {
    let item: AchievementItem
    let primaryTextColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            frontSide
        }
        .buttonStyle(.plain)
    }

    private var frontSide: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 14) {
                MedalBadgeView(style: item.medal)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(primaryTextColor)
                    Text(item.cardDescription)
                        .font(.subheadline)
                        .foregroundStyle(primaryTextColor.opacity(0.7))
                }

                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.clear, in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
    }
}

enum MedalStyle: CaseIterable {
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

struct MedalBadgeView: View {
    let style: MedalStyle

    var body: some View {
        ZStack {
            RibbonShape()
                .fill(style.ribbonColor)
                .frame(width: 42, height: 26)
                .offset(y: -18)

            Circle()
                .fill(style.gradient)
                .frame(width: 56, height: 56)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 5)

            Image(systemName: style.glyph)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 2)
        }
        .frame(width: 64, height: 72)
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
