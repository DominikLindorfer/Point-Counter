<p align="center">
  <img src="https://github.com/user-attachments/assets/5d866f24-f629-4d10-b6ff-5cc8576e2cc9" alt="Padel Pulse — courtside scoreboard" width="720" />
</p>

<h1 align="center">Padel Pulse</h1>

<p align="center">
  <b>A courtside scoreboard for padel & tennis — big scores, Bluetooth remote control, zero setup.</b><br><br>
  <b>No ads. No logins. Free and open source!</b>
</p>

<p align="center">
  <a href="https://github.com/DominikLindorfer/Padelcounter/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/Platform-Android-green.svg" alt="Platform: Android">
  <img src="https://img.shields.io/badge/Platform-iOS_(iPhone_%26_iPad)-orange.svg" alt="Platform: iOS (iPhone & iPad)">
  <img src="https://img.shields.io/badge/Kotlin-Jetpack%20Compose-7F52FF.svg" alt="Kotlin + Jetpack Compose">
  <img src="https://img.shields.io/badge/Swift-SwiftUI-FA7343.svg" alt="Swift + SwiftUI">
</p>

---

Place your tablet courtside and everyone can read the score. Pair a cheap Bluetooth remote and score points without leaving the court.

<p align="center">

https://github.com/user-attachments/assets/ad0aed53-c02c-48b0-93c0-9c121f993f9b

</p>

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=io.github.dominiklindorfer.padelcounter">
    <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Get it on Google Play" height="80">
  </a>
</p>

## Features

| | |
|---|---|
| **Full padel/tennis scoring** | 0 / 15 / 30 / 40 / Deuce / AD — games, sets, and tiebreaks |
| **Golden Point mode** | No advantage at 40-40 — one point decides |
| **Automatic tiebreaks** | Kicks in at 6-6 with proper tiebreak scoring |
| **Configurable sets** | Play to 1, 2, or 3 sets (or unlimited) |
| **Bluetooth remote** | Score with a wrist-mounted media controller — hands-free |
| **Serve indicator** | Shows serving team and serve side (L/R), auto-rotates each game |
| **Match timer** | Elapsed time starts on the first point |
| **Team customization** | Custom names and colors per team |
| **Swap sides** | One tap to mirror teams when you switch court ends |
| **Match history** | Auto-saves completed matches with scores, duration, and stats |
| **Share results** | Export match results as text or image via any app |
| **Undo** | Made a mistake? One button to go back |
| **Immersive display** | Full-screen, landscape-locked, screen stays on |
| **Animated transitions** | Score changes with smooth bounce effects and a trophy on match point |

## Platforms

### Android (released)

Available on Google Play. Built with Kotlin + Jetpack Compose.

See [`app/`](app/) for the Android source code.

### iOS — iPhone & iPad

Native universal app built with Swift + SwiftUI. Landscape-only on both devices, adaptive layout from iPhone SE to iPad Pro 13". Includes haptic feedback, sound effects, match state persistence, keyboard shortcuts, confetti animations, and localization (EN/DE/ES).

See [`ios/README.md`](ios/README.md) for full documentation.

## Recommended Setup

All you need is a tablet, a stand, and a Bluetooth remote:

|  | Link |
|------|------|
| **Android Tablet** — Xiaomi Redmi Pad Pro | [Amazon.de](https://www.amazon.de/dp/B0FJ9234ZX) |
| **iPad** — any iPad running iPadOS 17+ | |
| **Tablet Stand** | [Amazon.de](https://www.amazon.de/dp/B07B9QC2R3) |
| **Bluetooth Remote** | [Amazon.de](https://www.amazon.de/dp/B0DRXP3V6W) |

## Bluetooth Remote

The app works with cheap Bluetooth media controllers (like wrist-mounted remotes). They pair as standard HID devices — no special permissions needed.

<p align="center">
  <img src="https://github.com/user-attachments/assets/a66de593-18af-417a-b510-c643b2aa0ab2" alt="Bluetooth remote control" width="600" />
</p>

### Button Mapping

| Button | Android | iPadOS |
|--------|---------|--------|
| Volume Up | Team 1 scores | *(not available — OS restriction)* |
| Volume Down | Team 2 scores | *(not available — OS restriction)* |
| Next Track `>>` | Team 1 scores | Team 1 scores |
| Previous Track `<<` | Team 2 scores | Team 2 scores |
| Play / Pause | Undo | Undo |

> **Tip (Android):** If your controller sends different key codes, you can customize the mapping in `MainActivity.kt` — see the [KeyEvent docs](https://developer.android.com/reference/android/view/KeyEvent).

## Building from Source

### Android

```bash
git clone https://github.com/DominikLindorfer/Point-Counter.git
# Open in Android Studio, sync Gradle, and run
# Min SDK 26 (Android 8.0) · Target SDK 36 (Android 15)
```

### iOS (iPhone & iPad)

```bash
cd ios
xcodegen generate        # Generate .xcodeproj from project.yml
open PadelPulse.xcodeproj
# Build for iPhone or iPad in Xcode 16+ (requires iOS 17.0+)
```

## Project Structure

```
├── app/                    # Android app (Kotlin + Jetpack Compose)
├── ios/                    # iOS app (Swift + SwiftUI, iPhone + iPad) — see ios/README.md
├── CLAUDE.md               # Dev context for AI-assisted development
└── README.md               # This file
```

## Privacy

This app collects **zero data**. No accounts, no analytics, no internet access. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## License

MIT — see [LICENSE](LICENSE) for details.

---

<p align="center">
  Built for the court, not the cloud.
</p>
