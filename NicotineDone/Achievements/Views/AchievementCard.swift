import SwiftUI

struct AchievementCard: View {
    let item: AchievementItem
    let primaryTextColor: Color
    let isAchieved: Bool
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
                    .saturation(isAchieved ? 1 : 0.15)
                    .opacity(isAchieved ? 1 : 0.65)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(primaryTextColor.opacity(isAchieved ? 1 : 0.7))
                    Text(item.cardDescription)
                        .font(.subheadline)
                        .foregroundStyle(primaryTextColor.opacity(isAchieved ? 0.7 : 0.45))
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
