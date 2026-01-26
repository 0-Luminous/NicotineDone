import Foundation

extension NicotineMethod {
    var descriptionKey: String {
        switch self {
        case .cigarettes: return "onboarding_method_cigarettes_desc"
        case .disposableVape: return "onboarding_method_disposable_vape_desc"
        case .refillableVape: return "onboarding_method_refillable_vape_desc"
        case .heatedTobacco: return "onboarding_method_heated_tobacco_desc"
        case .snusOrPouches: return "onboarding_method_snus_or_pouches_desc"
        }
    }
}
