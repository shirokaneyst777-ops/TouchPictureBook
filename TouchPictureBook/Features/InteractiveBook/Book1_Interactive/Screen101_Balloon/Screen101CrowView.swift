import SwiftUI

struct CrowConfiguration: Identifiable, Equatable {
    let id = UUID()
    let yFraction: Double
    let flightDuration: TimeInterval
    let floatingPeriod: TimeInterval
    let floatingPhase: Double
    var startDate: Date

    func progress(at date: Date) -> Double {
        min(max(date.timeIntervalSince(startDate) / flightDuration, 0), 1)
    }
}

enum CrowAnimationPhase: Equatable {
    case flying
    case reacting(frame: Int)
    case tapped
    case falling
    case landed

    var imageName: String {
        switch self {
        case .flying:
            "Crow_2"
        case .reacting(let frame):
            "Crow_\(frame)"
        case .tapped:
            "Crow_Hit_2"
        case .falling:
            "Crow_Hit_3"
        case .landed:
            "Crow_Hit_4"
        }
    }
}

enum CrowMetrics {
    static let flightDurationRange: ClosedRange<Double> = 2...3
    static let floatingAmplitude: CGFloat = 20
    static let floatingPeriodRange: ClosedRange<Double> = 1.5...2.5
    static let maximumRotationDegrees = 4.0
    static let tappedFrameDuration = Duration.milliseconds(200)
    static let fallDuration: TimeInterval = 0.9
    static let landedFrameDuration = Duration.milliseconds(300)
    static let fallRotationDegrees = 28.0

    static let widthFraction = 0.38
    static let heightToWidthRatio = 593.0 / 720.0
    static let collisionWidthRatio = 0.90
    static let collisionHeightRatio = 0.80

    static func center(
        for configuration: CrowConfiguration,
        progress: Double,
        in size: CGSize
    ) -> CGPoint {
        let width = size.width * widthFraction
        let startX = size.width + (width / 2)
        let endX = -(width / 2)
        let floatingOffset = sin(floatingAngle(
            for: configuration,
            progress: progress
        )) * floatingAmplitude

        return CGPoint(
            x: startX + ((endX - startX) * progress),
            y: (size.height * configuration.yFraction) + floatingOffset
        )
    }

    static func rotation(
        for configuration: CrowConfiguration,
        progress: Double
    ) -> Double {
        sin(floatingAngle(for: configuration, progress: progress))
            * maximumRotationDegrees
    }

    static func fallingCenter(
        from startCenter: CGPoint,
        progress: Double,
        crowHeight: CGFloat,
        in size: CGSize
    ) -> CGPoint {
        let easedProgress = progress * progress
        let targetY = size.height - (crowHeight * 0.35)

        return CGPoint(
            x: startCenter.x,
            y: startCenter.y + ((targetY - startCenter.y) * easedProgress)
        )
    }

    static func intersects(
        balloon: BalloonConfiguration,
        at date: Date,
        crow: CrowConfiguration,
        crowProgress: Double,
        in size: CGSize
    ) -> Bool {
        let crowCenter = center(
            for: crow,
            progress: crowProgress,
            in: size
        )
        let balloonCenter = BalloonMetrics.center(
            for: balloon,
            at: date,
            in: size
        )

        let crowWidth = size.width * widthFraction
        let crowHeight = crowWidth * heightToWidthRatio
        let combinedRadiusX = (crowWidth * collisionWidthRatio / 2)
            + (size.width * BalloonMetrics.visibleWidthFraction / 2)
        let combinedRadiusY = (crowHeight * collisionHeightRatio / 2)
            + (size.width * BalloonMetrics.visibleHeightFraction / 2)
        let normalizedX = (balloonCenter.x - crowCenter.x) / combinedRadiusX
        let normalizedY = (balloonCenter.y - crowCenter.y) / combinedRadiusY

        return (normalizedX * normalizedX) + (normalizedY * normalizedY) <= 1
    }

    private static func floatingAngle(
        for configuration: CrowConfiguration,
        progress: Double
    ) -> Double {
        let elapsedFlightTime = progress * configuration.flightDuration

        return (2 * Double.pi * elapsedFlightTime / configuration.floatingPeriod)
            + configuration.floatingPhase
    }
}

struct Screen101CrowView: View {
    let availableSize: CGSize
    let configuration: CrowConfiguration
    let phase: CrowAnimationPhase
    let progress: Double
    let fallProgress: Double
    let onTap: () -> Void

    var body: some View {
        let width = availableSize.width * CrowMetrics.widthFraction
        let height = width * CrowMetrics.heightToWidthRatio
        let flightCenter = CrowMetrics.center(
            for: configuration,
            progress: progress,
            in: availableSize
        )
        let center = CrowMetrics.fallingCenter(
            from: flightCenter,
            progress: fallProgress,
            crowHeight: height,
            in: availableSize
        )
        let flightRotation = CrowMetrics.rotation(
            for: configuration,
            progress: progress
        )
        let rotation = flightRotation + (CrowMetrics.fallRotationDegrees * fallProgress)

        ZStack {
            Image(phase.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
                .allowsHitTesting(false)

            Button(action: onTap) {
                Color.clear
                    .frame(
                        width: width * CrowMetrics.collisionWidthRatio,
                        height: height * CrowMetrics.collisionHeightRatio
                    )
                    .contentShape(Ellipse())
            }
            .buttonStyle(.plain)
            .disabled(phase != .flying)
            .accessibilityLabel("カラス")
        }
        .rotationEffect(.degrees(rotation))
        .position(center)
    }
}
