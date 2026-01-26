import Foundation

struct SavedMethodsStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let key = "settings.saved.methods"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadProfiles() -> [NicotineProfile] {
        guard let data = defaults.data(forKey: key),
              let profiles = try? decoder.decode([NicotineProfile].self, from: data) else {
            return []
        }
        return profiles
    }

    func save(profile: NicotineProfile) {
        var profiles = loadProfiles()
        profiles.removeAll { $0.method == profile.method }
        profiles.insert(profile, at: 0)
        persist(profiles)
    }

    func mergeLatestOnboardingProfile(_ profile: NicotineProfile?) -> [NicotineProfile] {
        var profiles = loadProfiles()
        if let profile {
            profiles.removeAll { $0.method == profile.method }
            profiles.insert(profile, at: 0)
            persist(profiles)
        }
        return profiles
    }

    func delete(method: NicotineMethod) {
        var profiles = loadProfiles()
        profiles.removeAll { $0.method == method }
        persist(profiles)
    }

    private func persist(_ profiles: [NicotineProfile]) {
        guard let data = try? encoder.encode(profiles) else { return }
        defaults.set(data, forKey: key)
    }
}
