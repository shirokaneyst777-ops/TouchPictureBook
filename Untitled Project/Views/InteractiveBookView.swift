import SwiftUI

struct InteractiveBookView: View {
    private let pageCount = 8

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var currentPage = 1
    @State private var transitionTarget: Int?
    @State private var turnDirection = PageTurnDirection.forward
    @State private var turnProgress = 0.0
    @State private var transitionID = 0

    private var isTurningPage: Bool { transitionTarget != nil }

    var body: some View {
        ZStack {
            ZStack {
                if let transitionTarget {
                    BookPageContent(
                        currentPage: transitionTarget,
                        isActive: false
                    )
                }

                PageTurnLayer(
                    direction: turnDirection,
                    progress: turnProgress
                ) {
                    BookPageContent(
                        currentPage: currentPage,
                        isActive: !isTurningPage
                    )
                }
                .zIndex(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()

            BookControlsOverlay(
                currentPage: currentPage,
                pageCount: pageCount,
                isEnabled: !isTurningPage,
                onPrevious: { beginPageTurn(.backward) },
                onHome: dismiss.callAsFunction,
                onNext: { beginPageTurn(.forward) }
            )
            .zIndex(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: transitionID) { await completePageTurn() }
        .onAppear {
            updateBackgroundMusic(for: currentPage, scenePhase: scenePhase)
        }
        .onChange(of: currentPage) { _, newPage in
            updateBackgroundMusic(for: newPage, scenePhase: scenePhase)
        }
        .onChange(of: scenePhase) { _, newPhase in
            updateBackgroundMusic(for: currentPage, scenePhase: newPhase)
        }
        .onDisappear {
            SoundManager.shared.stopPageTurn()
            SoundManager.shared.stopBalloonBackgroundMusic()
            SoundManager.shared.stopToothBrushingBackgroundMusic()
        }
    }

    private func beginPageTurn(_ direction: PageTurnDirection) {
        guard transitionTarget == nil else { return }
        turnDirection = direction
        turnProgress = 0
        transitionTarget = targetPage(for: direction)
        SoundManager.shared.playPageTurn()
        transitionID += 1
    }

    private func targetPage(for direction: PageTurnDirection) -> Int {
        switch direction {
        case .forward:
            return currentPage == pageCount ? 1 : currentPage + 1
        case .backward:
            return currentPage == 1 ? pageCount : currentPage - 1
        }
    }

    private func completePageTurn() async {
        guard let targetPage = transitionTarget else { return }

        await Task.yield()
        withAnimation(.easeInOut(duration: PageTurnTransition.animationDuration)) {
            turnProgress = 1
        }

        do {
            try await Task.sleep(for: .seconds(PageTurnTransition.animationDuration))
        } catch {
            return
        }

        guard !Task.isCancelled, transitionTarget == targetPage else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            currentPage = targetPage
            transitionTarget = nil
            turnProgress = 0
        }
    }

    private func updateBackgroundMusic(
        for page: Int,
        scenePhase: ScenePhase = .active
    ) {
        guard scenePhase == .active else {
            SoundManager.shared.pauseBalloonBackgroundMusic()
            SoundManager.shared.pauseToothBrushingBackgroundMusic()
            return
        }

        if page == 1 {
            SoundManager.shared.stopToothBrushingBackgroundMusic()
            SoundManager.shared.startBalloonBackgroundMusic()
        } else if page == 2 {
            SoundManager.shared.stopBalloonBackgroundMusic()
            SoundManager.shared.startToothBrushingBackgroundMusic()
        } else {
            SoundManager.shared.stopBalloonBackgroundMusic()
            SoundManager.shared.stopToothBrushingBackgroundMusic()
        }
    }
}

private struct BookPageContent: View {
    let currentPage: Int
    let isActive: Bool

    var body: some View {
        if currentPage == 1 {
            BalloonPageView(isActive: isActive)
        } else if currentPage == 2 {
            ToothBrushingGameView(isActive: isActive)
        } else {
            PlaceholderBookPage()
        }
    }
}

private struct BalloonPageView: View {
    let isActive: Bool

    var body: some View {
        ZStack {
            BalloonBackgroundView()
            BalloonGameView(isActive: isActive)
        }
    }
}

private struct BalloonBackgroundView: View {
    var body: some View {
        ZStack {
            Color.cyan.opacity(0.12)
            GeometryReader { geometry in
                Image("balloon_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
        }
    }
}

private struct PlaceholderBookPage: View {
    var body: some View {
        ZStack {
            Color.cyan.opacity(0.12)
            Text("イラスト配置予定")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct BookControlsOverlay: View {
    let currentPage: Int
    let pageCount: Int
    let isEnabled: Bool
    let onPrevious: () -> Void
    let onHome: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Text("\(currentPage) / \(pageCount)")
                .font(.headline)
                .monospacedDigit()
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(.regularMaterial, in: Capsule())

            BookNavigationBar(
                onPrevious: onPrevious,
                onHome: onHome,
                onNext: onNext
            )
        }
        .padding(.bottom, 8)
        .allowsHitTesting(isEnabled)
    }
}
