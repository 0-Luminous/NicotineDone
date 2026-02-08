import Foundation
import CoreData

enum ProductType: Int16, CaseIterable, Identifiable {
    case refillableVape = 0
    case cigarettes = 1
    case disposableVape = 2
    case heatedTobacco = 3
    case snusOrPouches = 4
    case hookah = 5

    var id: Int16 { rawValue }

    var title: String {
        switch self {
        case .refillableVape:
            return NSLocalizedString("onboarding_method_refillable_vape", comment: "product type")
        case .cigarettes:
            return NSLocalizedString("onboarding_method_cigarettes", comment: "product type")
        case .disposableVape:
            return NSLocalizedString("onboarding_method_disposable_vape", comment: "product type")
        case .heatedTobacco:
            return NSLocalizedString("onboarding_method_heated_tobacco", comment: "product type")
        case .snusOrPouches:
            return NSLocalizedString("onboarding_method_snus_or_pouches", comment: "product type")
        case .hookah:
            return NSLocalizedString("onboarding_method_hookah", comment: "product type")
        }
    }

    var entryType: EntryType {
        switch self {
        case .refillableVape: return .puff
        case .cigarettes: return .cig
        case .disposableVape: return .disposableVape
        case .heatedTobacco: return .heatedTobacco
        case .snusOrPouches: return .snusOrPouches
        case .hookah: return .hookah
        }
    }

    var buttonLabel: String {
        switch self {
        case .refillableVape: return NSLocalizedString("+ Refillable vape", comment: "main action button")
        case .cigarettes: return NSLocalizedString("+ Cigarette", comment: "main action button")
        case .disposableVape: return NSLocalizedString("+ Disposable vape", comment: "main action button")
        case .heatedTobacco: return NSLocalizedString("+ Heated tobacco", comment: "main action button")
        case .snusOrPouches: return NSLocalizedString("+ Snus pouch", comment: "main action button")
        case .hookah: return NSLocalizedString("+ Hookah session", comment: "main action button")
        }
    }
}

enum EntryType: Int16 {
    case puff = 0
    case cig = 1
    case disposableVape = 2
    case heatedTobacco = 3
    case snusOrPouches = 4
    case hookah = 5
}

enum AchievementKind: Int16 {
    case streak = 0
    case totalSaved = 1
    case daysWithinLimit = 2
}

extension User {
    var product: ProductType {
        ProductType(rawValue: productType) ?? .cigarettes
    }

    var level: Int {
        GamificationService.level(forXP: xp)
    }
}
