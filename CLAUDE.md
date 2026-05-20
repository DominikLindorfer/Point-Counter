# CLAUDE.md — Padel Pulse

## Project Overview

Cross-platform padel & tennis courtside scoreboard. Fork of `DominikLindorfer/Point-Counter` (upstream remote already configured).

**Status:** Android app is published on Google Play. iOS app (iPhone + iPad) is in **beta** (feature-complete, pre-release polish in progress).

---

## Android App (released)

**Package:** `io.github.dominiklindorfer.padelcounter`
**Min SDK:** 26 (Android 8.0) | **Target SDK:** 36

### Tech Stack (Android)

- Kotlin + Jetpack Compose (Material 3)
- CameraX for video recording overlay
- AndroidX Lifecycle + ViewModel
- SharedPreferences + JSON for match history persistence
- Gradle with version catalogs (`libs.versions.toml`)

### Structure (Android)

```
app/src/main/java/io/github/dominiklindorfer/padelcounter/
├── MainActivity.kt            # UI: ScoreBoard, TeamPanel, SettingsSidebar, MatchTimer
├── MatchState.kt              # Scoring logic: MatchState, PadelScoring, MatchViewModel
├── MatchStorage.kt            # Match history persistence (SharedPreferences + JSON)
├── MatchHistoryScreen.kt      # Match history UI with share/export
├── CameraOverlay.kt           # Camera preview & video recording overlay
└── MatchViewModelFactory.kt   # ViewModel factory
```

### Build (Android)

```bash
./gradlew assembleDebug
```

---

## iOS App (beta)

**Bundle ID:** `com.padelpulse.app`
**Deployment Target:** iOS 17.0+ | **Device:** Universal (iPhone + iPad, landscape-locked)
**Version:** 1.0.0-beta

### Tech Stack (iOS)

- Swift 5.9+ / SwiftUI with `@Observable` macro (iOS 17)
- AVFoundation for camera preview & video recording
- UserDefaults + Codable for match history + in-progress match persistence
- MPRemoteCommandCenter + GCKeyboard for Bluetooth remote & keyboard input
- `AudioServicesPlaySystemSound` for sound effects (zero-dependency)
- `ImageRenderer` for share card image generation
- `Canvas` + `TimelineView` for confetti particle animation
- XcodeGen for project generation (`ios/project.yml`)
- Localized: English, German, Spanish

### Structure (iOS)

```
ios/PadelPulse/
├── App/PadelPulseApp.swift              # @main, scene config, keyboard shortcuts, state persistence hooks
├── Models/
│   ├── MatchState.swift                  # MatchState struct (Codable) + PadelScoring enum
│   ├── SavedMatch.swift                  # SavedMatch (Codable, Identifiable) + share text
│   └── TeamColor.swift                   # Default colors + Color↔RGB serialization
├── ViewModels/MatchViewModel.swift       # @Observable, match state, undo stack, persistence, sound
├── Storage/MatchStorage.swift            # UserDefaults + Codable match history persistence
├── Views/
│   ├── ScoreBoardView.swift              # Root split-screen scoreboard, toolbar, set pills
│   ├── TeamPanelView.swift               # Team half-panel (giant score, games box, team name)
│   ├── SettingsSidebarView.swift         # Slide-in settings with pill-badge values, toggles
│   ├── MatchHistoryView.swift            # ATP-style match history cards + share (text & image)
│   ├── MatchOverOverlayView.swift        # Confetti, staggered entrance, winner glow, share
│   ├── OnboardingOverlayView.swift       # First-launch hint overlay
│   ├── ServePickOverlayView.swift        # Pre-match "who serves first?" picker (remote-aware)
│   ├── CameraOverlayView.swift           # AVFoundation camera + recording
│   ├── MatchTimerView.swift              # Match timer pill
│   ├── WallClockView.swift               # Current time-of-day pill (HH:mm, system locale)
│   ├── CreditsView.swift                 # Upstream repo + SVG icon attribution (CC BY 3.0)
│   └── Components/
│       ├── ColorSwatchPicker.swift       # 8-color inline preset picker
│       ├── ConfettiView.swift            # Canvas-based particle animation (60 particles)
│       ├── MatchScoreCardView.swift      # 600x315 share card for image export
│       ├── NameFieldView.swift           # Team name text field
│       ├── PadelRacketView.swift         # SVG asset, template-tinted to gold (paired with L/R glyph in TeamPanelView)
│       └── SetScorePill.swift            # ATP-style set pill (winner bold, loser dim)
├── Services/
│   ├── CameraService.swift               # AVCaptureSession management (serial session queue)
│   ├── LanguageService.swift             # Runtime app-language switcher (bundle swizzle + Environment locale)
│   ├── RemoteInputService.swift          # Bluetooth media remote handling
│   └── SoundService.swift                # System sounds with mute toggle
├── Utilities/
│   ├── Constants.swift                   # Colors, LayoutMetrics (50+ scaled properties)
│   ├── DefaultsKeys.swift                # Central registry of every UserDefaults key
│   ├── HapticService.swift               # UIImpactFeedbackGenerator wrappers (+ prepareAll)
│   └── ShareImageRenderer.swift          # ImageRenderer wrapper for share cards
└── Resources/
    ├── Assets.xcassets/                  # AppIcon, LaunchLogo, DarkBg, GoldColor
    ├── en.lproj/Localizable.strings      # English (~95 strings)
    ├── de.lproj/Localizable.strings      # German
    └── es.lproj/Localizable.strings      # Spanish
```

