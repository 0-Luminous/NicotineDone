import SwiftUI
import CoreData

struct AchievementsScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var user: User
    @StateObject private var viewModel: AchievementsViewModel

    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false
    @State private var selectedAchievement: AchievementItem?
    @State private var isStreakStackExpanded = false

    init(user: User, environment: AppEnvironment) {
        self.user = user
        _viewModel = StateObject(wrappedValue: AchievementsViewModel(user: user, environment: environment))
    }

    var body: some View {
        ZStack {
            backgroundStyle.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    ForEach(nonStreakAchievements) { achievement in
                        let isAchieved = achievement.isAchieved(using: viewModel.achievementState)
                        AchievementCard(item: achievement,
                                        primaryTextColor: primaryTextColor,
                                        isAchieved: isAchieved,
                                        onTap: { selectedAchievement = achievement })
                    }

                    streakStack
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            ensureAppearanceMigration()
            viewModel.refresh()
        }
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

    var sortedAchievements: [AchievementItem] {
        viewModel.achievements.sorted {
            let left = $0.isAchieved(using: viewModel.achievementState)
            let right = $1.isAchieved(using: viewModel.achievementState)
            if left != right {
                return left && !right
            }
            return $0.title < $1.title
        }
    }

    var nonStreakAchievements: [AchievementItem] {
        sortedAchievements.filter { !$0.isStreakRelated }
    }

    var streakAchievements: [AchievementItem] {
        viewModel.achievements.filter { $0.isStreakRelated }.sorted {
            let left = $0.isAchieved(using: viewModel.achievementState)
            let right = $1.isAchieved(using: viewModel.achievementState)
            if left != right {
                return left && !right
            }
            let leftHours = streakHours(for: $0)
            let rightHours = streakHours(for: $1)
            if leftHours != rightHours {
                return leftHours < rightHours
            }
            return $0.title < $1.title
        }
    }

    var streakStack: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isStreakStackExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Стрики")
                            .font(.headline)
                            .foregroundStyle(primaryTextColor)
                        Text(streakProgressText)
                            .font(.subheadline)
                            .foregroundStyle(primaryTextColor.opacity(0.6))
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(primaryTextColor.opacity(0.7))
                        .rotationEffect(.degrees(isStreakStackExpanded ? 180 : 0))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.clear, in: .rect(cornerRadius: 20))
                .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .haptic()

            if isStreakStackExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(streakAchievements) { achievement in
                        let isAchieved = achievement.isAchieved(using: viewModel.achievementState)
                        AchievementCard(item: achievement,
                                        primaryTextColor: primaryTextColor,
                                        isAchieved: isAchieved,
                                        onTap: { selectedAchievement = achievement })
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    var streakProgressText: String {
        let achieved = streakAchievements.filter { $0.isAchieved(using: viewModel.achievementState) }.count
        return "Выполнено \(achieved) из \(streakAchievements.count)"
    }

    func ensureAppearanceMigration() {
        guard !appearanceStylesMigrated else { return }
        backgroundIndexLight = legacyBackgroundIndex
        backgroundIndexDark = legacyBackgroundIndex
        appearanceStylesMigrated = true
    }

    func streakHours(for achievement: AchievementItem) -> Int {
        if case let .abstinenceHours(hours) = achievement.rule {
            return hours
        }
        return .max
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
        AchievementsScreen(user: user, environment: AppEnvironment.preview)
            .environment(\.appEnvironment, AppEnvironment.preview)
            .environmentObject(AppViewModel(environment: AppEnvironment.preview))
    }
}
