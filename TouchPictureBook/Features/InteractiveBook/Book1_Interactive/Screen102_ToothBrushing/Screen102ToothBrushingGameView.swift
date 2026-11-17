import SwiftUI
#if DEBUG
import UIKit
#endif

struct Screen102ToothBrushingGameView: View {
    let isActive: Bool

    private enum Metrics {
        static let babyImageSize = CGSize(width: 937, height: 1678)
        static let expressionContentBounds = CGRect(
            x: 1,
            y: 307,
            width: 935,
            height: 1370
        )
        static let visibleHorizontalMargin: CGFloat = 4
        static let topClearance: CGFloat = 44
        static let navigationClearance: CGFloat = 150
        static let stainToToothWidthRatio = 0.55
        static let requiredBrushingTime: TimeInterval = 2.0
        static let minimumMovement: CGFloat = 0.75
        static let maximumSampleInterval: TimeInterval = 0.12
        static let minimumHitRadius: CGFloat = 24
        static let initialToothbrushPosition = CGPoint(x: 0.78, y: 0.72)
    }

    @Environment(\.scenePhase) private var scenePhase
    @State private var stains: [Screen102ToothStain] = []
    @State private var touchLocation: CGPoint?
    @State private var movementReferenceLocation: CGPoint?
    @State private var movementReferenceDate: Date?
    @State private var isComplete = false
    @State private var brushingSoundActivityID = 0
#if DEBUG
    @State private var loggedProgressSteps: [UUID: Int] = [:]
#endif

    var body: some View {
        GeometryReader { geometry in
            let babyFrame = babyFrame(in: geometry.size)

            ZStack {
                ToothBrushingBackgroundView()

                BabyBodyExtensionView(
                    topY: babyFrame.maxY - 2,
                    screenSize: geometry.size
                )

                BabyFaceView(
                    isHappy: isComplete,
                    frame: babyFrame
                )

                ForEach(stains) { stain in
                    let position = screenPosition(
                        for: stain.normalizedPosition,
                        in: babyFrame
                    )

                    Screen102ToothStainView(
                        imageName: stain.imageName,
                        progress: stain.brushingProgress,
                        width: babyFrame.width * stain.normalizedWidth
                    )
                    .position(position)

                    if stain.isRemoved {
                        Screen102ToothSparkleView()
                            .position(position)
                    }
                }

                if let touchLocation, !isComplete {
                    Screen102ToothbrushView(
                        touchLocation: touchLocation,
                        availableWidth: geometry.size.width
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .allowsHitTesting(isActive)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        handleDrag(
                            at: value.location,
                            in: geometry.size,
                            babyFrame: babyFrame
                        )
                    }
                    .onEnded { _ in
                        endBrushing()
                    }
            )
            .onAppear {
                resetGame(in: babyFrame)
                logMissingAssets()
            }
            .onDisappear {
                endBrushing()
                touchLocation = nil
                SoundManager.shared.stopToothBrushingCompletion()
                SoundManager.shared.stopToothStainRemoval()
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    return
                } else {
                    endBrushing()
                    SoundManager.shared.stopToothBrushingCompletion()
                    SoundManager.shared.stopToothStainRemoval()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    break
                case .inactive, .background:
                    SoundManager.shared.stopToothBrushingSound()
                    SoundManager.shared.stopToothBrushingCompletion()
                    SoundManager.shared.stopToothStainRemoval()
                @unknown default:
                    SoundManager.shared.stopToothBrushingSound()
                    SoundManager.shared.stopToothBrushingCompletion()
                    SoundManager.shared.stopToothStainRemoval()
                }
            }
            .task(id: brushingSoundActivityID) {
                guard brushingSoundActivityID > 0 else { return }

                do {
                    try await Task.sleep(for: .milliseconds(120))
                } catch {
                    return
                }

                guard !Task.isCancelled else { return }
                SoundManager.shared.stopToothBrushingSound()
            }
        }
    }