### Build (iOS)

```bash
cd ios
xcodegen generate        # Generate .xcodeproj from project.yml
xcodebuild -project PadelPulse.xcodeproj -scheme PadelPulse \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5)' build
xcodebuild -project PadelPulse.xcodeproj -scheme PadelPulseTests \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5)' test
```

### iOS Features (beyond Android parity)

- **Adaptive layout** — `LayoutMetrics` scales 50+ dimensions from iPhone SE to iPad Pro 13" (dual-axis on iPhone, width-only on iPad)
- **Haptic feedback** — UIImpactFeedbackGenerator for scoring, settings, game/match events
- **Match state persistence** — in-progress match survives app kill (UserDefaults + Codable)
- **iPad keyboard shortcuts** — Cmd+Z (undo), Cmd+N (new match), Cmd+Shift+S (swap), Cmd+, (settings)
- **Onboarding overlay** — first-launch hints, dismissed permanently via `@AppStorage`
- **Sound effects** — system sounds for points, games, match over (toggleable in settings)
- **Share as image** — `ImageRenderer` renders a 600x315 score card to `UIImage`
- **Animated match-over** — confetti particles, staggered entrance, winner glow pulse, trophy fly-in
- **8 team color presets** — inline swatch picker (Navy, Crimson, Forest, Purple, Teal, Amber, Graphite, Rose)
- **Fun random team names** — 30 padel-themed names assigned randomly on new match
- **Compact set scores** — completed sets shown as horizontal pills top-right below the timer
- **Camera as opt-in** — camera overlay toggle in settings, button only visible when enabled
- **Runtime language switcher** — Auto / EN / DE / ES togglable in settings, no app restart (bundle swizzle + `.id(...)` re-render)
- **Serve-pick overlay** — before every fresh match, tap a team tile or press its Bluetooth-remote button to set the first server. Play/Pause (or the inline gold swap button) flips the iPad's left/right panel assignment so it matches the court — fully operable from the remote. SKIP button or tap outside the tiles to dismiss. Toggle in Settings → "Ask Who Serves".
- **Wall clock pill** — current time-of-day shown next to the match timer
- **Credits page** — linked from settings, attributes upstream Point-Counter repo and Noun Project SVG icon

### iOS UI Layout

- **Top-left toolbar:** icon-only buttons — Undo, Swap, [Camera], New Match (uniform 44x44pt touch targets)
- **Top-right:** Clock + Match Timer + Settings gear (same row), completed set pills horizontally below
- **Center:** two team panels with team name above giant score, compact number-only games box in inner corner
- **Serve indicator:** big gold L/R letter + padel-racket icon paired in the court-side corner of the serving panel (L = deuce / left, R = ad / right; Spanish localization renders as I/D — Izquierda/Derecha), plus a pulsing gold border with rounded outer corners around the whole serving panel (static at 0.85 opacity under Reduce Motion)

### iOS-specific notes

- Universal app (iPhone + iPad), landscape-locked on both devices.
- `LayoutMetrics` uses width-only scaling on iPad (preserving original layout) and dual-axis `min(widthScale, heightScale)` on iPhone with per-metric min clamps for readability on small screens.
- Volume keys cannot be intercepted on iOS (OS restriction). Bluetooth remotes use Media Next/Prev + Play/Pause via MPRemoteCommandCenter.
- Camera requires real device (not simulator).
- iPad uses `UIRequiresFullScreen = YES` (no Split View).
- Launch screen uses `UILaunchScreen` dict in Info.plist (not a storyboard).
- `ScoreBoardButtonStyle` uses a ZStack with fixed 44x44 frame to guarantee uniform touch targets regardless of SF Symbol dimensions.
- `project.yml` pins `DEVELOPMENT_TEAM` (`P38L5RD8CU`, personal) + `CODE_SIGN_STYLE: Automatic` so xcodegen regenerations don't wipe the Signing team. Required for on-device installs; simulator builds don't care.

---

## Architecture (shared concepts)

- `PadelScoring` — pure scoring logic (stateless, testable), handles standard/golden-point/tiebreak rules
- `MatchViewModel` — holds `MatchState`, undo history stack, team config, timer state
- `MatchStorage` / `SavedMatch` — JSON persistence (SharedPreferences on Android, UserDefaults on iPadOS)
- Single-screen app, landscape-locked, full-screen immersive, screen stays on

## Key Behaviors

- Bluetooth media controllers for hands-free scoring
- Score transitions with bounce/slide animations
- Match auto-saves on completion, shareable via platform share sheet
- Sides can be swapped (mirrors left/right panels)
- Serve indicator rotates each point (court-side L/R) and each game (server flip); iOS panel additionally glows gold when its team serves
- No network calls, no analytics, no ads
