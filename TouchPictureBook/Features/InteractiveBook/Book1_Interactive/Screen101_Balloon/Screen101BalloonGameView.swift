import SwiftUI

enum BalloonKind: Equatable {
    case red
    case gold

    var assetPrefix: String {
        switch self {
        case .red:
            "balloon_red"
        case .gold:
            "balloon_gold"
        }
    }

    var accessibilityLabel: LocalizedStringResource {
        switch self {
        case .red:
            "赤い風船"
        case .gold:
            "金色の風船"
        }
    }
}

struct BalloonConfiguration: Identifiable, Equatable {
    let id = UUID()
    let kind: BalloonKind
    let baseXFraction: Double
    let initialProgress: Double
    let riseDuration: TimeInterval
    let swayAmplitudeFraction: Double
    let swayFrequency: Double
    let swayPhase: Double
    let startDate: Date

    func progress(at date: Date) -> Double {
        let elapsed = date.timeIntervalSince(startDate)
        return min(initialProgress + (elapsed / riseDuration), 1)
    }

    func horizontalFraction(at date: Date) -> CGFloat {
        let elapsed = date.timeIntervalSince(startDate)
        let angle = (2 * Double.pi * swayFrequency * elapsed) + swayPhase
        return CGFloat(baseXFraction + (sin(angle) * swayAmplitudeFraction))
    }

    func rotation(at date: Date) -> Double {
        let elapsed = date.timeIntervalSince(startDate)
        let angle = (2 * Double.pi * swayFrequency * elapsed) + swayPhase
        return sin(angle) * 4
    }
}

struct Screen101BalloonGameView: View {
    let isActive: Bool

    private let minimumBalloonCount = 3
    private let maximumBalloonCount = 5
    private let collisionCheckInterval = Duration.milliseconds(50)

    @State private var balloons: [BalloonConfiguration] = []
    @State private var inactiveBalloonIDs: Set<UUID> = []
    @State private var collisionTriggers: [UUID: Int] = [:]
    @State private var crow: CrowConfiguration?
    @State private var crowPhase = CrowAnimationPhase.flying
    @State private var crowPausedProgress: Double?
    @State private var crowFallStartDate: Date?
    @State private var crowTapSequenceID = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(balloons) { balloon in
                    Screen101BalloonView(
                        availableSize: geometry.size,
                        configuration: balloon,
                        collisionTrigger: collisionTriggers[balloon.id, default: 0],
                        onPopping: markBalloonInactive,
                        onFinished: removeBalloon
                    )
                }

                if let crow {
                    TimelineView(.animation) { context in
                        Screen101CrowView(
                            availableSize: geometry.size,
                            configuration: crow,
                            phase: crowPhase,
                            progress: crowProgress(at: context.date, crow: crow),
                            fallProgress: crowFallProgress(at: context.date),
                            onTap: handleCrowTap
                        )
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .task {
                guard isActive else { return }
                await runBalloonGeneration()
            }
            .task {
                guard isActive else { return }
                await runCollisionDetection(in: geometry.size)
            }
            .task(id: "\(isActive)-\(crowTapSequenceID)") {
                guard isActive else { return }
                await runCrowTapSequence()
            }
        }
        .allowsHitTesting(isActive)
        .onChange(of: isActive) { _, newValue in
            if !newValue {
                SoundManager.shared.stopCrowCry()
                SoundManager.shared.stopCrowFalling()
            }
        }
        .onDisappear {
            SoundManager.shared.stopCrowCry()
            SoundManager.shared.stopCrowFalling()
        }
    }

    private func runBalloonGeneration() async {
        if balloons.isEmpty {
            spawnInitialBalloons()
        }

        while !Task.isCancelled {
            guard await sleep(
                for: .milliseconds(Int.random(in: 500...1_000))
            ) else {
                return
            }

            let activeCount = balloons.count - inactiveBalloonIDs.count
            let shouldAdd = activeCount < minimumBalloonCount
                || (activeCount < maximumBalloonCount && Bool.random())

            if shouldAdd {
                spawnBalloon(initialProgress: 0)
            }
        }
    }

    private func runCollisionDetection(in size: CGSize) async {
        while !Task.isCancelled {
            guard await sleep(for: collisionCheckInterval) else { return }
            guard let currentCrow = crow else { continue }
            guard crowPhase == .flying else { continue }

            let progress = currentCrow.progress(at: .now)
            if progress >= 1 {
                removeCrow()
                continue
            }

            let now = Date.now
            if let balloon = balloons.first(where: {
                !inactiveBalloonIDs.contains($0.id)
                    && CrowMetrics.intersects(
                        balloon: $0,
                        at: now,
                        crow: currentCrow,
                        crowProgress: progress,
                        in: size
                    )
            }) {
                await handleCollision(
                    with: balloon.id,
                    crowID: currentCrow.id,
                    progress: progress
                )
            }
        }
    }

