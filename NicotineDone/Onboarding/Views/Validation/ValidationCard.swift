import SwiftUI

struct ValidationCard: View {
    let titleKey: LocalizedStringKey
    let messages: [String]
    let systemImage: String
    let tint: Color

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(titleKey)
                    .font(.headline)
                ValidationListView(messages: messages,
                                   systemImage: systemImage,
                                   tint: tint)
            }
        }
    }
}
