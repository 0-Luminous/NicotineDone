import SwiftUI
import CoreData
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published var user: User?
    @Published var shouldShowOnboarding = false

    private let context: NSManagedObjectContext
    private let gamification: GamificationService

    init(context: NSManagedObjectContext) {
        self.context = context
        self.gamification = GamificationService(context: context)
        loadUser()
    }

    func loadUser() {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        if let existing = try? context.fetch(request).first {
            user = existing
            shouldShowOnboarding = false
        } else {
            shouldShowOnboarding = true
        }
    }

    func completeOnboarding(with profile: NicotineProfile) {
        let newUser = User(context: context)
        newUser.id = UUID()
        newUser.createdAt = Date()
        newUser.productType = productType(for: profile).rawValue
        newUser.dailyLimit = Int32(clamping: dailyLimit(for: profile))
        newUser.packSize = Int16(clamping: packSize(for: profile))
        newUser.packCost = packCost(for: profile)
        newUser.currencyCode = profile.selectedCurrency.code
        newUser.coins = 0
        newUser.xp = 0

        gamification.bootstrapCatalogIfNeeded()
        context.saveIfNeeded()

        user = newUser
        shouldShowOnboarding = false
    }

    func resetOnboarding() {
        user = nil
        shouldShowOnboarding = true
    }

    private func productType(for profile: NicotineProfile) -> ProductType {
        switch profile.method {
        case .cigarettes, .hookah, .heatedTobacco, .snusOrPouches:
            return .cigarette
        case .disposableVape, .refillableVape:
            return .vape
        }
    }

    private func dailyLimit(for profile: NicotineProfile) -> Int {
        switch profile.method {
        case .cigarettes:
            return profile.cigarettes?.cigarettesPerDay ?? 10
        case .hookah:
            return profile.cigarettes?.cigarettesPerDay ?? 3
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

    private func packSize(for profile: NicotineProfile) -> Int {
        switch profile.method {
        case .cigarettes:
            return profile.cigarettes?.cigarettesPerPack ?? 20
        case .hookah:
            return profile.cigarettes?.cigarettesPerPack ?? 1
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

    private func packCost(for profile: NicotineProfile) -> Double {
        switch profile.method {
        case .cigarettes:
            guard let price = profile.cigarettes?.packPrice else { return 0 }
            return NSDecimalNumber(decimal: price).doubleValue
        case .hookah:
            guard let price = profile.cigarettes?.packPrice else { return 0 }
            return NSDecimalNumber(decimal: price).doubleValue
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
