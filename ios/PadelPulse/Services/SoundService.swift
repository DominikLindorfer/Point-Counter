import AudioToolbox
import Foundation

/// Lightweight sound effects using system sounds. No bundled audio files needed.
enum SoundService {
    static var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: "sound_muted") }
        set { UserDefaults.standard.set(newValue, forKey: "sound_muted") }
    }

    static func playPointScored() {
        play(systemSoundID: 1104) // Subtle keyboard tap
    }

    static func playGameWon() {
        play(systemSoundID: 1025) // Ascending chime
    }

    static func playMatchOver() {
        play(systemSoundID: 1335) // Triumphant notification
    }

    private static func play(systemSoundID: SystemSoundID) {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(systemSoundID)
    }
}
