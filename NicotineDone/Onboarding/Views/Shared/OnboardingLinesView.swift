import SwiftUI

struct OnboardingLinesView: View {
    enum Layout {
        case center
        case side
    }

    let size: CGSize
    let layout: Layout
    let namespace: Namespace.ID

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let strokeWidth: CGFloat = layout == .side ? 6 : 4
            ZStack {
                lineView(id: "onboardingLine1",
                     color: Color(hex: "#B758FF"),
                     lineWidth: strokeWidth,
                     amplitude: layout == .center ? 22 : 4,
                     phase: 0.2 + t * 0.6,
                     length: lineLength,
                     yOffset: baseY + (layout == .center ? -20 : -40),
                     xOffset: xOffset)
                lineView(id: "onboardingLine2",
                     color: Color(hex: "#64E2F2"),
                     lineWidth: strokeWidth,
                     amplitude: layout == .center ? 30 : 3,
                     phase: 1.1 + t * 0.45,
                     length: lineLength,
                     yOffset: baseY + (layout == .center ? 14 : 10),
                     xOffset: xOffset)
                lineView(id: "onboardingLine3",
                     color: Color(hex: "#C7A27A"),
                     lineWidth: strokeWidth,
                     amplitude: layout == .center ? 18 : 2,
                     phase: 2.0 + t * 0.35,
                     length: lineLength,
                     yOffset: baseY + (layout == .center ? 44 : 60),
                     xOffset: xOffset)
                lineView(id: "onboardingLine4",
                     color: Color(hex: "#FF6B5A"),
                     lineWidth: strokeWidth,
                     amplitude: layout == .center ? 16 : 2,
                     phase: 2.8 + t * 0.5,
                     length: lineLength,
                     yOffset: baseY + (layout == .center ? 78 : 100),
                     xOffset: xOffset)
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .allowsHitTesting(false)
        }
    }

    private var baseY: CGFloat {
        layout == .center ? size.height * 0.32 : size.height * 0.38
    }

    private var lineLength: CGFloat {
        if layout == .center {
            return size.width + 40
        }
        return min(size.width * 0.7, 460)
    }

    private var xOffset: CGFloat {
        layout == .center ? -20 : -40
    }

    private func lineView(id: String,
                          color: Color,
                          lineWidth: CGFloat,
                          amplitude: CGFloat,
                          phase: CGFloat,
                          length: CGFloat,
                          yOffset: CGFloat,
                          xOffset: CGFloat) -> some View {
        WaveLineShape(amplitude: amplitude, phase: phase)
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .frame(width: length, height: max(lineWidth + amplitude * 2, lineWidth))
            .shadow(color: color.opacity(0.25), radius: 6, x: 0, y: 4)
            .offset(x: xOffset, y: yOffset)
            .matchedGeometryEffect(id: id, in: namespace)
    }
}

private struct WaveLineShape: Shape {
    var amplitude: CGFloat
    var phase: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let midY = rect.midY
        let step: CGFloat = 16
        path.move(to: CGPoint(x: 0, y: midY))
        var x: CGFloat = 0
        while x <= width {
            let progress = x / max(width, 1)
            let y = midY + sin((progress * .pi * 2) + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }
        return path
    }
}
