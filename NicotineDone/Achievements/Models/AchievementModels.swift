import SwiftUI

enum AchievementRule {
    case abstinenceHours(Int)
    case cleanMorning(count: Int)
    case cleanEvening(count: Int)
    case withinLimitStreak(days: Int)
    case entryStreak(days: Int)
}

struct AchievementItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let cardDescription: String
    let healthBenefit: String
    let medal: MedalStyle
    let rewardTheme: DashboardBackgroundStyle?
    let rule: AchievementRule

    static let catalog: [AchievementItem] = [
        AchievementItem(title: "Чистые утренние часы",
                        subtitle: "Без курения до 12:00",
                        cardDescription: "Свободное утро и лёгкий старт дня.",
                        healthBenefit: "Утренний пульс и давление стабильнее, легче дышать.",
                        medal: .sunrise,
                        rule: .cleanMorning(count: 1)),
        AchievementItem(title: "Чистые вечера",
                        subtitle: "Без курения после 20:00",
                        cardDescription: "Вечер спокойнее и без лишних триггеров.",
                        healthBenefit: "Сон глубже, меньше ночных пробуждений.",
                        medal: .evening,
                        rule: .cleanEvening(count: 1)),
        AchievementItem(title: "Первый чистый день",
                        subtitle: "24 часа без никотина",
                        cardDescription: "Первый день — важная точка опоры.",
                        healthBenefit: "Снижается уровень CO, кровь насыщается кислородом.",
                        medal: .dayOne,
                        rule: .abstinenceHours(24)),
        AchievementItem(title: "В лимите",
                        subtitle: "Неделя без превышения лимита",
                        cardDescription: "Дисциплина и контроль изо дня в день.",
                        healthBenefit: "Меньше нагрузка на сердце и дыхательную систему.",
                        medal: .limit,
                        rule: .withinLimitStreak(days: 7)),
        AchievementItem(title: "Я всё ещё здесь",
                        subtitle: "7 дней подряд с приложением",
                        cardDescription: "Неделя стабильного ритма и внимания к себе.",
                        healthBenefit: "Устойчивый ритм помогает мозгу снижать тягу.",
                        medal: .streak,
                        rule: .entryStreak(days: 7)),
        AchievementItem(title: "Лёгкие утра",
                        subtitle: "3 утра без никотина до 12:00",
                        cardDescription: "Три спокойных утра — сильный старт.",
                        healthBenefit: "Лёгкие очищаются активнее, дыхание ровнее.",
                        medal: .morning,
                        rule: .cleanMorning(count: 3)),
        AchievementItem(title: "6 часов контроля",
                        subtitle: "6 часов без никотина",
                        cardDescription: "Первый устойчивый отрезок в твою пользу.",
                        healthBenefit: "Снижается частота позывов, появляется контроль.",
                        medal: .bronze,
                        rewardTheme: .coralSunset,
                        rule: .abstinenceHours(6)),
        AchievementItem(title: "9 часов без никотина",
                        subtitle: "9 часов без никотина",
                        cardDescription: "Тяга слабеет, ты держишь темп.",
                        healthBenefit: "Организм начинает стабилизировать уровень кислорода.",
                        medal: .bronze,
                        rewardTheme: .melloYellow,
                        rule: .abstinenceHours(9)),
        AchievementItem(title: "12 часов осознанности",
                        subtitle: "12 часов без никотина",
                        cardDescription: "Половина суток под твоим контролем.",
                        healthBenefit: "Пульс и давление ближе к норме.",
                        medal: .silver,
                        rewardTheme: .ocean,
                        rule: .abstinenceHours(12)),
        AchievementItem(title: "15 часов выбора",
                        subtitle: "15 часов без никотина",
                        cardDescription: "Ты сохраняешь фокус и продолжаешь.",
                        healthBenefit: "Снижается раздражительность, внимание яснее.",
                        medal: .silver,
                        rewardTheme: .forest,
                        rule: .abstinenceHours(15)),
        AchievementItem(title: "18 часов устойчивости",
                        subtitle: "18 часов без никотина",
                        cardDescription: "Организм адаптируется, устойчивость растёт.",
                        healthBenefit: "Улучшается циркуляция крови.",
                        medal: .silver,
                        rewardTheme: .cosmicPurple,
                        rule: .abstinenceHours(18)),
        AchievementItem(title: "24 часа свободы",
                        subtitle: "24 часа без никотина",
                        cardDescription: "Сутки свободы — серьёзный рубеж.",
                        healthBenefit: "Риск сердечного приступа начинает снижаться.",
                        medal: .gold,
                        rewardTheme: .pinkNebula,
                        rule: .abstinenceHours(24)),
        AchievementItem(title: "30 часов уверенности",
                        subtitle: "30 часов без никотина",
                        cardDescription: "Уверенность крепнет с каждым часом.",
                        healthBenefit: "Организм активнее выводит продукты распада.",
                        medal: .gold,
                        rewardTheme: .auroraGlow,
                        rule: .abstinenceHours(30)),
        AchievementItem(title: "36 часов восстановления",
                        subtitle: "36 часов без никотина",
                        cardDescription: "Тело перестраивается на новый ритм.",
                        healthBenefit: "Обоняние и вкус становятся ярче.",
                        medal: .gold,
                        rewardTheme: .lavaBurst,
                        rule: .abstinenceHours(36)),
        AchievementItem(title: "42 часа фокуса",
                        subtitle: "42 часа без никотина",
                        cardDescription: "Фокус на здоровье становится сильнее.",
                        healthBenefit: "Лёгкие постепенно избавляются от слизи.",
                        medal: .platinum,
                        rewardTheme: .iceCrystal,
                        rule: .abstinenceHours(42)),
        AchievementItem(title: "48 часов без никотина",
                        subtitle: "48 часов без никотина",
                        cardDescription: "Два дня подряд — серьёзный шаг.",
                        healthBenefit: "Нервные окончания восстанавливаются.",
                        medal: .platinum,
                        rewardTheme: .frescoCrush,
                        rule: .abstinenceHours(48)),
        AchievementItem(title: "60 часов контроля",
                        subtitle: "60 часов без никотина",
                        cardDescription: "Почти 2,5 дня устойчивого контроля.",
                        healthBenefit: "Дыхание глубже, выносливость выше.",
                        medal: .platinum,
                        rewardTheme: .сyberSplash,
                        rule: .abstinenceHours(60)),
        AchievementItem(title: "72 часа свободы",
                        subtitle: "72 часа без никотина",
                        cardDescription: "Три дня — привычка уже ослабевает.",
                        healthBenefit: "Лёгкие заметно очищаются, кашель уменьшается.",
                        medal: .diamond,
                        rewardTheme: .oceanDeep,
                        rule: .abstinenceHours(72)),
        AchievementItem(title: "84 часа устойчивости",
                        subtitle: "84 часа без никотина",
                        cardDescription: "Устойчивость растёт и становится заметной.",
                        healthBenefit: "Снижается зависимость, стабильнее настроение.",
                        medal: .diamond,
                        rule: .abstinenceHours(84)),
        AchievementItem(title: "96 часов ясности",
                        subtitle: "96 часов без никотина",
                        cardDescription: "Четыре дня ясного выбора.",
                        healthBenefit: "Кровообращение улучшается, больше энергии.",
                        medal: .diamond,
                        rule: .abstinenceHours(96)),
        AchievementItem(title: "108 часов спокойствия",
                        subtitle: "108 часов без никотина",
                        cardDescription: "Новая норма формируется день за днём.",
                        healthBenefit: "Сон глубже, меньше тревожности.",
                        medal: .aurora,
                        rule: .abstinenceHours(108)),
        AchievementItem(title: "180 часов осознанности",
                        subtitle: "180 часов без никотина",
                        cardDescription: "Больше недели стабильности и уверенности.",
                        healthBenefit: "Сердечно‑сосудистая нагрузка ниже.",
                        medal: .aurora,
                        rule: .abstinenceHours(180)),
        AchievementItem(title: "192 часа устойчивости",
                        subtitle: "192 часа без никотина",
                        cardDescription: "Сильная серия и уверенный прогресс.",
                        healthBenefit: "Устойчивость к триггерам заметно выше.",
                        medal: .aurora,
                        rule: .abstinenceHours(192)),
        AchievementItem(title: "200 часов свободы",
                        subtitle: "200 часов без никотина",
                        cardDescription: "Новая привычка закрепляется уверенно.",
                        healthBenefit: "Формируется новая привычка без никотина.",
                        medal: .aurora,
                        rule: .abstinenceHours(200))
    ]

    init(title: String,
         subtitle: String,
         cardDescription: String,
         healthBenefit: String,
         medal: MedalStyle,
         rewardTheme: DashboardBackgroundStyle? = nil,
         rule: AchievementRule) {
        self.title = title
        self.subtitle = subtitle
        self.cardDescription = cardDescription
        self.healthBenefit = healthBenefit
        self.medal = medal
        self.rewardTheme = rewardTheme
        self.rule = rule
    }
}

extension AchievementItem {
    func isAchieved(using state: AchievementState) -> Bool {
        switch rule {
        case .abstinenceHours(let hours):
            return state.bestAbstinenceInterval >= Double(hours) * 3600
        case .cleanMorning(let count):
            return state.cleanMorningCount >= count
        case .cleanEvening(let count):
            return state.cleanEveningCount >= count
        case .withinLimitStreak(let days):
            return state.withinLimitBestStreak >= days
        case .entryStreak(let days):
            return state.bestEntryStreak >= days
        }
    }

    var isStreakRelated: Bool {
        switch rule {
        case .withinLimitStreak, .entryStreak:
            return false
        case .abstinenceHours(let hours):
            return hours >= 6 && hours <= 200
        case .cleanMorning, .cleanEvening:
            return false
        }
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
