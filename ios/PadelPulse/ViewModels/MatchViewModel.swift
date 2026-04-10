import Foundation
import Observation

/// ViewModel that holds the match state and an undo history stack.
@Observable
final class MatchViewModel {
    // Public state
    var state = MatchState()
    var goldenPoint = false
    var sidesSwapped = false
    var setsToWin = 0
    var team1Name = "TEAM 1"
    var team2Name = "TEAM 2"
    var team1ColorIndex = 0
    var team2ColorIndex = 1
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
    @ObservationIgnored private var pointsHistory: [(Int, Int)] = []

    private let storage: MatchStorage

    var canUndo: Bool { !history.isEmpty }

    init(storage: MatchStorage) {
        self.storage = storage
        self.matchHistory = storage.loadAll()
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
        pointsHistory.append((team1PointsWon, team2PointsWon))

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
        }
        if state.isMatchOver {
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
    func updateTeam1Color(_ index: Int) { team1ColorIndex = index }
    func updateTeam2Color(_ index: Int) { team2ColorIndex = index }
    func updateServingTeam(_ team: Int) { servingTeam = team }

    func undo() {
        if !history.isEmpty {
            state = history.removeLast()
        }
        if !servingHistory.isEmpty {
            servingTeam = servingHistory.removeLast()
        }
        if !pointsHistory.isEmpty {
            let (t1, t2) = pointsHistory.removeLast()
            team1PointsWon = t1
            team2PointsWon = t2
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
    }

    func deleteMatch(id: Int64) {
        storage.delete(id: id)
        matchHistory = storage.loadAll()
    }

    func deleteAllHistory() {
        storage.deleteAll()
        matchHistory = []
    }
}
