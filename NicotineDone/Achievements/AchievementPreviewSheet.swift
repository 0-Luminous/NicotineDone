import SwiftUI

struct AchievementPreviewSheet: View {
    let item: AchievementItem
    let primaryTextColor: Color
    let backgroundStyle: DashboardBackgroundStyle

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header
                detailsCard
                healthSection
                rewardSection
                Spacer(minLength: 4)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.clear.ignoresSafeArea())
        .presentationDetents([.fraction(0.6)])
    }

    private var header: some View {
        HStack(spacing: 12) {
            MedalBadgeView(style: item.medal)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(primaryTextColor)
                Text("Достижение")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(primaryTextColor.opacity(0.6))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Задача")
                .font(.caption.weight(.semibold))
                .foregroundStyle(primaryTextColor.opacity(0.6))
            Text(item.subtitle)
                .font(.body.weight(.semibold))
                .foregroundStyle(primaryTextColor)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.clear, in: .rect(cornerRadius: 18))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 6)
    }

    private var rewardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Награда")
                .font(.caption.weight(.semibold))
                .foregroundStyle(primaryTextColor.opacity(0.6))
            if let rewardTheme = item.rewardTheme {
                ThemeRewardBadge(style: rewardTheme, primaryTextColor: primaryTextColor)
            } else {
                Text("Награда пока не назначена")
                    .font(.subheadline)
                    .foregroundStyle(primaryTextColor.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Польза для здоровья")
                .font(.caption.weight(.semibold))
                .foregroundStyle(primaryTextColor.opacity(0.6))
            Text(item.healthBenefit)
                .font(.body.weight(.semibold))
                .foregroundStyle(primaryTextColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.clear, in: .rect(cornerRadius: 18))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 6)
    }
}

private struct ThemeRewardBadge: View {
    let style: DashboardBackgroundStyle
    let primaryTextColor: Color

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(style.previewGradient(for: .light))
                .frame(width: 72, height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text("Награда")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(primaryTextColor.opacity(0.7))
                Text("Тема \(style.name)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryTextColor)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 8)
    }
}
