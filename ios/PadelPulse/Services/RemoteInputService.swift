import AVFoundation
import MediaPlayer
import GameController

/// Captures Bluetooth media remote and keyboard input for courtside scoring.
///
/// Layer 1: MPRemoteCommandCenter — handles Next/Previous/PlayPause from media remotes
/// Layer 2: GCKeyboard — handles hardware keyboard input as fallback
///
/// Note: Volume keys CANNOT be intercepted on iPadOS (OS restriction).
/// The Android app maps Volume Up/Down to scoring, but on iPadOS only
/// media keys (Next Track, Previous Track, Play/Pause) are available.
final class RemoteInputService {
    var onTeam1Score: (() -> Void)?
    var onTeam2Score: (() -> Void)?
    var onUndo: (() -> Void)?

    private var audioSession: AVAudioSession?
    private var silentPlayer: AVAudioPlayer?
    private var keyboardConnectObserver: NSObjectProtocol?

    func start() {
        setupAudioSession()
        setupRemoteCommands()
        setupGameController()
    }

    func stop() {
        let center = MPRemoteCommandCenter.shared()
        center.nextTrackCommand.removeTarget(nil)
        center.previousTrackCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
        center.togglePlayPauseCommand.isEnabled = false

        silentPlayer?.stop()
        silentPlayer = nil

        if let token = keyboardConnectObserver {
            NotificationCenter.default.removeObserver(token)
            keyboardConnectObserver = nil
        }

        try? AVAudioSession.sharedInstance().setActive(false)
    }

    /// Re-activates the audio session and silent loop after interruptions
    /// (call returns, Siri, foregrounding from background).
    func resumeSilentLoop() {
        try? AVAudioSession.sharedInstance().setActive(true)
        if let player = silentPlayer, !player.isPlaying {
            player.play()
        }
    }

    // MARK: - Layer 1: MPRemoteCommandCenter (Media Keys)

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            audioSession = session

            // Silent audio loop is required for iOS to deliver MPRemoteCommand
            // events — the app must be the active "Now Playing" source.
            if let url = Bundle.main.url(forResource: "silence", withExtension: "m4a") {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1
                player.volume = 0
                player.prepareToPlay()
                player.play()
                silentPlayer = player
            }

            MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                MPMediaItemPropertyTitle: "Padel Pulse",
                MPMediaItemPropertyArtist: "Scoreboard"
            ]
        } catch {
            print("RemoteInputService: Audio session setup failed: \(error)")
        }
    }

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.nextTrackCommand.isEnabled = true
        center.nextTrackCommand.addTarget { [weak self] _ in
            // Handlers can fire on an arbitrary thread — @Observable mutations must be on main.
            DispatchQueue.main.async { self?.onTeam1Score?() }
            return .success
        }

        center.previousTrackCommand.isEnabled = true
        center.previousTrackCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async { self?.onTeam2Score?() }
            return .success
        }

        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async { self?.onUndo?() }
            return .success
        }

        // Disable other commands so they don't interfere
        center.playCommand.isEnabled = false
        center.pauseCommand.isEnabled = false
        center.stopCommand.isEnabled = false
    }

    // MARK: - Layer 2: GCKeyboard (Hardware keyboard fallback)

    private func setupGameController() {
        // Listen for keyboard connections. Store the token so stop() can unregister.
        keyboardConnectObserver = NotificationCenter.default.addObserver(
            forName: .GCKeyboardDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let keyboard = notification.object as? GCKeyboard else { return }
            self?.configureKeyboard(keyboard)
        }

        // Configure already-connected keyboard
        if let keyboard = GCKeyboard.coalesced {
            configureKeyboard(keyboard)
        }
    }

    private func configureKeyboard(_ keyboard: GCKeyboard) {
        keyboard.keyboardInput?.keyChangedHandler = { [weak self] _, _, keyCode, pressed in
            guard pressed else { return }
            DispatchQueue.main.async {
                switch keyCode {
                case .upArrow, .keypadPlus:
                    self?.onTeam1Score?()
                case .downArrow, .keypadHyphen:
                    self?.onTeam2Score?()
                case .spacebar:
                    self?.onUndo?()
                default:
                    break
                }
            }
        }
    }
}
