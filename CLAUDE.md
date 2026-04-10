# CLAUDE.md — Padel Pulse

## Project Overview

Cross-platform padel & tennis courtside scoreboard. Fork of `DominikLindorfer/Point-Counter` (upstream remote already configured).

Both platforms share identical scoring logic and feature set.

---

## Android App

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

## iPadOS App

**Bundle ID:** `com.padelpulse.app`
**Deployment Target:** iPadOS 17.0+ | **Device:** iPad only

### Tech Stack (iPadOS)

- Swift 5.9+ / SwiftUI with `@Observable` macro (iOS 17)
- AVFoundation for camera preview & video recording
- UserDefaults + Codable for match history persistence
- MPRemoteCommandCenter + GCKeyboard for Bluetooth remote input
- XcodeGen for project generation (`ios/project.yml`)

### Structure (iPadOS)

```
ios/PadelPulse/
├── App/PadelPulseApp.swift              # @main, scene config, remote input setup
├── Models/
│   ├── MatchState.swift                  # MatchState struct + PadelScoring enum
│   ├── SavedMatch.swift                  # SavedMatch (Codable, Identifiable)
│   └── TeamColor.swift                   # 8 color presets
├── ViewModels/MatchViewModel.swift       # @Observable, match state + undo stack
├── Storage/MatchStorage.swift            # UserDefaults + Codable persistence
├── Views/
│   ├── ScoreBoardView.swift              # Root split-screen scoreboard
│   ├── TeamPanelView.swift               # Team half-panel (giant score, games box)
│   ├── SettingsSidebarView.swift         # Slide-in settings
│   ├── MatchHistoryView.swift            # Match history + cards + share
│   ├── MatchOverOverlayView.swift        # Trophy + winner overlay
│   ├── CameraOverlayView.swift           # AVFoundation camera + recording
│   ├── MatchTimerView.swift              # Timer pill
│   ├── ServeSideIndicatorView.swift      # L/R serve indicator
│   └── Components/                       # ColorPickerGrid, NameFieldView, SetScorePill
├── Services/
│   ├── CameraService.swift               # AVCaptureSession management
│   └── RemoteInputService.swift          # Bluetooth media remote handling
└── Utilities/Constants.swift             # Shared colors & dimensions
```

### Build (iPadOS)

```bash
cd ios
xcodegen generate        # Generate .xcodeproj from project.yml
# Then open PadelPulse.xcodeproj in Xcode and build
```

### iPadOS-specific notes

- Volume keys cannot be intercepted on iPadOS (OS restriction). Bluetooth remotes use Media Next/Prev + Play/Pause via MPRemoteCommandCenter.
- Camera requires real device (not simulator).
- App is landscape-locked with `UIRequiresFullScreen = YES` (no Split View).

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
- Serve indicator auto-rotates each game, shows L/R side
- No network calls, no analytics, no ads
