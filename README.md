# Padel & Tennis Point Counter

A simple, full-screen scoreboard app for Android tablets. Designed to be placed courtside so everyone can see the score during a match. 

Works with **Bluetooth media controller buttons** so you can score points without touching the screen.

## Screenshots

![Courtside_Watch](https://github.com/user-attachments/assets/5d866f24-f629-4d10-b6ff-5cc8576e2cc9)


https://github.com/user-attachments/assets/ad0aed53-c02c-48b0-93c0-9c121f993f9b

## Bluetooth Setup

The app works with cheap Bluetooth media controllers (like wrist-mounted remotes). These pair as standard HID devices — no special app permissions needed.

### Default Button Mapping

| Button | Action |
|--------|--------|
| Volume Up | Team 1 scores |
| Volume Down | Team 2 scores |
| Next Track (>>) | Team 1 scores |
| Previous Track (<<) | Team 2 scores |
| Play/Pause | Undo |

<img width="1779" height="1194" alt="Control" src="https://github.com/user-attachments/assets/a66de593-18af-417a-b510-c643b2aa0ab2" />


### Pairing

1. Put your Bluetooth controller in pairing mode
2. Open Android **Settings > Bluetooth** and pair the device
3. Open Padel Counter — button presses are automatically captured

## Features

- Full-screen scoreboard with huge, readable score numbers
- Proper padel scoring: points (0/15/30/40/deuce/AD), games, sets, tiebreaks
- Undo button for mistakes
- Bluetooth HID button support (media controllers, camera shutters)
- **Golden Point** mode (no advantage at 40-40) — toggle on/off
- **Tiebreak** — automatic tiebreak scoring at 6-6
- Configurable sets to win (infinite, 1, 2, or 3)
- **Serve side indicator** (right/left) — alternates every point
- **Serving team indicator** — shows which team serves, auto-rotates each game
- **Match timer** — elapsed time display, starts on first point
- **Settings sidebar** — customize team names, team colors (8 presets), scoring mode, sets, and serving team
- **Swap sides** — switch team positions on screen when teams change court sides
- **Match history** — completed matches auto-save with scores, duration, and statistics
- **Share/export** — share match results via WhatsApp, email, or any app
- **Match statistics** — points won per team shown as percentages
- Animated score transitions with bounce effects
- Immersive full-screen, landscape-locked, screen stays on
- Match over overlay with trophy animation

## Settings Sidebar

Tap the gear icon (top-right) to access:
- **Team names** — customize up to 16 characters each
- **Team colors** — choose from 8 presets (Blue, Red, Green, Purple, Orange, Cyan, Pink, Yellow)
- **Scoring mode** — toggle between Advantage and Golden Point
- **Sets to win** — cycle through infinite / 1 / 2 / 3
- **Serving team** — tap to toggle which team serves
- **Match History** — view all completed matches

### Customizing Button Mapping (Dev-Mode)

If your controller sends different key codes, edit the `onKeyDown` method in `MainActivity.kt`. Android key code constants are listed in the [KeyEvent documentation](https://developer.android.com/reference/android/view/KeyEvent).

## Building

1. Open the project in Android Studio
2. Sync Gradle
3. Run on a device or emulator (minimum SDK 26 / Android 8.0)

## Project Structure

```
app/src/main/java/io/github/dominiklindorfer/padelcounter/
  MainActivity.kt          -- UI (ScoreBoard, TeamPanel, SettingsSidebar, MatchTimer)
  MatchState.kt            -- Scoring logic (MatchState, PadelScoring, MatchViewModel)
  MatchStorage.kt          -- Match history persistence (SharedPreferences + JSON)
  MatchHistoryScreen.kt    -- Match history UI with share/export
  MatchViewModelFactory.kt -- ViewModel factory for dependency injection
```

## Privacy Policy

This app collects no data. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for details.

## License

MIT License — see [LICENSE](LICENSE) for details.
