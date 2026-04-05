<p align="center">
  <img src="https://github.com/user-attachments/assets/5d866f24-f629-4d10-b6ff-5cc8576e2cc9" alt="Point Counter — courtside scoreboard" width="720" />
</p>

<h1 align="center">Point Counter</h1>

<p align="center">
  <b>A courtside scoreboard for padel & tennis — big scores, Bluetooth remote control, zero setup.</b><br><br>
  <b>No ads. Free and open source!</b>
</p>

<p align="center">
  <a href="https://github.com/DominikLindorfer/Padelcounter/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/Platform-Android-green.svg" alt="Platform: Android">
  <img src="https://img.shields.io/badge/Min%20SDK-26%20(Android%208.0)-brightgreen.svg" alt="Min SDK 26">
  <img src="https://img.shields.io/badge/Kotlin-Jetpack%20Compose-7F52FF.svg" alt="Kotlin + Jetpack Compose">
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

## Setup that I personally use

All you need is an Android tablet, a stand, and a Bluetooth remote. This is what I use but modify as suits you best:

|  | Link |
|------|------|
| **Android Tablet** — Xiaomi Redmi Pad Pro | [Amazon.de](https://www.amazon.de/dp/B0FJ9234ZX) |
| **Tablet Stand** | [Amazon.de](https://www.amazon.de/dp/B0DRXP3V6W) |
| **Bluetooth Remote** | [Amazon.de](https://www.amazon.de/dp/B08MKJX4MH) |

## Features

| | |
|---|---|
| **Full padel/tennis scoring** | 0 / 15 / 30 / 40 / Deuce / AD — games, sets, and tiebreaks |
| **Golden Point mode** | No advantage at 40-40 — toggle on or off |
| **Automatic tiebreaks** | Kicks in at 6-6 with proper tiebreak scoring |
| **Configurable sets** | Play to 1, 2, or 3 sets (or infinite) |
| **Bluetooth remote** | Score with a wrist-mounted media controller — no screen touch needed |
| **Serve indicator** | Shows serving team and serve side (L/R), auto-rotates each game |
| **Match timer** | Elapsed time starts on the first point |
| **Team customization** | Custom names and 8 color presets per team |
| **Swap sides** | One tap to mirror teams when you switch court ends |
| **Match history** | Auto-saves completed matches with scores, duration, and stats |
| **Share results** | Export match results via WhatsApp, email, or any app |
| **Undo** | Made a mistake? One button to go back |
| **Immersive display** | Full-screen, landscape-locked, screen stays on |
| **Animated transitions** | Score changes with smooth bounce effects and a trophy on match point |

## Bluetooth Setup

The app works with cheap Bluetooth media controllers (like wrist-mounted remotes). They pair as standard HID devices — no special permissions needed.

<p align="center">
  <img src="https://github.com/user-attachments/assets/a66de593-18af-417a-b510-c643b2aa0ab2" alt="Bluetooth remote control" width="600" />
</p>

### Button Mapping

| Button | Action |
|--------|--------|
| Volume Up | Team 1 scores |
| Volume Down | Team 2 scores |
| Next Track `>>` | Team 1 scores |
| Previous Track `<<` | Team 2 scores |
| Play / Pause | Undo |

### Pairing

1. Put your Bluetooth controller in pairing mode
2. Open Android **Settings > Bluetooth** and pair the device
3. Open Point Counter — button presses are captured automatically

> **Tip:** If your controller sends different key codes, you can customize the mapping in `MainActivity.kt` — see the [KeyEvent docs](https://developer.android.com/reference/android/view/KeyEvent).

## Building from Source

```bash
# Clone the repository
git clone https://github.com/DominikLindorfer/Point-Counter.git

# Open in Android Studio, sync Gradle, and run
# Min SDK 26 (Android 8.0) · Target SDK 36 (Android 15)
```

## Project Structure

```
app/src/main/java/io/github/dominiklindorfer/padelcounter/
├── MainActivity.kt            UI — ScoreBoard, TeamPanel, SettingsSidebar, MatchTimer
├── MatchState.kt              Scoring logic — MatchState, PadelScoring, MatchViewModel
├── MatchStorage.kt            Match history persistence (SharedPreferences + JSON)
├── MatchHistoryScreen.kt      Match history UI with share/export
├── CameraOverlay.kt           Camera preview & video recording overlay
└── MatchViewModelFactory.kt   ViewModel factory
```

## Tech Stack

- **Kotlin** + **Jetpack Compose** (Material 3)
- **CameraX** for optional video capture
- **AndroidX Lifecycle** + ViewModel
- No network calls, no third-party analytics, no ads

## Privacy

This app collects **zero data**. No accounts, no analytics, no internet access. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## License

MIT — see [LICENSE](LICENSE) for details.

---

<p align="center">
  Built for the court, not the cloud.
</p>
