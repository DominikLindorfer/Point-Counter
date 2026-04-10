# Padel Pulse — iPadOS App

<p align="center">
  <img src="https://img.shields.io/badge/iPadOS-17.0+-blue.svg" alt="iPadOS 17.0+">
  <img src="https://img.shields.io/badge/Swift_5.9-SwiftUI-FA7343.svg" alt="Swift 5.9 + SwiftUI">
  <img src="https://img.shields.io/badge/Status-Beta-orange.svg" alt="Status: Beta">
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT">
</p>

Native iPad scoreboard for padel & tennis. Landscape-locked, full-screen, designed for courtside use with touch or Bluetooth remote.

---

## Quick Start

```bash
xcodegen generate                    # Generate .xcodeproj from project.yml
open PadelPulse.xcodeproj            # Build & run in Xcode 16+ for iPad
```

Requires iPadOS 17.0+. iPad only (no iPhone). Camera features require a real device.

## Features

### Core Scoring
- Full padel/tennis scoring: 0 / 15 / 30 / 40 / Deuce / AD
- Golden Point mode (no advantage at 40-40)
- Automatic tiebreaks at 6-6
- Configurable sets: 1, 2, 3, or unlimited
- Undo with full history stack

### Display & UX
- **Adaptive layout** — `LayoutMetrics` scales 50+ dimensions to any iPad screen
- **Giant score display** — readable from across the court
- **Team customization** — custom names + 8 color presets (Navy, Crimson, Forest, Purple, Teal, Amber, Graphite, Rose)
- **Fun random team names** — 30 padel-themed names on each new match
- **Serve indicator** — L/R side with pulse animation, auto-rotates each game
- **Compact set scores** — completed sets as pills in the top-right corner
- **Match timer** — elapsed time from first point
- **Swap sides** — mirror teams when switching court ends

### Premium Features
- **Haptic feedback** — tactile responses for scoring, games, match events
- **Sound effects** — system sounds for points, games, match over (toggleable)
- **Match state persistence** — in-progress match survives app kill and restart
- **Animated match-over** — confetti particles, staggered entrance, winner glow, trophy fly-in
- **Share as image** — rendered 600x315 score card via `ImageRenderer`
- **Onboarding overlay** — first-launch hints, dismissed permanently
- **Camera overlay** — optional PiP camera (opt-in via settings)

### Input
- **Touch** — tap left/right panel to score
- **Bluetooth remote** — Next/Prev Track for scoring, Play/Pause for undo
- **iPad keyboard** — Cmd+Z (undo), Cmd+N (new match), Cmd+S (swap), Cmd+, (settings), Arrow keys + Space via GCKeyboard

### Localization
- English, German, Spanish (~95 strings each)

## Architecture

```
PadelPulse/
├── App/PadelPulseApp.swift              # @main, scene config, keyboard shortcuts, persistence hooks
├── Models/
│   ├── MatchState.swift                  # MatchState (Codable) + PadelScoring (stateless logic)
│   ├── SavedMatch.swift                  # SavedMatch (Codable) + share text builder
│   └── TeamColor.swift                   # Default colors + Color↔RGB serialization
├── ViewModels/MatchViewModel.swift       # @Observable — state, undo stack, persistence, sound
├── Storage/MatchStorage.swift            # UserDefaults + Codable match history
├── Views/
│   ├── ScoreBoardView.swift              # Root view — panels, toolbar, set pills, overlays
│   ├── TeamPanelView.swift               # Team half — giant score, GAMES box, team name
│   ├── SettingsSidebarView.swift         # Slide-in settings — pill badges, chevrons, toggles
│   ├── MatchHistoryView.swift            # History cards + share (text & image)
│   ├── MatchOverOverlayView.swift        # Confetti, staggered entrance, winner glow, share
│   ├── OnboardingOverlayView.swift       # First-launch hints
│   ├── CameraOverlayView.swift           # AVFoundation camera + recording
│   ├── MatchTimerView.swift              # Timer pill
│   ├── ServeSideIndicatorView.swift      # L/R serve indicator with pulse
│   └── Components/
│       ├── ColorSwatchPicker.swift       # 8-color inline preset picker
│       ├── ConfettiView.swift            # Canvas + TimelineView particle animation
│       ├── MatchScoreCardView.swift      # 600x315 share card
│       ├── NameFieldView.swift           # Team name text field
│       └── SetScorePill.swift            # Set score display pill
├── Services/
│   ├── CameraService.swift               # AVCaptureSession management
│   ├── RemoteInputService.swift          # MPRemoteCommandCenter + GCKeyboard
│   └── SoundService.swift                # AudioServicesPlaySystemSound + mute toggle
├── Utilities/
│   ├── Constants.swift                   # Colors + LayoutMetrics (50+ scaled properties)
│   ├── HapticService.swift               # UIImpactFeedbackGenerator wrappers
│   └── ShareImageRenderer.swift          # ImageRenderer → UIImage
└── Resources/
    ├── Assets.xcassets/                  # AppIcon, LaunchLogo, DarkBg, GoldColor
    ├── en.lproj/Localizable.strings
    ├── de.lproj/Localizable.strings
    └── es.lproj/Localizable.strings
```

## UI Layout

```
┌─────────────────────────────────────────────────────┐
│ [↩] [⇄] [🎥] [↻]              [⏱ 1:23] [⚙]       │
│                                   S1 6:0             │
│   ┌──────┐                        S2 4:3  ┌──────┐  │
│   │GAMES │                                │GAMES │  │
│   │  3   │                                │  2   │  │
│   └──────┘                                └──────┘  │
│          30                    15                    │
│                                                      │
│      CHIQUITAS          COURT JESTERS                │
│                 ← 🎾 RIGHT →                         │
└─────────────────────────────────────────────────────┘
```

- **Top-left:** icon-only toolbar (Undo, Swap, Camera*, New Match) — 44x44pt touch targets
- **Top-right:** Timer + Settings (same row), completed set pills below
- **Center:** two team panels with giant score, GAMES box at inner corner
- **Bottom:** team names, serve side indicator

*Camera button only visible when enabled in settings.

## Tech Stack

- **Swift 5.9** / **SwiftUI** with `@Observable` macro (iOS 17)
- **AVFoundation** for camera preview & video recording
- **UserDefaults + Codable** for match history + in-progress match persistence
- **MPRemoteCommandCenter + GCKeyboard** for Bluetooth remote & keyboard input
- **AudioServicesPlaySystemSound** for sound effects (zero-dependency)
- **ImageRenderer** for share card generation
- **Canvas + TimelineView** for confetti particle animation
- **XcodeGen** for project generation (`project.yml`)

## Running Tests

```bash
xcodegen generate
xcodebuild -project PadelPulse.xcodeproj -scheme PadelPulseTests \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5)' test
```

## Notes

- Volume keys cannot be intercepted on iPadOS (OS restriction). Use Media Next/Prev via Bluetooth remote.
- Camera requires a real device (not simulator).
- App is landscape-locked with `UIRequiresFullScreen = YES` (no Split View/Slide Over).
- Launch screen uses `UILaunchScreen` dict in Info.plist (not a storyboard).
- `ScoreBoardButtonStyle` uses ZStack with fixed 44x44 frame for uniform touch targets.
- No network calls, no analytics, no ads, no third-party dependencies.
