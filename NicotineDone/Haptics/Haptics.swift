import SwiftUI
import UIKit

enum HapticType {
    case selection
    case impactLight
    case impactMedium
    case impactHeavy
    case notificationSuccess
    case notificationWarning
    case notificationError
}

enum Haptics {
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    static func play(_ type: HapticType) {
        DispatchQueue.main.async {
            switch type {
            case .selection:
                selectionGenerator.prepare()
                selectionGenerator.selectionChanged()
            case .impactLight:
                lightImpactGenerator.prepare()
                lightImpactGenerator.impactOccurred()
            case .impactMedium:
                mediumImpactGenerator.prepare()
                mediumImpactGenerator.impactOccurred()
            case .impactHeavy:
                heavyImpactGenerator.prepare()
                heavyImpactGenerator.impactOccurred()
            case .notificationSuccess:
                notificationGenerator.prepare()
                notificationGenerator.notificationOccurred(.success)
            case .notificationWarning:
                notificationGenerator.prepare()
                notificationGenerator.notificationOccurred(.warning)
            case .notificationError:
                notificationGenerator.prepare()
                notificationGenerator.notificationOccurred(.error)
            }
        }
    }
}

extension View {
    func haptic(_ type: HapticType = .selection) -> some View {
        simultaneousGesture(
            TapGesture().onEnded { Haptics.play(type) }
        )
    }
}
