import Foundation
import SwiftUI

// MARK: - Onboarding Modes

enum OnboardingMode: String, CaseIterable, Identifiable {
    case tracking
    case gradualReduction
    case quitNow

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .tracking: return "onboarding_mode_tracking_title"
        case .gradualReduction: return "onboarding_mode_gradual_title"
        case .quitNow: return "onboarding_mode_quit_title"
        }
    }

    var subtitleKey: LocalizedStringKey {
        switch self {
        case .tracking: return "onboarding_mode_tracking_description"
        case .gradualReduction: return "onboarding_mode_gradual_description"
        case .quitNow: return "onboarding_mode_quit_description"
        }
    }

    var backgroundImageName: String {
        switch self {
        case .tracking: return "tracking"
        case .gradualReduction: return "Reduce"
        case .quitNow: return "quit"
        }
    }
}

// MARK: - Core Models

enum NicotineMethod: String, Codable, CaseIterable, Identifiable {
    case cigarettes
    case disposableVape = "disposable_vape"
    case refillableVape = "refillable_vape"
    case heatedTobacco = "heated_tobacco"
    case snusOrPouches = "snus_or_pouches"

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .cigarettes: return "onboarding_method_cigarettes"
        case .disposableVape: return "onboarding_method_disposable_vape"
        case .refillableVape: return "onboarding_method_refillable_vape"
        case .heatedTobacco: return "onboarding_method_heated_tobacco"
        case .snusOrPouches: return "onboarding_method_snus_or_pouches"
        }
    }

    var iconAssetName: String {
        switch self {
        case .cigarettes: return "Cigarette"
        case .disposableVape: return "Disposable vape"
        case .refillableVape: return "RefillableVape"
        case .heatedTobacco: return "HeatingDevice"
        case .snusOrPouches: return "SnusPouch"
        }
    }
}

struct Currency: Codable, Hashable, Identifiable {
    let code: String
    var id: String { code }

    var localizedName: String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }

    var symbol: String {
        let identifier = Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code])
        let locale = Locale(identifier: identifier)
        return locale.currencySymbol ?? code
    }

    static var `default`: Currency {
        let code = Locale.current.currencyCode ?? "USD"
        return Currency(code: code)
    }
}

struct CigarettesConfig: Codable, Equatable {
    var cigarettesPerDay: Int = 10
    var cigarettesPerPack: Int = 20
    var packPrice: Decimal = 5
    var currency: Currency = .default
}

struct DisposableVapeConfig: Codable, Equatable {
    var puffsPerDevice: Int = 600
    var devicePrice: Decimal = 12
    var currency: Currency = .default
}

struct RefillableVapeConfig: Codable, Equatable {
    var liquidBottleMl: Int = 30
    var liquidPrice: Decimal = 15
    var nicotineMgPerMl: Int = 12
    var coilPrice: Decimal? = 5
    var estimatedPuffsPerMl: Int = 15
    var currency: Currency = .default
}

struct HeatedTobaccoConfig: Codable, Equatable {
    var sticksPerPack: Int = 20
    var packPrice: Decimal = 7
    var dailySticks: Int = 10
    var currency: Currency = .default
}

struct SnusConfig: Codable, Equatable {
    var pouchesPerCan: Int = 20
    var canPrice: Decimal = 6
    var dailyPouches: Int = 8
    var currency: Currency = .default
}

struct NicotineProfile: Codable, Equatable {
    var method: NicotineMethod
    var cigarettes: CigarettesConfig?
    var disposableVape: DisposableVapeConfig?
    var refillableVape: RefillableVapeConfig?
    var heatedTobacco: HeatedTobaccoConfig?
    var snus: SnusConfig?

    var selectedCurrency: Currency {
        switch method {
        case .cigarettes: return cigarettes?.currency ?? .default
        case .disposableVape: return disposableVape?.currency ?? .default
        case .refillableVape: return refillableVape?.currency ?? .default
        case .heatedTobacco: return heatedTobacco?.currency ?? .default
        case .snusOrPouches: return snus?.currency ?? .default
        }
    }
}

// MARK: - Validation

