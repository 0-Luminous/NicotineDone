import CoreData

protocol UserRepository {
    func fetchUser() -> User?
    func createUser(from profile: NicotineProfile) -> User
}

final class CoreDataUserRepository: UserRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchUser() -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    func createUser(from profile: NicotineProfile) -> User {
        let user = User(context: context)
        user.id = UUID()
        user.createdAt = Date()
        user.productType = productType(for: profile).rawValue
        user.dailyLimit = Int32(clamping: dailyLimit(for: profile))
        user.packSize = Int16(clamping: packSize(for: profile))
        user.packCost = packCost(for: profile)
        user.currencyCode = profile.selectedCurrency.code
        user.coins = 0
        user.xp = 0
        return user
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

    private func packSize(for profile: NicotineProfile) -> Int {
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

    private func packCost(for profile: NicotineProfile) -> Double {
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
