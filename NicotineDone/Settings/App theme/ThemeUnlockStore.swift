import Foundation

enum ThemeUnlockStore {
    private static let unlockedThemesKey = "unlockedThemeIds"
    private static let unlockedVersionKey = "unlockedThemesVersion"

    static let baseStyles: Set<DashboardBackgroundStyle> = [
        .classic,
        .oceanDeep,
        .sunrise,
        .virentia
    ]

    static func unlockedStyles() -> Set<DashboardBackgroundStyle> {
        let stored = UserDefaults.standard.array(forKey: unlockedThemesKey) as? [Int] ?? []
        let decoded = stored.compactMap { DashboardBackgroundStyle(rawValue: $0) }
        return baseStyles.union(decoded)
    }

    static func setUnlocked(_ styles: [DashboardBackgroundStyle]) {
        let unique = Array(Set(styles.map(\.rawValue))).sorted()
        let existing = UserDefaults.standard.array(forKey: unlockedThemesKey) as? [Int] ?? []
        if existing != unique {
            UserDefaults.standard.set(unique, forKey: unlockedThemesKey)
            bumpVersion()
        }
    }

    private static func bumpVersion() {
        let value = UserDefaults.standard.integer(forKey: unlockedVersionKey)
        UserDefaults.standard.set(value + 1, forKey: unlockedVersionKey)
    }
}
