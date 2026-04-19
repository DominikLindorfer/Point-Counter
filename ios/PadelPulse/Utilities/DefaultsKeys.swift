import Foundation

/// Central registry of every UserDefaults key used in the app.
///
/// Any caller that persists to UserDefaults — directly or via `@AppStorage` —
/// uses a constant from here so that:
/// - the full set of keys is discoverable in one file,
/// - tests can tear down by symbolic name instead of hardcoded strings,
/// - accidental key drift (typos, renames) is impossible without touching here.
enum DefaultsKey {
    static let matchHistory = "match_history"
    static let nextId = "next_id"
    static let inProgressMatch = "in_progress_match"
    static let autoSwapMode = "auto_swap_mode"
    static let soundMuted = "sound_muted"
    static let selectedLanguage = "selected_language"
    static let cameraOverlayEnabled = "camera_overlay_enabled"
    static let hasSeenOnboarding = "has_seen_onboarding"
}
