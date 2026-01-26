import Foundation
import CoreData

enum ProductType: Int16, CaseIterable, Identifiable {
    case vape = 0
    case cigarette = 1

    var id: Int16 { rawValue }

    var title: String {
        switch self {
        case .vape: return NSLocalizedString("Vape", comment: "product type")
        case .cigarette: return NSLocalizedString("Cigarettes", comment: "product type")
        }
    }

    var entryType: EntryType {
        switch self {
        case .vape: return .puff
        case .cigarette: return .cig
        }
    }

    var buttonLabel: String {
        switch self {
        case .vape: return NSLocalizedString("+ Puff", comment: "main action button")
        case .cigarette: return NSLocalizedString("+ Cigarette", comment: "main action button")
        }
    }
}

enum EntryType: Int16 {
    case puff = 0
    case cig = 1
}

enum AchievementKind: Int16 {
    case streak = 0
    case totalSaved = 1
    case daysWithinLimit = 2
}

extension User {
    var product: ProductType {
        ProductType(rawValue: productType) ?? .cigarette
    }

    var level: Int {
        GamificationService.level(forXP: xp)
    }
}
