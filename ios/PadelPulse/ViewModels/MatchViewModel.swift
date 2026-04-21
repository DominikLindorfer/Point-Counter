import Foundation
import Observation
import SwiftUI

/// Snapshot of all state needed to undo a single point.
/// Captured *before* the point is applied so a pop fully restores prior state,
/// including timer fields (so undoing the very first point resets the timer).
struct UndoSnapshot: Codable, Equatable {
    let state: MatchState
    let servingTeam: Int
    let team1PointsWon: Int
    let team2PointsWon: Int
    let matchStartTimeMs: Int64
    let matchRunning: Bool
    let pausedElapsedMs: Int64
    // Optional for backwards-compat with snapshots persisted before sidesSwapped was tracked.
    let sidesSwapped: Bool?
}

/// Auto side-swap behaviour. Remote buttons stay team-fixed; only the display rotates.
enum AutoSwapMode: String, Codable {
    case off
    case afterSet
}

/// All state needed to restore an in-progress match.
struct PersistedMatchState: Codable {
    /// Schema version for this snapshot. Optional so legacy saves written before
    /// this field existed decode as v1. Bump + add a migration when changing
    /// the shape of persisted fields.
    var schemaVersion: Int? = 1
    let state: MatchState
    let goldenPoint: Bool
    let sidesSwapped: Bool
    let setsToWin: Int
    let team1Name: String
    let team2Name: String
    let team1ColorRGB: [CGFloat]
    let team2ColorRGB: [CGFloat]
    let servingTeam: Int
    let showServeSide: Bool
    let matchStartTimeMs: Int64
    let matchRunning: Bool
    let team1PointsWon: Int
    let team2PointsWon: Int
    let pausedElapsedMs: Int64
    let undoStack: [UndoSnapshot]
    let autoSwapMode: AutoSwapMode?
}

private let funTeamNames = [
    "SMASH BROS", "NET NINJAS", "LOB STARS",
    "VOLLEY LLAMAS", "SPIN DOCTORS", "THE WALLS",
    "GLASS GANG", "PADEL BEARS", "DROP SHOTS",
    "BANDEJA BOYS", "VIBORA VIBES", "CHIQUITAS",
    "GOLDEN POINTERS", "DEUCE BIGALOW", "COURT JESTERS",
    "MATCH POINT", "SWEET SPOTS", "ACE VENTURA",
    "TOP SPIN", "BACKHAND BANDITS", "RALLY CATS",
    "NET PROFIT", "FAULT LINES", "BREAK POINT",
    "GAME SETTERS", "TIEBREAKERS", "NO AD ZONE",
    "PASSING SHOTS", "BASELINE BROS", "POWER PADEL",
]

/// ViewModel that holds the match state and an undo history stack.
@Observable
final class MatchViewModel {
    // Public state
    var state = MatchState()
    var goldenPoint = true
    var sidesSwapped = false
    var setsToWin = 2
    var team1Name: String
    var team2Name: String
    var team1Color: Color = defaultTeam1Color
    var team2Color: Color = defaultTeam2Color
    var servingTeam = 1
    var showServeSide = true
    var matchStartTimeMs: Int64 = 0
    var matchRunning = false
    var team1PointsWon = 0
    var team2PointsWon = 0
    var matchHistory: [SavedMatch] = []
    var autoSwapMode: AutoSwapMode {
        didSet { UserDefaults.standard.set(autoSwapMode.rawValue, forKey: DefaultsKey.autoSwapMode) }
    }

    // Undo stack — mutations are mirrored into `undoCount` so SwiftUI can observe canUndo.
    @ObservationIgnored private var undoStack: [UndoSnapshot] = [] {
        didSet { undoCount = undoStack.count }
    }
    @ObservationIgnored private var pausedElapsedMs: Int64 = 0

    private(set) var undoCount = 0
    private let storage: MatchStorage

    var canUndo: Bool { undoCount > 0 }

    init(storage: MatchStorage) {
        self.storage = storage
        let names = Self.randomTeamNames()
        self.team1Name = names.0
        self.team2Name = names.1
        self.matchHistory = storage.loadAll()
        let raw = UserDefaults.standard.string(forKey: DefaultsKey.autoSwapMode) ?? AutoSwapMode.afterSet.rawValue
        self.autoSwapMode = AutoSwapMode(rawValue: raw) ?? .afterSet
    }

    private static func randomTeamNames() -> (String, String) {
        guard funTeamNames.count >= 2 else { return ("TEAM 1", "TEAM 2") }
        let shuffled = funTeamNames.shuffled()
        return (shuffled[0], shuffled[1])
    }

