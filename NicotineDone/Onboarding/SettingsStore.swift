import Foundation
import Combine

protocol SettingsStore: AnyObject {
    var profilePublisher: Published<NicotineProfile?>.Publisher { get }

    func loadProfile() -> NicotineProfile?
    func save(profile: NicotineProfile) throws

    func loadPreferredCurrency() -> Currency
    func savePreferredCurrency(_ currency: Currency)

    func reset() throws
}

final class InMemorySettingsStore: SettingsStore, ObservableObject {
    @Published private var storedProfile: NicotineProfile?
    @Published private var storedCurrency: Currency

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private static let profileKey = "onboarding.nicotine.profile"
    private static let currencyKey = "onboarding.preferred.currency"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.profileKey),
           let profile = try? decoder.decode(NicotineProfile.self, from: data) {
            storedProfile = profile
            storedCurrency = profile.selectedCurrency
        } else {
            storedProfile = nil
            let code = defaults.string(forKey: Self.currencyKey)
            storedCurrency = CurrencyRepository.currency(for: code)
        }
    }

    var profilePublisher: Published<NicotineProfile?>.Publisher { $storedProfile }

    func loadProfile() -> NicotineProfile? {
        storedProfile
    }

    func save(profile: NicotineProfile) throws {
        storedProfile = profile
        let data = try encoder.encode(profile)
        defaults.set(data, forKey: Self.profileKey)
        savePreferredCurrency(profile.selectedCurrency)
    }

    func loadPreferredCurrency() -> Currency {
        storedCurrency
    }

    func savePreferredCurrency(_ currency: Currency) {
        storedCurrency = currency
        defaults.set(currency.code, forKey: Self.currencyKey)
    }

    func reset() throws {
        storedProfile = nil
        defaults.removeObject(forKey: Self.profileKey)
    }
}
