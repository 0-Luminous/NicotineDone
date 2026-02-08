import CoreData

protocol AchievementRepository {
    func fetchAchievement(code: String) -> Achievement?
    func createAchievement(code: String,
                           title: String,
                           description: String,
                           icon: String,
                           threshold: Int64,
                           kind: AchievementKind) -> Achievement
    func fetchUserAchievement(user: User, achievement: Achievement) -> UserAchievement?
    func createUserAchievement(user: User, achievement: Achievement) -> UserAchievement
}

final class CoreDataAchievementRepository: AchievementRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchAchievement(code: String) -> Achievement? {
        let request: NSFetchRequest<Achievement> = Achievement.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "code == %@", code)
        return try? context.fetch(request).first
    }

    func createAchievement(code: String,
                           title: String,
                           description: String,
                           icon: String,
                           threshold: Int64,
                           kind: AchievementKind) -> Achievement {
        let achievement = Achievement(context: context)
        achievement.id = UUID()
        achievement.code = code
        achievement.title = title
        achievement.descText = description
        achievement.icon = icon
        achievement.threshold = threshold
        achievement.kind = kind.rawValue
        return achievement
    }

    func fetchUserAchievement(user: User, achievement: Achievement) -> UserAchievement? {
        let request: NSFetchRequest<UserAchievement> = UserAchievement.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "user == %@ AND achievement == %@", user, achievement)
        return try? context.fetch(request).first
    }

    func createUserAchievement(user: User, achievement: Achievement) -> UserAchievement {
        let ua = UserAchievement(context: context)
        ua.id = UUID()
        ua.user = user
        ua.achievement = achievement
        ua.progress = 0
        return ua
    }
}