    func scorePoint(team: Int) {
        if state.isMatchOver { return }

        // Snapshot full pre-point state so undo can restore everything,
        // including timer fields (so undo of the very first point resets the timer).
        undoStack.append(UndoSnapshot(
            state: state,
            servingTeam: servingTeam,
            team1PointsWon: team1PointsWon,
            team2PointsWon: team2PointsWon,
            matchStartTimeMs: matchStartTimeMs,
            matchRunning: matchRunning,
            pausedElapsedMs: pausedElapsedMs,
            sidesSwapped: sidesSwapped
        ))

        if !matchRunning {
            matchStartTimeMs = Int64(Date().timeIntervalSince1970 * 1000)
            matchRunning = true
        }

        if team == 1 { team1PointsWon += 1 } else { team2PointsWon += 1 }

        let wasInTiebreak = state.isTiebreak
        let oldGames = state.team1Games[state.currentSet] + state.team2Games[state.currentSet]
        let oldCurrentSet = state.currentSet
        state = PadelScoring.scorePoint(state: state, team: team, goldenPoint: goldenPoint, setsToWin: setsToWin)

        let gameJustWon: Bool
        if state.isMatchOver {
            gameJustWon = true
        } else {
            let newGames = state.team1Games[state.currentSet] + state.team2Games[state.currentSet]
            gameJustWon = newGames != oldGames
        }

        if gameJustWon {
            servingTeam = servingTeam == 1 ? 2 : 1
            HapticService.gameWon()
            SoundService.playGameWon()
            if !state.isMatchOver, autoSwapMode == .afterSet, state.currentSet > oldCurrentSet {
                sidesSwapped.toggle()
            }
        } else {
            // Inside a tiebreak the server alternates after the 1st point and
            // then every two points (per ITF rule): switch on odd point totals.
            if wasInTiebreak {
                let totalTBPoints = state.team1Points + state.team2Points
                if totalTBPoints.isMultiple(of: 2) == false {
                    servingTeam = servingTeam == 1 ? 2 : 1
                }
            }
            HapticService.scorePoint()
            SoundService.playPointScored()
        }
        if state.isMatchOver {
            HapticService.matchOver()
            SoundService.playMatchOver()
            matchRunning = false
            saveMatch()
        }
    }

    func toggleGoldenPoint() { goldenPoint.toggle() }
    func swapSides() { sidesSwapped.toggle() }

    func cycleAutoSwapMode() {
        switch autoSwapMode {
        case .off: autoSwapMode = .afterSet
        case .afterSet: autoSwapMode = .off
        }
    }

    func cycleSetsToWin() {
        switch setsToWin {
        case 0: setsToWin = 1
        case 1: setsToWin = 2
        case 2: setsToWin = 3
        default: setsToWin = 0
        }
    }

    func updateTeam1Name(_ name: String) { team1Name = name }
    func updateTeam2Name(_ name: String) { team2Name = name }
    func updateTeam1Color(_ color: Color) { team1Color = color }
    func updateTeam2Color(_ color: Color) { team2Color = color }
    func updateServingTeam(_ team: Int) { servingTeam = team }

    func undo() {
        guard let snap = undoStack.popLast() else { return }
        HapticService.undo()
        state = snap.state
        servingTeam = snap.servingTeam
        team1PointsWon = snap.team1PointsWon
        team2PointsWon = snap.team2PointsWon
        matchStartTimeMs = snap.matchStartTimeMs
        matchRunning = snap.matchRunning
        pausedElapsedMs = snap.pausedElapsedMs
        if let swapped = snap.sidesSwapped { sidesSwapped = swapped }
    }

    func resetMatch() {
        undoStack.removeAll()
        state = MatchState()
        servingTeam = 1
        matchStartTimeMs = 0
        matchRunning = false
        team1PointsWon = 0
        team2PointsWon = 0
        pausedElapsedMs = 0
        clearInProgressMatch()
    }

    /// Build a SavedMatch from the current view-model state. Shared between
    /// `saveMatch()` (auto-persist on match over) and the overlay's share action.
    /// If `durationMs` is nil, derives it from `matchStartTimeMs`.
    func currentMatchSnapshot(durationMs: Int64? = nil) -> SavedMatch {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let derivedDuration = matchStartTimeMs > 0 ? now - matchStartTimeMs : 0
        return SavedMatch(
            id: 0,
            timestamp: now,
            team1Name: team1Name,
            team2Name: team2Name,
            team1Sets: state.team1Sets,
            team2Sets: state.team2Sets,
            team1Games: state.team1Games,
            team2Games: state.team2Games,
            winner: state.winner,
            durationMs: durationMs ?? derivedDuration,
            goldenPoint: goldenPoint,
            team1PointsWon: team1PointsWon,
            team2PointsWon: team2PointsWon
        )
    }

