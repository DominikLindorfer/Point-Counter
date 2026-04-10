import Foundation
import Observation
import SwiftUI

/// Codable replacement for (Int, Int) tuples in undo history.
struct PointsPair: Codable, Equatable {
    let team1: Int
    let team2: Int
}

/// All state needed to restore an in-progress match.
struct PersistedMatchState: Codable {
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
    let history: [MatchState]
    let servingHistory: [Int]
    let pointsHistory: [PointsPair]
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
    var goldenPoint = false
    var sidesSwapped = false
    var setsToWin = 0
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

    // Undo stacks — not observed by views
    @ObservationIgnored private var history: [MatchState] = []
    @ObservationIgnored private var servingHistory: [Int] = []
    @ObservationIgnored private var pointsHistory: [PointsPair] = []
    @ObservationIgnored private var pausedElapsedMs: Int64 = 0

    private let storage: MatchStorage

    var canUndo: Bool { !history.isEmpty }

    init(storage: MatchStorage) {
        self.storage = storage
        let names = Self.randomTeamNames()
        self.team1Name = names.0
        self.team2Name = names.1
        self.matchHistory = storage.loadAll()
    }

    private static func randomTeamNames() -> (String, String) {
        var shuffled = funTeamNames.shuffled()
        return (shuffled[0], shuffled[1])
    }

    func scorePoint(team: Int) {
        if state.isMatchOver { return }
        if !matchRunning {
            matchStartTimeMs = Int64(Date().timeIntervalSince1970 * 1000)
            matchRunning = true
        }

        // Push current state to undo stacks
        history.append(state)
        servingHistory.append(servingTeam)
        pointsHistory.append(PointsPair(team1: team1PointsWon, team2: team2PointsWon))

        if team == 1 { team1PointsWon += 1 } else { team2PointsWon += 1 }

        let oldGames = state.team1Games[state.currentSet] + state.team2Games[state.currentSet]
        state = PadelScoring.scorePoint(state: state, team: team, goldenPoint: goldenPoint, setsToWin: setsToWin)

        let newGames: Int
        if !state.isMatchOver {
            newGames = state.team1Games[state.currentSet] + state.team2Games[state.currentSet]
        } else {
            newGames = oldGames + 1
        }
        if newGames != oldGames {
            servingTeam = servingTeam == 1 ? 2 : 1
            HapticService.gameWon()
            SoundService.playGameWon()
        } else {
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
        guard !history.isEmpty else { return }
        HapticService.undo()
        state = history.removeLast()
        if !servingHistory.isEmpty {
            servingTeam = servingHistory.removeLast()
        }
        if !pointsHistory.isEmpty {
            let pair = pointsHistory.removeLast()
            team1PointsWon = pair.team1
            team2PointsWon = pair.team2
        }
    }

    func resetMatch() {
        history.removeAll()
        servingHistory.removeAll()
        pointsHistory.removeAll()
        state = MatchState()
        servingTeam = 1
        matchStartTimeMs = 0
        matchRunning = false
        team1PointsWon = 0
        team2PointsWon = 0
        pausedElapsedMs = 0
        let names = Self.randomTeamNames()
        team1Name = names.0
        team2Name = names.1
        clearInProgressMatch()
    }

    private func saveMatch() {
        let duration = matchStartTimeMs > 0
            ? Int64(Date().timeIntervalSince1970 * 1000) - matchStartTimeMs
            : 0

        let match = SavedMatch(
            id: 0,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            team1Name: team1Name,
            team2Name: team2Name,
            team1Sets: state.team1Sets,
            team2Sets: state.team2Sets,
            team1Games: state.team1Games,
            team2Games: state.team2Games,
            winner: state.winner,
            durationMs: duration,
            goldenPoint: goldenPoint,
            team1PointsWon: team1PointsWon,
            team2PointsWon: team2PointsWon
        )
        _ = storage.save(match)
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

    private static let inProgressKey = "in_progress_match"

    func saveInProgressMatch() {
        // Only save if there's an active match worth restoring
        guard matchRunning || !history.isEmpty || state.team1Points > 0 || state.team2Points > 0 else {
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
            history: history,
            servingHistory: servingHistory,
            pointsHistory: pointsHistory
        )

        if let data = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(data, forKey: Self.inProgressKey)
        }
    }

    func restoreInProgressMatch() {
        guard let data = UserDefaults.standard.data(forKey: Self.inProgressKey),
              let persisted = try? JSONDecoder().decode(PersistedMatchState.self, from: data) else {
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
        history = persisted.history
        servingHistory = persisted.servingHistory
        pointsHistory = persisted.pointsHistory

        // Restore timer state
        if persisted.matchRunning {
            // Recalculate start time from elapsed
            let elapsed = Int64(Date().timeIntervalSince1970 * 1000) - persisted.matchStartTimeMs
            let wasElapsed = persisted.pausedElapsedMs > 0 ? persisted.pausedElapsedMs : elapsed
            pausedElapsedMs = wasElapsed
            // Resume as paused — PadelPulseApp's scenePhase .active will call resumeTimer()
            matchRunning = false
        } else {
            pausedElapsedMs = persisted.pausedElapsedMs
            matchStartTimeMs = persisted.matchStartTimeMs
            matchRunning = false
        }

        clearInProgressMatch()
    }

    func clearInProgressMatch() {
        UserDefaults.standard.removeObject(forKey: Self.inProgressKey)
    }

    func pauseTimer() {
        guard matchRunning else { return }
        pausedElapsedMs = Int64(Date().timeIntervalSince1970 * 1000) - matchStartTimeMs
        matchRunning = false
    }

    func resumeTimer() {
        guard pausedElapsedMs > 0 else { return }
        matchStartTimeMs = Int64(Date().timeIntervalSince1970 * 1000) - pausedElapsedMs
        matchRunning = true
        pausedElapsedMs = 0
    }
}