    private func handleCollision(
        with balloonID: UUID,
        crowID: UUID,
        progress: Double
    ) async {
        guard crow?.id == crowID else { return }
        guard !inactiveBalloonIDs.contains(balloonID) else { return }

        inactiveBalloonIDs.insert(balloonID)
        collisionTriggers[balloonID, default: 0] += 1
        crowPausedProgress = progress
        crowPhase = .reacting(frame: 1)

        guard await sleep(for: .milliseconds(120)) else { return }
        crowPhase = .reacting(frame: 3)

        guard await sleep(for: .milliseconds(160)) else { return }
        crowPhase = .reacting(frame: 2)

        guard await sleep(for: .milliseconds(120)) else { return }
        guard var resumedCrow = crow, resumedCrow.id == crowID else { return }

        resumedCrow.startDate = .now.addingTimeInterval(
            -(progress * resumedCrow.flightDuration)
        )
        crow = resumedCrow
        crowPausedProgress = nil
        crowPhase = .flying
    }

    private func handleCrowTap() {
        guard let currentCrow = crow, crowPhase == .flying else { return }

        crowPausedProgress = currentCrow.progress(at: .now)
        crowFallStartDate = nil
        crowPhase = .tapped
        SoundManager.shared.stopCrowCry()
        crowTapSequenceID += 1
    }

    private func runCrowTapSequence() async {
        guard crow != nil, crowPhase == .tapped else { return }

        guard await sleep(for: CrowMetrics.tappedFrameDuration) else { return }
        guard crow != nil, crowPhase == .tapped else { return }

        crowFallStartDate = .now
        crowPhase = .falling
        SoundManager.shared.playCrowFalling()

        guard await sleep(for: .seconds(CrowMetrics.fallDuration)) else { return }
        guard crow != nil, crowPhase == .falling else { return }

        crowPhase = .landed

        guard await sleep(for: CrowMetrics.landedFrameDuration) else { return }
        guard crow != nil, crowPhase == .landed else { return }
        removeCrow()
    }

    private func spawnInitialBalloons() {
        let startingPositions = [
            (x: 0.22, progress: 0.34),
            (x: 0.50, progress: 0.17),
            (x: 0.78, progress: 0.02)
        ]

        for position in startingPositions {
            spawnBalloon(
                initialProgress: position.progress,
                preferredX: position.x
            )
        }
    }

    private func spawnBalloon(
        initialProgress: Double,
        preferredX: Double? = nil
    ) {
        let kind: BalloonKind = Int.random(in: 1...8) == 1 ? .gold : .red
        let balloon = BalloonConfiguration(
            kind: kind,
            baseXFraction: preferredX ?? availableXFraction(),
            initialProgress: initialProgress,
            riseDuration: Double.random(in: 8...12),
            swayAmplitudeFraction: Double.random(in: 0.035...0.055),
            swayFrequency: Double.random(in: 0.10...0.18),
            swayPhase: Double.random(in: 0...(2 * .pi)),
            startDate: .now
        )

        balloons.append(balloon)
        attemptCrowSpawn()
    }

    private func attemptCrowSpawn() {
        guard crow == nil else { return }
        guard Int.random(in: 1...10) == 1 else { return }

        crow = CrowConfiguration(
            yFraction: Double.random(in: 0.18...0.68),
            flightDuration: Double.random(
                in: CrowMetrics.flightDurationRange
            ),
            floatingPeriod: Double.random(
                in: CrowMetrics.floatingPeriodRange
            ),
            floatingPhase: Double.random(in: 0...(2 * .pi)),
            startDate: .now
        )
        crowPhase = .flying
        crowPausedProgress = nil
        crowFallStartDate = nil
        SoundManager.shared.stopCrowFalling()
        SoundManager.shared.startCrowCry()
    }

    private func crowProgress(
        at date: Date,
        crow: CrowConfiguration
    ) -> Double {
        crowPausedProgress ?? crow.progress(at: date)
    }

    private func crowFallProgress(at date: Date) -> Double {
        switch crowPhase {
        case .falling:
            guard let crowFallStartDate else { return 0 }
            return min(
                max(date.timeIntervalSince(crowFallStartDate) / CrowMetrics.fallDuration, 0),
                1
            )
        case .landed:
            return 1
        default:
            return 0
        }
    }

    private func removeCrow() {
        crow = nil
        crowPausedProgress = nil
        crowFallStartDate = nil
        crowPhase = .flying
        SoundManager.shared.stopCrowCry()
        SoundManager.shared.stopCrowFalling()
    }

    private func availableXFraction() -> Double {
        let candidates = [0.22, 0.36, 0.50, 0.64, 0.78].shuffled()
        let activeXPositions = balloons
            .filter { !inactiveBalloonIDs.contains($0.id) }
            .map(\.baseXFraction)

        return candidates.max { first, second in
            minimumDistance(from: first, to: activeXPositions)
                < minimumDistance(from: second, to: activeXPositions)
        } ?? 0.5
    }

    private func minimumDistance(
        from candidate: Double,
        to positions: [Double]
    ) -> Double {
        positions.map { abs($0 - candidate) }.min() ?? 1
    }

    private func markBalloonInactive(_ id: UUID) {
        inactiveBalloonIDs.insert(id)
    }

    private func removeBalloon(_ id: UUID) {
        balloons.removeAll { $0.id == id }
        inactiveBalloonIDs.remove(id)
        collisionTriggers.removeValue(forKey: id)
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