    private func saveMatch() {
        _ = storage.save(currentMatchSnapshot())
        matchHistory = storage.loadAll()
        clearInProgressMatch()
    }

    func deleteMatch(id: Int64) {
        storage.delete(id: id)
        matchHistory = storage.loadAll()
    }

    func deleteAllHistory() {
        storage.deleteAll()
        matchHistory = []
    }

    // MARK: - Match State Persistence

    func saveInProgressMatch() {
        // Only save if there's an active match worth restoring
        guard matchRunning || !undoStack.isEmpty || state.team1Points > 0 || state.team2Points > 0 else {
            clearInProgressMatch()
            return
        }
        guard !state.isMatchOver else { return }

        let persisted = PersistedMatchState(
            state: state,
            goldenPoint: goldenPoint,
            sidesSwapped: sidesSwapped,
            setsToWin: setsToWin,
            team1Name: team1Name,
            team2Name: team2Name,
            team1ColorRGB: team1Color.rgbComponents,
            team2ColorRGB: team2Color.rgbComponents,
            servingTeam: servingTeam,
            showServeSide: showServeSide,
            matchStartTimeMs: matchStartTimeMs,
            matchRunning: matchRunning,
            team1PointsWon: team1PointsWon,
            team2PointsWon: team2PointsWon,
            pausedElapsedMs: pausedElapsedMs,
            undoStack: undoStack,
            autoSwapMode: autoSwapMode
        )

        if let data = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(data, forKey: DefaultsKey.inProgressMatch)
        }
    }

    func restoreInProgressMatch() {
        guard let data = UserDefaults.standard.data(forKey: DefaultsKey.inProgressMatch) else {
            return
        }
        let persisted: PersistedMatchState
        do {
            persisted = try JSONDecoder().decode(PersistedMatchState.self, from: data)
        } catch {
            // Quarantine so the corrupt snapshot isn't lost silently, then clear
            // the key so the next launch starts clean instead of re-trying forever.
            MatchStorage.quarantine(data: data, label: "in_progress_match", error: error)
            UserDefaults.standard.removeObject(forKey: DefaultsKey.inProgressMatch)
            return
        }

        state = persisted.state
        goldenPoint = persisted.goldenPoint
        sidesSwapped = persisted.sidesSwapped
        setsToWin = persisted.setsToWin
        team1Name = persisted.team1Name
        team2Name = persisted.team2Name
        team1Color = Color(rgb: persisted.team1ColorRGB)
        team2Color = Color(rgb: persisted.team2ColorRGB)
        servingTeam = persisted.servingTeam
        showServeSide = persisted.showServeSide
        team1PointsWon = persisted.team1PointsWon
        team2PointsWon = persisted.team2PointsWon
        undoStack = persisted.undoStack
        if let restored = persisted.autoSwapMode { autoSwapMode = restored }

        // Restore timer state. Always land in "paused" — PadelPulseApp's scenePhase .active
        // handler calls resumeTimer(), which recomputes matchStartTimeMs from now - pausedElapsedMs.
        matchStartTimeMs = persisted.matchStartTimeMs
        matchRunning = false
        if persisted.matchRunning {
            // Legacy saves (before .inactive pauseTimer) may have recorded a live startTime.
            // Treat wall-clock delta as elapsed — fresh installs with the pause-first fix won't hit this.
            let elapsed = Int64(Date().timeIntervalSince1970 * 1000) - persisted.matchStartTimeMs
            pausedElapsedMs = persisted.pausedElapsedMs > 0 ? persisted.pausedElapsedMs : elapsed
        } else {
            pausedElapsedMs = persisted.pausedElapsedMs
        }

        clearInProgressMatch()
    }

    func clearInProgressMatch() {
        UserDefaults.standard.removeObject(forKey: DefaultsKey.inProgressMatch)
    }

    func pauseTimer() {
        guard matchRunning else { return }
        pausedElapsedMs = Int64(Date().timeIntervalSince1970 * 1000) - matchStartTimeMs
        matchRunning = false
    }

    func resumeTimer() {
        // Resume only if there's a paused match to resume. Previously this gated on
        // pausedElapsedMs > 0, which missed sub-millisecond pauses and restored
        // sessions where the elapsed value happened to round to 0.
        guard !matchRunning, matchStartTimeMs > 0 else { return }
        matchStartTimeMs = Int64(Date().timeIntervalSince1970 * 1000) - pausedElapsedMs
        matchRunning = true
        pausedElapsedMs = 0
    }
}
