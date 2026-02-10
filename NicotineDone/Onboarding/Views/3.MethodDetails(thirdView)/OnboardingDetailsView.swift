import SwiftUI

struct OnboardingDetailsView: View {
    let method: NicotineMethod
    @ObservedObject var viewModel: OnboardingViewModel
    let supportedCurrencies: [Currency]
    let onboardingCompleted: (NicotineProfile) -> Void
    let onBack: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("dashboardBackgroundIndex") private var legacyBackgroundIndex: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexLight") private var backgroundIndexLight: Int = DashboardBackgroundStyle.default.rawValue
    @AppStorage("dashboardBackgroundIndexDark") private var backgroundIndexDark: Int = DashboardBackgroundStyle.defaultDark.rawValue
    @AppStorage("appearanceStylesMigrated") private var appearanceStylesMigrated = false

    @State private var errorMessage: String?
    @State private var isCurrencySheetPresented = false
    @State private var currencySearchText = ""

    private var backgroundStyle: DashboardBackgroundStyle { style(for: colorScheme) }
    private var backgroundGradient: LinearGradient { backgroundStyle.backgroundGradient(for: colorScheme) }
    private var primaryTextColor: Color { backgroundStyle.primaryTextColor(for: colorScheme) }
    private var secondaryTextColor: Color { backgroundStyle.secondaryTextColor(for: colorScheme) }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    GlassSection("onboarding_section_currency") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("onboarding_currency_picker_title")
                                .font(.subheadline)
                                .foregroundStyle(primaryTextColor.opacity(0.8))
                            currencyButton
                        }
                    }

                    formContent

                    if !viewModel.validationMessages.isEmpty {
                        ValidationCard(titleKey: "onboarding_validation_section",
                                       messages: viewModel.validationMessages,
                                       systemImage: "exclamationmark.triangle.fill",
                                       tint: .orange)
                    }

                    if !viewModel.warningMessages.isEmpty {
                        ValidationCard(titleKey: "onboarding_warning_section",
                                       messages: viewModel.warningMessages,
                                       systemImage: "info.circle.fill",
                                       tint: .yellow)
                    }

                    let helperTexts = viewModel.helperTextForCurrentMethod()
                    if !helperTexts.isEmpty {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("onboarding_helper_section")
                                    .font(.headline)
                                    .foregroundStyle(primaryTextColor)
                                ForEach(helperTexts, id: \.self) { message in
                                    Text(message)
                                        .font(.footnote)
                                        .foregroundStyle(primaryTextColor.opacity(0.85))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
        .navigationTitle(Text(LocalizedStringKey(method.localizationKey)))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    Label("back_button", systemImage: "chevron.left")
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(primaryTextColor)
                }
                .haptic()
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .transition(.opacity)
                }

                Button(action: submit) {
                    Text("onboarding_continue")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(primaryTextColor)
                }
                .buttonStyle(PrimaryGradientButtonStyle())
                .haptic()
                .disabled(!viewModel.isCurrentFormValid)
                .opacity(viewModel.isCurrentFormValid ? 1 : 0.5)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $isCurrencySheetPresented) {
            NavigationStack {
                CurrencyPickerSheet(supportedCurrencies: supportedCurrencies,
                                    selection: currencyBinding,
                                    searchText: $currencySearchText)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("back_button") {
                                isCurrencySheetPresented = false
                            }
                            .haptic()
                        }
                    }
                    .navigationTitle(Text("onboarding_currency_picker_title"))
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private var formContent: some View {
        switch method {
        case .cigarettes:
            CigarettesFormView(primaryTextColor: primaryTextColor,
                               config: $viewModel.cigarettesConfig)
        case .hookah:
            HookahFormView(primaryTextColor: primaryTextColor,
                           config: $viewModel.cigarettesConfig)
        case .disposableVape:
            DisposableVapeFormView(primaryTextColor: primaryTextColor,
                                   config: $viewModel.disposableVapeConfig)
        case .refillableVape:
            RefillableVapeFormView(primaryTextColor: primaryTextColor,
                                   config: $viewModel.refillableVapeConfig)
        case .heatedTobacco:
            HeatedTobaccoFormView(primaryTextColor: primaryTextColor,
                                  config: $viewModel.heatedTobaccoConfig)
        case .snusOrPouches:
            SnusFormView(primaryTextColor: primaryTextColor,
                         config: $viewModel.snusConfig)
        }
    }

    private var currencyBinding: Binding<Currency> {
        Binding(
            get: { viewModel.currency(for: method) },
            set: { viewModel.updateCurrency($0) }
        )
    }

    private var currencyButton: some View {
        Button {
            isCurrencySheetPresented = true
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(selectedCurrencyDescription)
                        .font(.headline)
                        .foregroundStyle(primaryTextColor)
                    Text(viewModel.currency(for: method).localizedName)
                        .font(.caption)
                        .foregroundStyle(primaryTextColor)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(primaryTextColor.opacity(0.75))
            }
            .glassInputStyle()
        }
        .buttonStyle(.plain)
        .haptic()
    }

    private var selectedCurrencyDescription: String {
        let currency = viewModel.currency(for: method)
        return "\(currency.code)"
    }

    private func submit() {
        do {
            viewModel.select(method: method)
            let profile = try viewModel.persistProfile()
            onboardingCompleted(profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func style(for scheme: ColorScheme) -> DashboardBackgroundStyle {
        ensureAppearanceMigration()
        let index = scheme == .dark ? backgroundIndexDark : backgroundIndexLight
        return DashboardBackgroundStyle(rawValue: index) ?? DashboardBackgroundStyle.default(for: scheme)
    }

    private func ensureAppearanceMigration() {
        guard !appearanceStylesMigrated else { return }
        backgroundIndexLight = legacyBackgroundIndex
        backgroundIndexDark = legacyBackgroundIndex
        appearanceStylesMigrated = true
    }
}

#Preview("Cigarette Form") {
    let viewModel = OnboardingViewModel()
    viewModel.select(method: .cigarettes)
    return NavigationStack {
        OnboardingDetailsView(method: .cigarettes,
                              viewModel: viewModel,
                              supportedCurrencies: viewModel.currencyOptions,
                              onboardingCompleted: { _ in }, onBack: {})
    }
    .environment(\.locale, .init(identifier: "en"))
}
