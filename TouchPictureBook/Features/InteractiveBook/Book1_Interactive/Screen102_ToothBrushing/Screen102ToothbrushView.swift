import SwiftUI

struct Screen102ToothbrushView: View {
    let touchLocation: CGPoint
    let availableWidth: CGFloat

    private enum Metrics {
        static let baseWidthFraction = 0.18
        static let sizeScale = 2.0
        static let widthFraction = baseWidthFraction * sizeScale
        static let imageAspectRatio = 1579.0 / 996.0
        static let bristlePosition = CGPoint(x: 0.27, y: 0.20)
    }

    var body: some View {
        let width = availableWidth * Metrics.widthFraction
        let height = width * Metrics.imageAspectRatio
        let center = CGPoint(
            x: touchLocation.x + ((0.5 - Metrics.bristlePosition.x) * width),
            y: touchLocation.y + ((0.5 - Metrics.bristlePosition.y) * height)
        )

        Image("toothbrush")
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
            .position(center)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
