import Foundation
import CoreData
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedMethod: NicotineMethod = .cigarettes
    @Published var latestProfile: NicotineProfile?
    @Published var dailyLimit: Double = 10
    @Published var storedProfiles: [NicotineProfile] = []
    @Published var editingProfile: NicotineProfile?

    private let user: User
    private let context: NSManagedObjectContext
    private let savedMethodsStore: SavedMethodsStore
    private let onboardingStore: SettingsStore

    init(user: User, environment: AppEnvironment) {
        self.user = user
        self.context = environment.context
        self.savedMethodsStore = environment.savedMethodsStore
        self.onboardingStore = environment.settingsStore
    }

    func synchronizeForm() {
        refreshStoredProfiles()
        if let profile = storedProfiles.first {
            selectedMethod = profile.method
        } else {
            selectedMethod = nicotineMethod(for: ProductType(rawValue: user.productType) ?? .cigarettes)
        }
        dailyLimit = Double(user.dailyLimit)
    }

    func save() {
        user.productType = productType(for: selectedMethod).rawValue
        user.dailyLimit = Int32(dailyLimit)

        if let profile = latestProfile {
            user.packSize = Int16(clamping: packSize(for: profile))
            user.packCost = packCost(for: profile)
            user.currencyCode = profile.selectedCurrency.code
        }

        context.saveIfNeeded()
    }

    func refreshStoredProfiles() {
        let latestOnboardingProfile = onboardingStore.loadProfile()
        storedProfiles = savedMethodsStore.mergeLatestOnboardingProfile(latestOnboardingProfile)
    }

    func applyProfileSelection(_ profile: NicotineProfile, persist: Bool = true) {
        latestProfile = profile
        selectedMethod = profile.method
        dailyLimit = Double(dailyLimit(for: profile))
        if persist {
            savedMethodsStore.save(profile: profile)
        }
        try? onboardingStore.save(profile: profile)
        refreshStoredProfiles()
    }

    func deleteProfile(_ profile: NicotineProfile) {
        savedMethodsStore.delete(method: profile.method)
        refreshStoredProfiles()
        if selectedMethod == profile.method {
            if let fallback = storedProfiles.first {
                applyProfileSelection(fallback, persist: false)
            } else {
                selectedMethod = nicotineMethod(for: ProductType(rawValue: user.productType) ?? .cigarettes)
                dailyLimit = Double(user.dailyLimit)
                latestProfile = nil
            }
        }
    }

    func nicotineMethod(for product: ProductType) -> NicotineMethod {
        switch product {
        case .cigarettes:
            return .cigarettes
        case .refillableVape:
            return .refillableVape
        case .disposableVape:
            return .disposableVape
        case .heatedTobacco:
            return .heatedTobacco
        case .snusOrPouches:
            return .snusOrPouches
        case .hookah:
            return .hookah
        }
    }

    func productType(for method: NicotineMethod) -> ProductType {
        switch method {
        case .cigarettes:
            return .cigarettes
        case .hookah:
            return .hookah
        case .heatedTobacco:
            return .heatedTobacco
        case .snusOrPouches:
            return .snusOrPouches
        case .disposableVape:
            return .disposableVape
        case .refillableVape:
            return .refillableVape
        }
    }

    func dailyLimit(for profile: NicotineProfile) -> Int {
        switch profile.method {
        case .cigarettes:
            return profile.cigarettes?.cigarettesPerDay ?? 10
        case .hookah:
            let sessionsPerWeek = profile.cigarettes?.cigarettesPerDay ?? 3
            let perDay = Double(sessionsPerWeek) / 7.0
            return max(1, Int(ceil(perDay)))
        case .disposableVape:
            guard let config = profile.disposableVape else { return 150 }
            let computed = max(80, config.puffsPerDevice / 5)
            return min(computed, config.puffsPerDevice)
        case .refillableVape:
            guard let config = profile.refillableVape else { return 200 }
            return max(100, config.estimatedPuffsPerMl * 5)
        case .heatedTobacco:
            return profile.heatedTobacco?.dailySticks ?? 15
        case .snusOrPouches:
            return profile.snus?.dailyPouches ?? 10
        }
    }

    func packSize(for profile: NicotineProfile) -> Int {
        switch profile.method {
        case .cigarettes:
            return profile.cigarettes?.cigarettesPerPack ?? 20
        case .hookah:
            return 1
        case .disposableVape:
            return profile.disposableVape?.puffsPerDevice ?? 600
        case .refillableVape:
            return profile.refillableVape?.liquidBottleMl ?? 30
        case .heatedTobacco:
            return profile.heatedTobacco?.sticksPerPack ?? 20
        case .snusOrPouches:
            return profile.snus?.pouchesPerCan ?? 20
        }
    }

    func packCost(for profile: NicotineProfile) -> Double {
        switch profile.method {
        case .cigarettes:
            guard let price = profile.cigarettes?.packPrice else { return 0 }
            return NSDecimalNumber(decimal: price).doubleValue
        case .hookah:
            guard let config = profile.cigarettes else { return 0 }
            let total = config.packPrice * config.hookahPacksPerSession
            return NSDecimalNumber(decimal: total).doubleValue
        case .disposableVape:
            guard let price = profile.disposableVape?.devicePrice else { return 0 }
            return NSDecimalNumber(decimal: price).doubleValue
        case .refillableVape:
            guard let config = profile.refillableVape else { return 0 }
            let total = config.liquidPrice + (config.coilPrice ?? 0)
            return NSDecimalNumber(decimal: total).doubleValue
        case .heatedTobacco:
            guard let price = profile.heatedTobacco?.packPrice else { return 0 }
            return NSDecimalNumber(decimal: price).doubleValue
        case .snusOrPouches:
            guard let price = profile.snus?.canPrice else { return 0 }
            return NSDecimalNumber(decimal: price).doubleValue
        }
    }
}
