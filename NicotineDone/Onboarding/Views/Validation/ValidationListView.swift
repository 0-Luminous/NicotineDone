import SwiftUI

struct ValidationListView: View {
    let messages: [String]
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(messages, id: \.self) { message in
                Label {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                } icon: {
                    Image(systemName: systemImage)
                        .foregroundStyle(tint)
                        .accessibilityHidden(true)
                }
            }
        }
    }
}