protocol OnboardingValidatable {
    var validationMessages: [String] { get }
}

extension OnboardingValidatable {
    var isValid: Bool { validationMessages.isEmpty }
}

extension CigarettesConfig: OnboardingValidatable {
    var validationMessages: [String] {
        var messages: [String] = []
        if cigarettesPerDay < 1 || cigarettesPerDay > 99 {
            messages.append(String(localized: "validation_cigarettes_per_day"))
        }
        if cigarettesPerPack < 10 || cigarettesPerPack > 40 {
            messages.append(String(localized: "validation_cigarettes_per_pack"))
        }
        if packPrice <= 0 {
            messages.append(String(localized: "validation_pack_price_positive"))
        }
        return messages
    }

    var consumptionWarning: String? {
        guard cigarettesPerPack > 0,
              cigarettesPerDay > cigarettesPerPack * 2 else { return nil }
        return String(localized: "warning_cigarettes_high_consumption")
    }
}

extension DisposableVapeConfig: OnboardingValidatable {
    var validationMessages: [String] {
        var messages: [String] = []
        if !(600...10000).contains(puffsPerDevice) {
            messages.append(String(localized: "validation_puffs_range"))
        }
        if devicePrice <= 0 {
            messages.append(String(localized: "validation_device_price_positive"))
        }
        return messages
    }
}

extension RefillableVapeConfig: OnboardingValidatable {
    var validationMessages: [String] {
        var messages: [String] = []
        if !(10...120).contains(liquidBottleMl) {
            messages.append(String(localized: "validation_liquid_volume"))
        }
        if liquidPrice <= 0 {
            messages.append(String(localized: "validation_liquid_price_positive"))
        }
        if !(1...60).contains(nicotineMgPerMl) {
            messages.append(String(localized: "validation_nicotine_strength"))
        }
        if let coilPrice, coilPrice < 0 {
            messages.append(String(localized: "validation_coil_price_positive"))
        }
        if !(10...30).contains(estimatedPuffsPerMl) {
            messages.append(String(localized: "validation_estimated_puffs"))
        }
        return messages
    }
}

extension HeatedTobaccoConfig: OnboardingValidatable {
    var validationMessages: [String] {
        var messages: [String] = []
        if sticksPerPack <= 0 {
            messages.append(String(localized: "validation_sticks_per_pack"))
        }
        if packPrice <= 0 {
            messages.append(String(localized: "validation_pack_price_positive"))
        }
        if dailySticks <= 0 {
            messages.append(String(localized: "validation_daily_sticks_positive"))
        }
        return messages
    }
}

extension SnusConfig: OnboardingValidatable {
    var validationMessages: [String] {
        var messages: [String] = []
        if pouchesPerCan <= 0 {
            messages.append(String(localized: "validation_pouches_per_can"))
        }
        if canPrice <= 0 {
            messages.append(String(localized: "validation_can_price_positive"))
        }
        if dailyPouches <= 0 {
            messages.append(String(localized: "validation_daily_pouches_positive"))
        }
        return messages
    }
}

// MARK: - Currency Repository

enum CurrencyRepository {
    static var supportedCurrencies: [Currency] {
        Locale.commonISOCurrencyCodes
            .sorted()
            .map { Currency(code: $0) }
    }

    static func currency(for code: String?) -> Currency {
        guard let code = code else { return .default }
        if Locale.commonISOCurrencyCodes.contains(code) {
            return Currency(code: code)
        }
        return .default
    }
}

// MARK: - Formatting helpers

enum CurrencyFormatterFactory {
    private static var cache: [String: NumberFormatter] = [:]
    private static let queue = DispatchQueue(label: "currency.formatter.factory")

    static func string(from decimal: Decimal, currencyCode: String) -> String {
        let formatter = formatter(for: currencyCode)
        let number = NSDecimalNumber(decimal: decimal)
        return formatter.string(from: number) ?? number.stringValue
    }

    static func formatter(for currencyCode: String) -> NumberFormatter {
        queue.sync {
            if let cached = cache[currencyCode] {
                return cached
            }
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currencyCode
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            cache[currencyCode] = formatter
            return formatter
        }
    }
}
