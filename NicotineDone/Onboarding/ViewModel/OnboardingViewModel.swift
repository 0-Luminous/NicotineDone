import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var selectedMode: OnboardingMode = .tracking
    @Published var selectedMethod: NicotineMethod?
    @Published var cigarettesConfig: CigarettesConfig
    @Published var disposableVapeConfig: DisposableVapeConfig
    @Published var refillableVapeConfig: RefillableVapeConfig
    @Published var heatedTobaccoConfig: HeatedTobaccoConfig
    @Published var snusConfig: SnusConfig

    @Published private(set) var validationMessages: [String] = []
    @Published private(set) var warningMessages: [String] = []

    private let settingsStore: SettingsStore
    private var cancellables: Set<AnyCancellable> = []

    let currencyOptions: [Currency]

    init(settingsStore: SettingsStore = InMemorySettingsStore()) {
        self.settingsStore = settingsStore
        currencyOptions = CurrencyRepository.supportedCurrencies
        let defaultCurrency = settingsStore.loadPreferredCurrency()

        if let existing = settingsStore.loadProfile() {
            selectedMethod = existing.method
            cigarettesConfig = existing.cigarettes ?? CigarettesConfig(currency: defaultCurrency)
            disposableVapeConfig = existing.disposableVape ?? DisposableVapeConfig(currency: defaultCurrency)
            refillableVapeConfig = existing.refillableVape ?? RefillableVapeConfig(currency: defaultCurrency)
            heatedTobaccoConfig = existing.heatedTobacco ?? HeatedTobaccoConfig(currency: defaultCurrency)
            snusConfig = existing.snus ?? SnusConfig(currency: defaultCurrency)
        } else {
            cigarettesConfig = CigarettesConfig(currency: defaultCurrency)
            disposableVapeConfig = DisposableVapeConfig(currency: defaultCurrency)
            refillableVapeConfig = RefillableVapeConfig(currency: defaultCurrency)
            heatedTobaccoConfig = HeatedTobaccoConfig(currency: defaultCurrency)
            snusConfig = SnusConfig(currency: defaultCurrency)
        }

        publishersBinding()
    }

    func select(method: NicotineMethod) {
        selectedMethod = method
        refreshValidation()
    }

    func updateCurrency(_ currency: Currency) {
        guard let method = selectedMethod else { return }
        switch method {
        case .cigarettes:
            cigarettesConfig.currency = currency
        case .disposableVape:
            disposableVapeConfig.currency = currency
        case .refillableVape:
            refillableVapeConfig.currency = currency
        case .heatedTobacco:
            heatedTobaccoConfig.currency = currency
        case .snusOrPouches:
            snusConfig.currency = currency
        }
        settingsStore.savePreferredCurrency(currency)
        refreshValidation()
    }

    func apply(profile: NicotineProfile) {
        selectedMethod = profile.method
        cigarettesConfig = profile.cigarettes ?? CigarettesConfig(currency: profile.selectedCurrency)
        disposableVapeConfig = profile.disposableVape ?? DisposableVapeConfig(currency: profile.selectedCurrency)
        refillableVapeConfig = profile.refillableVape ?? RefillableVapeConfig(currency: profile.selectedCurrency)
        heatedTobaccoConfig = profile.heatedTobacco ?? HeatedTobaccoConfig(currency: profile.selectedCurrency)
        snusConfig = profile.snus ?? SnusConfig(currency: profile.selectedCurrency)
        refreshValidation()
    }

    func currency(for method: NicotineMethod) -> Currency {
        switch method {
        case .cigarettes: return cigarettesConfig.currency
        case .disposableVape: return disposableVapeConfig.currency
        case .refillableVape: return refillableVapeConfig.currency
        case .heatedTobacco: return heatedTobaccoConfig.currency
        case .snusOrPouches: return snusConfig.currency
        }
    }

    var isCurrentFormValid: Bool {
        (currentValidatable?.isValid ?? false) && selectedMethod != nil
    }

    func persistProfile() throws -> NicotineProfile {
        let profile = try makeProfile()
        try settingsStore.save(profile: profile)
        return profile
    }

    func makeProfile() throws -> NicotineProfile {
        guard let method = selectedMethod else {
            throw ValidationError.noMethodSelected
        }
        guard let validatable = currentValidatable, validatable.isValid else {
            throw ValidationError.invalidForm
        }

        var profile = NicotineProfile(method: method,
                                      cigarettes: nil,
                                      disposableVape: nil,
                                      refillableVape: nil,
                                      heatedTobacco: nil,
                                      snus: nil)

        switch method {
        case .cigarettes:
            profile.cigarettes = cigarettesConfig
        case .disposableVape:
            profile.disposableVape = disposableVapeConfig
        case .refillableVape:
            profile.refillableVape = refillableVapeConfig
        case .heatedTobacco:
            profile.heatedTobacco = heatedTobaccoConfig
        case .snusOrPouches:
            profile.snus = snusConfig
        }

        return profile
    }

    func helperTextForCurrentMethod() -> [String] {
        guard let method = selectedMethod else { return [] }
        switch method {
        case .cigarettes:
            guard cigarettesConfig.packPrice > 0,
                  cigarettesConfig.cigarettesPerPack > 0 else { return [] }
            let perStick = cigarettesConfig.packPrice / Decimal(cigarettesConfig.cigarettesPerPack)
            let formatted = CurrencyFormatterFactory.string(from: perStick, currencyCode: cigarettesConfig.currency.code)
            return [localized("hint_price_per_cigarette", formatted)]
        case .disposableVape:
            guard disposableVapeConfig.devicePrice > 0,
                  disposableVapeConfig.puffsPerDevice > 0 else { return [] }
            let pricePerHundred = disposableVapeConfig.devicePrice / Decimal(disposableVapeConfig.puffsPerDevice) * Decimal(100)
            let formatted = CurrencyFormatterFactory.string(from: pricePerHundred, currencyCode: disposableVapeConfig.currency.code)
            return [localized("hint_price_per_100_puffs", formatted)]
        case .refillableVape:
            var hints: [String] = []
            if refillableVapeConfig.liquidPrice > 0,
               refillableVapeConfig.liquidBottleMl > 0,
               refillableVapeConfig.estimatedPuffsPerMl > 0 {
                let totalPuffs = Decimal(refillableVapeConfig.liquidBottleMl * refillableVapeConfig.estimatedPuffsPerMl)
                let pricePer100 = refillableVapeConfig.liquidPrice / totalPuffs * Decimal(100)
                let formatted = CurrencyFormatterFactory.string(from: pricePer100, currencyCode: refillableVapeConfig.currency.code)
                hints.append(localized("hint_refillable_price_per_100", formatted))
                let assumedDailyPuffsInt = 200
                let assumedDailyPuffs = Decimal(assumedDailyPuffsInt)
                let dailyCost = pricePer100 / Decimal(100) * assumedDailyPuffs
                let dailyFormatted = CurrencyFormatterFactory.string(from: dailyCost, currencyCode: refillableVapeConfig.currency.code)
                hints.append(localized("hint_refillable_daily_cost", assumedDailyPuffsInt, dailyFormatted))
            }
            return hints
        case .heatedTobacco:
            guard heatedTobaccoConfig.packPrice > 0,
                  heatedTobaccoConfig.sticksPerPack > 0 else { return [] }
            let perStick = heatedTobaccoConfig.packPrice / Decimal(heatedTobaccoConfig.sticksPerPack)
            let formatted = CurrencyFormatterFactory.string(from: perStick, currencyCode: heatedTobaccoConfig.currency.code)
            return [localized("hint_heated_price_per_stick", formatted)]
        case .snusOrPouches:
            guard snusConfig.canPrice > 0,
                  snusConfig.pouchesPerCan > 0 else { return [] }
            let perPouch = snusConfig.canPrice / Decimal(snusConfig.pouchesPerCan)
            let formatted = CurrencyFormatterFactory.string(from: perPouch, currencyCode: snusConfig.currency.code)
            return [localized("hint_snus_price_per_pouch", formatted)]
        }
    }

    private var currentValidatable: OnboardingValidatable? {
        guard let method = selectedMethod else { return nil }
        switch method {
        case .cigarettes: return cigarettesConfig
        case .disposableVape: return disposableVapeConfig
        case .refillableVape: return refillableVapeConfig
        case .heatedTobacco: return heatedTobaccoConfig
        case .snusOrPouches: return snusConfig
        }
    }

    private func publishersBinding() {
        $cigarettesConfig
            .sink { [weak self] _ in self?.refreshValidationIfNeeded(.cigarettes) }
            .store(in: &cancellables)
        $disposableVapeConfig
            .sink { [weak self] _ in self?.refreshValidationIfNeeded(.disposableVape) }
            .store(in: &cancellables)
        $refillableVapeConfig
            .sink { [weak self] _ in self?.refreshValidationIfNeeded(.refillableVape) }
            .store(in: &cancellables)
        $heatedTobaccoConfig
            .sink { [weak self] _ in self?.refreshValidationIfNeeded(.heatedTobacco) }
            .store(in: &cancellables)
        $snusConfig
            .sink { [weak self] _ in self?.refreshValidationIfNeeded(.snusOrPouches) }
            .store(in: &cancellables)
    }

    private func refreshValidationIfNeeded(_ method: NicotineMethod) {
        guard method == selectedMethod else { return }
        refreshValidation()
    }

    private func refreshValidation() {
        validationMessages = currentValidatable?.validationMessages ?? []
        warningMessages = warningMessages(for: selectedMethod)
    }

    private func warningMessages(for method: NicotineMethod?) -> [String] {
        guard let method else { return [] }
        switch method {
        case .cigarettes:
            if let warning = cigarettesConfig.consumptionWarning {
                return [warning]
            }
        default:
            break
        }
        return []
    }

    private func localized(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String(format: format, locale: Locale.current, arguments: args)
    }

    enum ValidationError: LocalizedError {
        case noMethodSelected
        case invalidForm

        var errorDescription: String? {
            switch self {
            case .noMethodSelected:
                return NSLocalizedString("error_no_method_selected", comment: "")
            case .invalidForm:
                return NSLocalizedString("error_invalid_form", comment: "")
            }
        }
    }
}
