import SwiftUI

enum PageTurnDirection {
    case forward
    case backward
}

enum PageTurnTransition {
    static let animationDuration: TimeInterval = 0.7
}

struct PageTurnLayer<Content: View>: View {
    let direction: PageTurnDirection
    let progress: Double
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            let animatedProgress = CGFloat(progress)
            let bendAmount = sin(.pi * animatedProgress)
            let turnAngle = direction == .forward
                ? -88 * progress
                : 88 * progress
            let anchor: UnitPoint = direction == .forward ? .leading : .trailing
            let edgeAlignment: Alignment = direction == .forward
                ? .trailing
                : .leading

            content()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color(red: 1.0, green: 0.98, blue: 0.91))
                .mask {
                    PageSoftEdgeShape(
                        progress: animatedProgress,
                        direction: direction
                    )
                }
                .overlay(alignment: edgeAlignment) {
                    PageCurlHighlight(
                        direction: direction,
                        progress: animatedProgress,
                        height: geometry.size.height
                    )
                }
                .scaleEffect(
                    x: 1 - (0.055 * bendAmount),
                    y: 1 + (0.012 * bendAmount),
                    anchor: anchor
                )
                .rotationEffect(
                    .degrees(
                        (direction == .forward ? -1 : 1)
                            * 2.5 * bendAmount
                    ),
                    anchor: anchor
                )
                .rotation3DEffect(
                    .degrees(turnAngle),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: anchor,
                    perspective: 0.72
                )
                .shadow(
                    color: .black.opacity(0.12 + (0.24 * bendAmount)),
                    radius: 8 + (20 * bendAmount),
                    x: direction == .forward
                        ? -14 * bendAmount
                        : 14 * bendAmount,
                    y: 3
                )
        }
    }
}

private struct PageSoftEdgeShape: Shape {
    var progress: CGFloat
    let direction: PageTurnDirection

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let bend = sin(.pi * progress)
        let inset = rect.width * 0.045 * bend

        var path = Path()
        if direction == .forward {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - inset * 0.25, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - inset, y: rect.midY),
                control: CGPoint(x: rect.maxX + inset, y: rect.height * 0.28)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - inset * 0.25, y: rect.maxY),
                control: CGPoint(x: rect.maxX + inset, y: rect.height * 0.72)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + inset * 0.25, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + inset, y: rect.midY),
                control: CGPoint(x: rect.minX - inset, y: rect.height * 0.28)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + inset * 0.25, y: rect.maxY),
                control: CGPoint(x: rect.minX - inset, y: rect.height * 0.72)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

private struct PageCurlHighlight: View {
    let direction: PageTurnDirection
    let progress: CGFloat
    let height: CGFloat

    var body: some View {
        let bend = sin(.pi * progress)
        let curlWidth = 10 + (54 * bend)

        PageCurlShape(direction: direction, bend: bend)
            .fill(
                LinearGradient(
                    colors: direction == .forward
                        ? [
                            .clear,
                            .black.opacity(0.18 * bend),
                            Color(red: 1.0, green: 0.98, blue: 0.91)
                                .opacity(0.9 * bend),
                            .white.opacity(0.5 * bend)
                        ]
                        : [
                            .white.opacity(0.5 * bend),
                            Color(red: 1.0, green: 0.98, blue: 0.91)
                                .opacity(0.9 * bend),
                            .black.opacity(0.18 * bend),
                            .clear
                        ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: curlWidth, height: height)
            .allowsHitTesting(false)
    }
}

private struct PageCurlShape: Shape {
    let direction: PageTurnDirection
    var bend: CGFloat

    var animatableData: CGFloat {
        get { bend }
        set { bend = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let outerX = direction == .forward ? rect.maxX : rect.minX
        let innerX = direction == .forward
            ? rect.minX + rect.width * 0.15 * bend
            : rect.maxX - rect.width * 0.15 * bend

        var path = Path()
        path.move(to: CGPoint(x: outerX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: innerX, y: rect.midY),
            control: CGPoint(
                x: direction == .forward ? rect.minX : rect.maxX,
                y: rect.height * 0.30
            )
        )
        path.addQuadCurve(
            to: CGPoint(x: outerX, y: rect.maxY),
            control: CGPoint(
                x: direction == .forward ? rect.minX : rect.maxX,
                y: rect.height * 0.70
            )
        )
        path.closeSubpath()
        return path
    }
}
