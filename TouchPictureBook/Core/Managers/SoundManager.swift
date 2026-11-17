import AVFoundation
import OSLog

@MainActor
final class SoundManager {
    static let shared = SoundManager()

    private enum Volume {
        static let backgroundMusic: Float = 0.25
        static let soundEffect: Float = 0.8
    }

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TouchPictureBook",
        category: "Audio"
    )

    private var backgroundMusicPlayer: AVAudioPlayer?
    private var crowCryPlayer: AVAudioPlayer?
    private var crowFallingPlayer: AVAudioPlayer?
    private var toothBrushingBackgroundMusicPlayer: AVAudioPlayer?
    private var toothBrushingPlayer: AVAudioPlayer?
    private var toothBrushingCompletionPlayer: AVAudioPlayer?
    private var toothStainRemovalPlayer: AVAudioPlayer?
    private var pageTurnPlayer: AVAudioPlayer?
    private var effectPlayers: [AVAudioPlayer] = []

    private init() {
        configureAudioSession()
    }

    func startBalloonBackgroundMusic() {
        if let player = backgroundMusicPlayer {
            if !player.isPlaying {
                _ = player.play()
            }
            return
        }
        guard let url = soundURL(named: "Balloon BGM") else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = Volume.backgroundMusic
            player.currentTime = 0

            let prepared = player.prepareToPlay()
            let started = player.play()
            backgroundMusicPlayer = player

            logger.info(
                "BGM start: prepared=\(prepared, privacy: .public), play=\(started, privacy: .public)"
            )
        } catch {
            logger.error(
                "BGM player initialization failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func stopBalloonBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
        logger.info("BGM stopped")
    }

    func pauseBalloonBackgroundMusic() {
        backgroundMusicPlayer?.pause()
        logger.info("BGM paused")
    }

    func resumeBalloonBackgroundMusic() {
        guard let player = backgroundMusicPlayer else {
            logger.error("BGM resume failed: player is not initialized")
            return
        }

        let started = player.play()
        logger.info("BGM resumed: play=\(started, privacy: .public)")
    }

    func startCrowCry() {
        guard let url = soundURL(named: "Crow_cry") else { return }

        crowCryPlayer?.stop()

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = Volume.soundEffect

            let prepared = player.prepareToPlay()
            let started = player.play()
            crowCryPlayer = player

            logger.info(
                "Crow cry start: prepared=\(prepared, privacy: .public), play=\(started, privacy: .public)"
            )
        } catch {
            logger.error(
                "Crow cry player initialization failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func stopCrowCry() {
        crowCryPlayer?.stop()
        crowCryPlayer = nil
        logger.info("Crow cry stopped")
    }

    func playCrowFalling() {
        guard let url = soundURL(named: "Crow_falling") else { return }

        crowFallingPlayer?.stop()

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.volume = Volume.soundEffect

            let prepared = player.prepareToPlay()
            let started = player.play()
            crowFallingPlayer = player

            logger.info(
                "Crow falling start: prepared=\(prepared, privacy: .public), play=\(started, privacy: .public)"
            )
        } catch {
            logger.error(
                "Crow falling player initialization failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func stopCrowFalling() {
        crowFallingPlayer?.stop()
        crowFallingPlayer = nil
        logger.info("Crow falling stopped")
    }

    func startToothBrushingBackgroundMusic() {
        if let player = toothBrushingBackgroundMusicPlayer {
            if !player.isPlaying {
                _ = player.play()
            }
            return
        }
        guard let url = soundURL(named: "dentifrice BGM") else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = Volume.backgroundMusic
            player.currentTime = 0
            let prepared = player.prepareToPlay()
            let started = player.play()
            toothBrushingBackgroundMusicPlayer = player
            logger.info(
                "Tooth BGM start: prepared=\(prepared, privacy: .public), play=\(started, privacy: .public)"
            )
        } catch {
            logger.error(
                "Tooth BGM initialization failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func stopToothBrushingBackgroundMusic() {
        toothBrushingBackgroundMusicPlayer?.stop()
        toothBrushingBackgroundMusicPlayer = nil
        logger.info("Tooth BGM stopped")
    }

    func pauseToothBrushingBackgroundMusic() {
        toothBrushingBackgroundMusicPlayer?.pause()
    }

    func resumeToothBrushingBackgroundMusic() {
        guard let player = toothBrushingBackgroundMusicPlayer else { return }
        _ = player.play()
    }

    func startToothBrushingSound() {
        guard toothBrushingPlayer?.isPlaying != true else { return }
        guard let url = soundURL(named: "dentifrice") else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = Volume.soundEffect
            let prepared = player.prepareToPlay()
            let started = player.play()
            toothBrushingPlayer = player
            logger.info(
                "Tooth brushing start: prepared=\(prepared, privacy: .public), play=\(started, privacy: .public)"
            )
        } catch {
            logger.error(
                "Tooth brushing initialization failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func stopToothBrushingSound() {
        toothBrushingPlayer?.stop()
        toothBrushingPlayer = nil
    }

    func playToothBrushingCompletion() {
        guard let url = soundURL(named: "Sparkly") else { return }

        toothBrushingCompletionPlayer?.stop()

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.volume = Volume.soundEffect
            let prepared = player.prepareToPlay()
            let started = player.play()
            toothBrushingCompletionPlayer = player
            logger.info(
                "Tooth completion: prepared=\(prepared, privacy: .public), play=\(started, privacy: .public)"
            )
        } catch {
            logger.error(
                "Tooth completion initialization failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func stopToothBrushingCompletion() {
        toothBrushingCompletionPlayer?.stop()
        toothBrushingCompletionPlayer = nil
    }

    func playToothStainRemoval() {
        guard let url = soundURL(named: "Sparkly_1") else { return }

        toothStainRemovalPlayer?.stop()

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.volume = Volume.soundEffect
            let prepared = player.prepareToPlay()
            let started = player.play()
            toothStainRemovalPlayer = player
            logger.info(
                "Tooth stain removal: prepared=\(prepared, privacy: .public), play=\(started, privacy: .public)"
            )
        } catch {
            logger.error(
                "Tooth stain removal initialization failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func stopToothStainRemoval() {
        toothStainRemovalPlayer?.stop()
        toothStainRemovalPlayer = nil
    }

    func playBalloonBurst() {
        logger.info("Balloon burst sound requested")
        playEffect(named: "Balloon burst")
    }

    func playClick() {
        playEffect(named: "click")
    }

    func playPageTurn() {
        guard let url = soundURL(named: "page") else { return }

        pageTurnPlayer?.stop()

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.volume = Volume.soundEffect
            let prepared = player.prepareToPlay()
            let started = player.play()
            pageTurnPlayer = player
            logger.info(
                "Page turn: prepared=\(prepared, privacy: .public), play=\(started, privacy: .public)"
            )
        } catch {
            logger.error(
                "Page turn initialization failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func stopPageTurn() {
        pageTurnPlayer?.stop()
        pageTurnPlayer = nil
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            logger.info(
                "Audio session active: category=\(session.category.rawValue, privacy: .public)"
            )
        } catch {
            logger.error(
                "Audio session setup failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func playEffect(named name: String) {
        effectPlayers.removeAll { !$0.isPlaying }

        guard let url = soundURL(named: name) else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = Volume.soundEffect

            let prepared = player.prepareToPlay()
            effectPlayers.append(player)
            let started = player.play()

            logger.info(
                "Effect \(name, privacy: .public): prepared=\(prepared, privacy: .public), play=\(started, privacy: .public)"
            )
        } catch {
            logger.error(
                "Effect player initialization failed for \(name, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func soundURL(named name: String) -> URL? {
        let url = Bundle.main.url(
            forResource: name,
            withExtension: "mp3",
            subdirectory: "Sounds"
        ) ?? Bundle.main.url(
            forResource: name,
            withExtension: "mp3"
        )

        if let url {
            logger.info(
                "Audio file loaded: \(name, privacy: .public) at \(url.path, privacy: .public)"
            )
        } else {
            logger.error(
                "Audio file not found in bundle: \(name, privacy: .public).mp3"
            )
        }

        return url
    }
}
