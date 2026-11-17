import SwiftUI

enum BalloonMetrics {
    static let imageCanvasWidthFraction = 1.02
    static let imageCanvasHeightFraction = 0.52
    static let visibleWidthFraction = 0.34
    static let visibleHeightFraction = 0.38

    static func center(
        for configuration: BalloonConfiguration,
        at date: Date,
        in size: CGSize
    ) -> CGPoint {
        let canvasHeight = size.width * imageCanvasHeightFraction
        let verticalRange = size.height + (canvasHeight * 2)
        let y = size.height + canvasHeight
            - (verticalRange * configuration.progress(at: date))

        return CGPoint(
            x: size.width * configuration.horizontalFraction(at: date),
            y: y
        )
    }

    static func contains(
        point: CGPoint,
        configuration: BalloonConfiguration,
        at date: Date,
        in size: CGSize
    ) -> Bool {
        let center = center(for: configuration, at: date, in: size)
        let radiusX = size.width * visibleWidthFraction / 2
        let radiusY = size.width * visibleHeightFraction / 2
        let normalizedX = (point.x - center.x) / radiusX
        let normalizedY = (point.y - center.y) / radiusY

        return (normalizedX * normalizedX) + (normalizedY * normalizedY) <= 1
    }
}

struct Screen101BalloonView: View {
    private enum Phase: Equatable {
        case rising
        case popping(frame: Int)
        case waiting
    }

    private let frameDuration = Duration.milliseconds(80)
    private let regenerationDelay = Duration.milliseconds(400)

    let availableSize: CGSize
    let configuration: BalloonConfiguration
    let collisionTrigger: Int
    let onPopping: (UUID) -> Void
    let onFinished: (UUID) -> Void

    @State private var phase = Phase.rising
    @State private var frozenCenter = CGPoint.zero
    @State private var frozenRotation = 0.0
    @State private var lifecycleID = 0

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1.0 / 60.0,
                paused: phase != .rising
            )
        ) { context in
            balloonContent(at: context.date)
        }
        .task(id: lifecycleID) {
            await runLifecycle()
        }
        .onChange(of: collisionTrigger) { oldValue, newValue in
            guard newValue > oldValue else { return }
            pop()
        }
    }

    private func balloonContent(at date: Date) -> some View {
        let canvasWidth = availableSize.width
            * BalloonMetrics.imageCanvasWidthFraction
        let canvasHeight = availableSize.width
            * BalloonMetrics.imageCanvasHeightFraction
        let hitTargetWidth = availableSize.width
            * BalloonMetrics.visibleWidthFraction
        let hitTargetHeight = availableSize.width
            * BalloonMetrics.visibleHeightFraction
        let center = phase == .rising
            ? BalloonMetrics.center(
                for: configuration,
                at: date,
                in: availableSize
            )
            : frozenCenter
        let rotation = phase == .rising
            ? configuration.rotation(at: date)
            : frozenRotation

        return ZStack {
            Image(currentImageName)
                .resizable()
                .scaledToFit()
                .frame(width: canvasWidth, height: canvasHeight)
                .allowsHitTesting(false)

            Button(action: pop) {
                Color.clear
                    .frame(width: hitTargetWidth, height: hitTargetHeight)
                    .contentShape(Ellipse())
            }
            .buttonStyle(.plain)
            .allowsHitTesting(phase == .rising)
            .accessibilityLabel(configuration.kind.accessibilityLabel)
            .accessibilityHint("タップすると風船が割れます")
        }
        .frame(width: canvasWidth, height: canvasHeight)
        .rotationEffect(.degrees(rotation))
        .position(center)
        .opacity(phase == .waiting ? 0 : 1)
    }

    private var currentImageName: String {
        let frame: Int

        switch phase {
        case .rising:
            frame = 1
        case .popping(let poppingFrame):
            frame = poppingFrame
        case .waiting:
            frame = 8
        }

        return "\(configuration.kind.assetPrefix)_\(frame)"
    }

    private func pop() {
        guard phase == .rising else { return }

        let now = Date.now
        frozenCenter = BalloonMetrics.center(
            for: configuration,
            at: now,
            in: availableSize
        )
        frozenRotation = configuration.rotation(at: now)
        phase = .popping(frame: 2)
        onPopping(configuration.id)
        SoundManager.shared.playBalloonBurst()
        lifecycleID += 1
    }

    private func runLifecycle() async {
        switch phase {
        case .rising:
            let remainingDuration = configuration.riseDuration
                * (1 - configuration.initialProgress)

            guard await sleep(for: .seconds(remainingDuration)) else { return }
            onFinished(configuration.id)

        case .popping:
            for frame in 2...8 {
                guard !Task.isCancelled else { return }
                phase = .popping(frame: frame)

                guard await sleep(for: frameDuration) else { return }
            }

            phase = .waiting
            guard await sleep(for: regenerationDelay) else { return }
            onFinished(configuration.id)

        case .waiting:
            break
        }
    }

    private func sleep(for duration: Duration) async -> Bool {
        do {
            try await Task.sleep(for: duration)
            return !Task.isCancelled
        } catch {
            return false
        }
    }
}