    private func babyFrame(in size: CGSize) -> CGRect {
        let imageAspectRatio = Metrics.babyImageSize.height
            / Metrics.babyImageSize.width
        let visibleWidthRatio = Metrics.expressionContentBounds.width
            / Metrics.babyImageSize.width
        let visibleHeightToImageWidth = Metrics.expressionContentBounds.height
            / Metrics.babyImageSize.width
        let targetVisibleWidth = max(
            0,
            size.width - (Metrics.visibleHorizontalMargin * 2)
        )
        let widthForHorizontalFit = targetVisibleWidth / visibleWidthRatio
        let footerTop = size.height - Metrics.navigationClearance
        let widthForVerticalFit = max(
            0,
            (footerTop - Metrics.topClearance) / visibleHeightToImageWidth
        )
        let width = min(widthForHorizontalFit, widthForVerticalFit)
        let height = width * imageAspectRatio
        let visibleWidth = width * visibleWidthRatio
        let visibleLeft = (size.width - visibleWidth) / 2
        let originX = visibleLeft
            - ((Metrics.expressionContentBounds.minX / Metrics.babyImageSize.width) * width)
        let visibleBottomRatio = Metrics.expressionContentBounds.maxY
            / Metrics.babyImageSize.height
        let originY = footerTop - (visibleBottomRatio * height)

        return CGRect(
            x: originX,
            y: originY,
            width: width,
            height: height
        )
    }

    private func screenPosition(for normalizedPosition: CGPoint, in frame: CGRect) -> CGPoint {
        CGPoint(
            x: frame.minX + (normalizedPosition.x * frame.width),
            y: frame.minY + (normalizedPosition.y * frame.height)
        )
    }

    private func handleDrag(
        at location: CGPoint,
        in size: CGSize,
        babyFrame: CGRect
    ) {
        guard !isComplete else { return }
        guard location.y < size.height - Metrics.navigationClearance else {
            endBrushing()
            return
        }

        touchLocation = location
        let now = Date.now

        guard
            let referenceLocation = movementReferenceLocation,
            let referenceDate = movementReferenceDate
        else {
            movementReferenceLocation = location
            movementReferenceDate = now
            return
        }

        let movement = hypot(
            location.x - referenceLocation.x,
            location.y - referenceLocation.y
        )
        guard movement >= Metrics.minimumMovement else { return }

        let elapsed = min(
            now.timeIntervalSince(referenceDate),
            Metrics.maximumSampleInterval
        )
        movementReferenceLocation = location
        movementReferenceDate = now

        guard let index = stainIndex(at: location, in: babyFrame) else { return }

        SoundManager.shared.startToothBrushingSound()
        brushingSoundActivityID += 1
        let wasRemoved = stains[index].isRemoved

        stains[index].effectiveBrushingTime = min(
            stains[index].effectiveBrushingTime + elapsed,
            Metrics.requiredBrushingTime
        )
        stains[index].brushingProgress = min(
            stains[index].effectiveBrushingTime / Metrics.requiredBrushingTime,
            1
        )
        logBrushingProgress(for: stains[index], at: location)

        if !wasRemoved, stains[index].isRemoved {
            SoundManager.shared.stopToothBrushingSound()
            let removedCount = stains.filter(\.isRemoved).count

            if removedCount == stains.count, !isComplete {
                SoundManager.shared.playToothBrushingCompletion()
                withAnimation(.easeInOut(duration: 0.25)) {
                    isComplete = true
                    touchLocation = nil
                }
            } else {
                SoundManager.shared.playToothStainRemoval()
            }
        }
    }

    private func stainIndex(at location: CGPoint, in babyFrame: CGRect) -> Int? {
        stains.firstIndex { stain in
            guard !stain.isRemoved else { return false }
            let center = screenPosition(
                for: stain.normalizedPosition,
                in: babyFrame
            )
            let displayedWidth = babyFrame.width * stain.normalizedWidth
            let hitRadius = max(
                displayedWidth * 1.5,
                Metrics.minimumHitRadius
            )

            return hypot(location.x - center.x, location.y - center.y) <= hitRadius
        }
    }

    private func endBrushing() {
        movementReferenceLocation = nil
        movementReferenceDate = nil
        SoundManager.shared.stopToothBrushingSound()
    }

