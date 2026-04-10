<p align="center">
  <img src="https://github.com/user-attachments/assets/5d866f24-f629-4d10-b6ff-5cc8576e2cc9" alt="Padel Pulse — courtside scoreboard" width="720" />
</p>

<h1 align="center">Padel Pulse</h1>

<p align="center">
  <b>A premium courtside scoreboard for padel & tennis on iPad.</b><br>
  <b>Big scores. Bluetooth remote. Zero setup. No ads.</b>
</p>

<p align="center">
  <a href="https://github.com/DominikLindorfer/Padelcounter/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/iPadOS-17.0+-blue.svg" alt="iPadOS 17.0+">
  <img src="https://img.shields.io/badge/Swift-SwiftUI-FA7343.svg" alt="Swift + SwiftUI">
  <img src="https://img.shields.io/badge/Status-Beta-orange.svg" alt="Status: Beta">
  <img src="https://img.shields.io/badge/Platform-Android-green.svg" alt="Platform: Android">
</p>

---

Place your iPad courtside and everyone can read the score from across the court. Pair a cheap Bluetooth remote and score points without touching the screen.

<p align="center">

https://github.com/user-attachments/assets/ad0aed53-c02c-48b0-93c0-9c121f993f9b

</p>

## Features

| | |
|---|---|
| **Full padel/tennis scoring** | 0 / 15 / 30 / 40 / Deuce / AD — games, sets, and tiebreaks |
| **Golden Point mode** | No advantage at 40-40 — one point decides |
| **Automatic tiebreaks** | Kicks in at 6-6 with proper tiebreak scoring |
| **Configurable sets** | Play to 1, 2, or 3 sets (or unlimited) |
| **Bluetooth remote** | Score with a wrist-mounted media controller — hands-free |
| **Serve indicator** | Shows L/R serve side, auto-rotates each game |
| **Match timer** | Elapsed time starts on the first point |
| **Team customization** | Custom names + 8 color presets per team |
| **Swap sides** | One tap to mirror teams when you switch court ends |
| **Match history** | Auto-saves completed matches with scores, duration, and stats |
| **Share results** | Export as text or as a rendered score card image |
| **Undo** | Made a mistake? One button to go back |
| **Adaptive layout** | Scales to any iPad screen size |
| **Haptic feedback** | Tactile responses for scoring and UI interactions |
| **Match persistence** | In-progress match survives app kill and restart |
| **Keyboard shortcuts** | Cmd+Z (undo), Cmd+N (new match), Cmd+S (swap sides) |
| **Sound effects** | System sounds for points, games, match over (toggleable) |
| **Onboarding** | First-launch hints for new users |
| **Match-over celebration** | Confetti, winner glow, staggered animations |
| **Camera overlay** | Optional picture-in-picture camera (opt-in via settings) |
| **Localization** | English, German, Spanish |
| **Immersive display** | Full-screen, landscape-locked, screen stays on |

## Recommended Setup

All you need is an iPad, a stand, and a Bluetooth remote:

|  | Link |
|------|------|
| **iPad** — any iPad running iPadOS 17+ | |
| **Tablet Stand** | [Amazon.de](https://www.amazon.de/dp/B0DRXP3V6W) |
| **Bluetooth Remote** | [Amazon.de](https://www.amazon.de/dp/B08MKJX4MH) |

> Also available on **Android** — [Get it on Google Play](https://play.google.com/store/apps/details?id=io.github.dominiklindorfer.padelcounter)

## Bluetooth Remote

The app works with cheap Bluetooth media controllers (like wrist-mounted remotes). They pair as standard HID devices — no special permissions needed.

<p align="center">
  <img src="https://github.com/user-attachments/assets/a66de593-18af-417a-b510-c643b2aa0ab2" alt="Bluetooth remote control" width="600" />
</p>

### Button Mapping

| Button | Action |
|--------|--------|
| Next Track `>>` | Team 1 scores |
| Previous Track `<<` | Team 2 scores |
| Play / Pause | Undo |

> On Android, Volume Up/Down also work for scoring.

### iPad Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd + Z` | Undo last point |
| `Cmd + N` | New match |
| `Cmd + S` | Swap sides |
| `Cmd + ,` | Open settings |
| `Space` | Undo (via GCKeyboard) |
| `Arrow keys` | Score points (via GCKeyboard) |

## Building from Source

### iPadOS

```bash
cd ios
xcodegen generate                    # Generate .xcodeproj from project.yml
open PadelPulse.xcodeproj            # Open in Xcode 16+, build for iPad
```

Requires iPadOS 17.0+. Runs on iPad only (landscape-locked). Camera features require a real device.

### Android

```bash
git clone https://github.com/DominikLindorfer/Point-Counter.git
# Open in Android Studio, sync Gradle, and run
# Min SDK 26 (Android 8.0) · Target SDK 36
```

## Tech Stack

### iPadOS
- **Swift 5.9** + **SwiftUI** with `@Observable` (iOS 17)
- **AVFoundation** for camera + video recording
- **UserDefaults + Codable** for match persistence
- **XcodeGen** for project generation from `project.yml`
- **ImageRenderer** for share card generation
- **Canvas + TimelineView** for particle animations

### Android
- **Kotlin** + **Jetpack Compose** (Material 3)
- **CameraX** for optional video capture
- **AndroidX Lifecycle** + ViewModel

Both platforms: **No network calls, no analytics, no ads.**

## Privacy

This app collects **zero data**. No accounts, no analytics, no internet access. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## License

MIT — see [LICENSE](LICENSE) for details.

---

<p align="center">
  Built for the court, not the cloud.
</p>
