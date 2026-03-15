# Padel Counter

A simple, full-screen padel scoreboard app for Android tablets. Designed to be placed courtside so everyone can see the score during a match.

Supports **Bluetooth media controller buttons** so you can score points without touching the screen.

## Features

- Full-screen scoreboard with huge, readable score numbers
- Proper padel scoring: points (0/15/30/40/deuce/AD), games, sets, tiebreaks
- **Golden Point** mode (no advantage at 40-40) — toggle on/off mid-match
- Configurable sets to win (infinite, 1, 2, or 3)
- Serve side indicator (right/left) — alternates every point
- Undo button for mistakes
- Bluetooth HID button support (media controllers, camera shutters)
- Animated score transitions
- Immersive full-screen, landscape-locked, screen stays on

## Screenshots

> Add your screenshots here

## How to Use

1. **Touch controls**: Tap the left (blue) half to score for Team 1, tap the right (red) half for Team 2
2. **Buttons at the top**:
   - **UNDO** — undo the last point
   - **ADVANTAGE / GOLDEN PT** — toggle between standard deuce/advantage scoring and golden point (next point wins at 40-40)
   - **SETS** — cycle through infinite / 1 / 2 / 3 sets to win
   - **NEW MATCH** — reset everything

## Bluetooth Setup

The app works with cheap Bluetooth media controllers (like wrist-mounted remotes). These pair as standard HID devices — no special app permissions needed.

### Pairing

1. Put your Bluetooth controller in pairing mode
2. Open Android **Settings > Bluetooth** and pair the device
3. Open Padel Counter — button presses are automatically captured

### Default Button Mapping

| Button | Action |
|--------|--------|
| Volume Up | Team 1 (blue) scores |
| Volume Down | Team 2 (red) scores |
| Next Track (>>) | Team 1 (blue) scores |
| Previous Track (<<) | Team 2 (red) scores |
| Play/Pause | Undo |

### Customizing Button Mapping

If your controller sends different key codes, edit the `onKeyDown` method in `MainActivity.kt`. Android key code constants are listed in the [KeyEvent documentation](https://developer.android.com/reference/android/view/KeyEvent).

## Building

1. Open the project in Android Studio
2. Sync Gradle
3. Run on a device or emulator (minimum SDK 24 / Android 7.0)

## Tech Stack

- Kotlin
- Jetpack Compose with Material 3
- Single-activity architecture
- ~500 lines of code total

## Project Structure

```
app/src/main/java/com/example/padelcounter/
  MainActivity.kt   -- UI (ScoreBoard + TeamPanel composables, key event handling)
  MatchState.kt      -- Scoring logic (MatchState, PadelScoring, MatchViewModel)
```

## License

MIT License — see [LICENSE](LICENSE) for details.
