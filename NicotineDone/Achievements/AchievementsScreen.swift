import SwiftUI
import CoreData

struct AchievementsScreen: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var user: User

    @State private var achievements: [UserAchievement] = []

    var body: some View {
        List {
            ForEach(achievements) { userAchievement in
                AchievementRow(userAchievement: userAchievement)
            }
        }
        .navigationTitle("Achievements")
        .onAppear(perform: load)
    }

    private func load() {
        let request: NSFetchRequest<UserAchievement> = UserAchievement.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@", user)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \UserAchievement.achievedAt, ascending: false),
            NSSortDescriptor(keyPath: \UserAchievement.progress, ascending: false)
        ]
        achievements = (try? context.fetch(request)) ?? []
    }
}

private struct AchievementRow: View {
    @ObservedObject var userAchievement: UserAchievement

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: userAchievement.achievement?.icon ?? "star")
                .font(.title2)
                .frame(width: 36, height: 36)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 4) {
                Text(userAchievement.achievement?.title ?? "Achievement")
                    .font(.headline)
                Text(userAchievement.achievement?.descText ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgressView(value: progressRatio)
                    .progressViewStyle(.linear)
                    .tint(userAchievement.achievedAt == nil ? .accentColor : .green)
            }

            Spacer()

            if let achievedAt = userAchievement.achievedAt {
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text(dateString(from: achievedAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(String(format: "%.0f%%", progressRatio * 100))
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private var progressRatio: Double {
        guard let threshold = userAchievement.achievement?.threshold, threshold > 0 else { return 0 }
        return min(1.0, Double(userAchievement.progress) / Double(threshold))
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    if let user = try? PersistenceController.preview.container.viewContext.fetch(User.fetchRequest()).first {
        AchievementsScreen(user: user)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppViewModel(context: PersistenceController.preview.container.viewContext))
    }
}
