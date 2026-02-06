import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var path: [OnboardingRoute] = []
    @Namespace private var linesNamespace

    private let appName = "NicotineDone"

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingWelcomeView(appName: appName,
                                  selectedMode: Binding(
                                    get: { viewModel.selectedMode },
                                    set: { viewModel.selectedMode = $0 }),
                                  onStart: { path.append(.themePicker) },
                                  linesNamespace: linesNamespace)
            .navigationDestination(for: OnboardingRoute.self) { route in
                switch route {
                case .themePicker:
                    OnboardingThemePickerView(linesNamespace: linesNamespace) {
                        path = [.themePicker, .methodPicker]
                    }
                case .methodPicker:
                    OnboardingMethodPickerView(selectedMethod: viewModel.selectedMethod) { method in
                        viewModel.select(method: method)
                        path = [.themePicker, .methodPicker, .methodDetails(method)]
                    }
                    .navigationTitle(Text("onboarding_method_title"))
                    .navigationBarTitleDisplayMode(.large)
                case .methodDetails(let method):
                    OnboardingDetailsView(method: method,
                                          viewModel: viewModel,
                                          supportedCurrencies: viewModel.currencyOptions) { profile in
                        appViewModel.completeOnboarding(with: profile)
                    } onBack: {
                        path = [.themePicker, .methodPicker]
                    }
                    .navigationBarBackButtonHidden()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private enum OnboardingRoute: Hashable {
    case themePicker
    case methodPicker
    case methodDetails(NicotineMethod)
}