    private func resetGame(in babyFrame: CGRect) {
        let upperTeeth = ToothRegion.all.filter { $0.jaw == .upper }
        let lowerTeeth = ToothRegion.all.filter { $0.jaw == .lower }
        let upper = upperTeeth.randomElement() ?? upperTeeth[3]
        let lower = lowerTeeth.randomElement() ?? lowerTeeth[4]
        let remaining = ToothRegion.all.filter {
            $0.id != upper.id && $0.id != lower.id
        }
        let third = remaining.randomElement() ?? remaining[0]
        let selectedTeeth = [upper, lower, third].shuffled()
        let imageNames = ["tooth_decay_1", "tooth_decay_2", "tooth_decay_3"]

        stains = zip(imageNames, selectedTeeth).map { imageName, tooth in
            Screen102ToothStain(
                imageName: imageName,
                toothID: tooth.id,
                normalizedPosition: tooth.normalizedCenter,
                normalizedWidth: tooth.normalizedFrame.width
                    * Metrics.stainToToothWidthRatio
            )
        }
        isComplete = false
        brushingSoundActivityID = 0
        SoundManager.shared.stopToothBrushingSound()
        SoundManager.shared.stopToothBrushingCompletion()
        SoundManager.shared.stopToothStainRemoval()
#if DEBUG
        loggedProgressSteps = [:]
#endif
        endBrushing()
        touchLocation = screenPosition(
            for: Metrics.initialToothbrushPosition,
            in: babyFrame
        )
        logSelectedTeeth(in: babyFrame)
    }

    private func logMissingAssets() {
#if DEBUG
        let names = [
            "bathroom_background",
            "Baby_expression",
            "Baby_happy",
            "toothbrush",
            "tooth_decay_1",
            "tooth_decay_2",
            "tooth_decay_3"
        ]

        for name in names where UIImage(named: name) == nil {
            print("[ToothBrushingGame] Missing asset: \(name)")
        }
#endif
    }

    private func logSelectedTeeth(in babyFrame: CGRect) {
#if DEBUG
        for stain in stains {
            let screenPoint = screenPosition(
                for: stain.normalizedPosition,
                in: babyFrame
            )
            print(
                "[ToothBrushingGame] selected=\(stain.toothID) "
                    + "normalized=(\(stain.normalizedPosition.x), "
                    + "\(stain.normalizedPosition.y)) "
                    + "screen=(\(screenPoint.x), \(screenPoint.y))"
            )
        }
#endif
    }

    private func logBrushingProgress(for stain: Screen102ToothStain, at bristle: CGPoint) {
#if DEBUG
        let step = Int(stain.brushingProgress * 4)
        guard step > loggedProgressSteps[stain.id, default: 0] else { return }
        loggedProgressSteps[stain.id] = step
        print(
            "[ToothBrushingGame] tooth=\(stain.toothID) "
                + "bristle=(\(bristle.x), \(bristle.y)) "
                + "time=\(stain.effectiveBrushingTime)s "
                + "progress=\(stain.brushingProgress)"
        )
#endif
    }
}

private struct BabyBodyExtensionView: View {
    let topY: CGFloat
    let screenSize: CGSize

    var body: some View {
        let height = max(0, screenSize.height - topY)

        Rectangle()
            .fill(Color(red: 68 / 255, green: 153 / 255, blue: 219 / 255))
            .frame(width: screenSize.width, height: height)
            .position(x: screenSize.width / 2, y: topY + (height / 2))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct ToothBrushingBackgroundView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.cyan.opacity(0.12)

                Image("bathroom_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
        }
        .allowsHitTesting(false)
    }
}

private struct BabyFaceView: View {
    let isHappy: Bool
    let frame: CGRect

    var body: some View {
        Image(isHappy ? "Baby_happy" : "Baby_expression")
            .resizable()
            .scaledToFit()
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
            .animation(.easeInOut(duration: 0.25), value: isHappy)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct Screen102ToothStainView: View {
    let imageName: String
    let progress: Double
    let width: CGFloat

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: width)
            .opacity(progress >= 1 ? 0 : max(0.12, 1 - (progress * 0.88)))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
