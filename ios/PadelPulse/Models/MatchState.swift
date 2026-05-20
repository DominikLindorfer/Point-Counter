import Foundation

/// The complete state of a padel match.
/// Points are stored as raw integers (0,1,2,3,...) and converted to display strings separately.
struct MatchState: Equatable, Codable {
    var team1Sets: Int = 0
    var team2Sets: Int = 0
    var team1Games: [Int] = [0]   // games won per set (index = set number)
    var team2Games: [Int] = [0]
    var team1Points: Int = 0
    var team2Points: Int = 0
    var currentSet: Int = 0
    var isTiebreak: Bool = false
    var isMatchOver: Bool = false
    var winner: Int = 0           // 0 = none, 1 = team1, 2 = team2
}

/// Pure scoring logic — no UI dependencies, easy to test.
enum PadelScoring {

    static func scorePoint(state: MatchState, team: Int, goldenPoint: Bool, setsToWin: Int) -> MatchState {
        if state.isMatchOver { return state }

        let t1 = team == 1 ? state.team1Points + 1 : state.team1Points
        let t2 = team == 2 ? state.team2Points + 1 : state.team2Points

        let gameWinner = checkGameWinner(t1: t1, t2: t2, isTiebreak: state.isTiebreak, goldenPoint: goldenPoint)

        if gameWinner == 0 {
            var s = state
            s.team1Points = t1
            s.team2Points = t2
            return s
        } else {
            return scoreGame(state: state, winner: gameWinner, setsToWin: setsToWin)
        }
    }

    /// Display the current point score as padel-style strings.
    static func displayPoints(state: MatchState, goldenPoint: Bool) -> (String, String) {
        if state.isTiebreak {
            return (String(state.team1Points), String(state.team2Points))
        }

        let map = ["0", "15", "30", "40"]
        let t1 = state.team1Points
        let t2 = state.team2Points

        // Before deuce territory
        if t1 < 3 || t2 < 3 {
            return (
                t1 <= 3 ? map[t1] : "40",
                t2 <= 3 ? map[t2] : "40"
            )
        }

        // Deuce territory (both reached 40 at some point)
        if goldenPoint {
            // Golden point: at 40-40, just show 40-40 (next point wins)
            return ("40", "40")
        }
        if t1 == t2 { return ("40", "40") }   // Deuce
        if t1 > t2 { return ("AD", "-") }      // Advantage team 1
        return ("-", "AD")                       // Advantage team 2
    }

    private static func checkGameWinner(t1: Int, t2: Int, isTiebreak: Bool, goldenPoint: Bool) -> Int {
        if isTiebreak {
            // Tiebreak: always need 7+ with 2-point lead
            if t1 >= 7 && t1 - t2 >= 2 { return 1 }
            if t2 >= 7 && t2 - t1 >= 2 { return 2 }
            return 0
        }
        if goldenPoint {
            // Golden point: first to 4 wins, no deuce/advantage
            if t1 >= 4 { return 1 }
            if t2 >= 4 { return 2 }
            return 0
        }
        // Standard advantage scoring: need 4+ with 2-point lead
        if t1 >= 4 && t1 - t2 >= 2 { return 1 }
        if t2 >= 4 && t2 - t1 >= 2 { return 2 }
        return 0
    }

    private static func scoreGame(state: MatchState, winner: Int, setsToWin: Int) -> MatchState {
        let set = state.currentSet
        var t1Games = state.team1Games
        var t2Games = state.team2Games

        if winner == 1 { t1Games[set] += 1 } else { t2Games[set] += 1 }

        let setWinner = checkSetWinner(t1g: t1Games[set], t2g: t2Games[set], wasTiebreak: state.isTiebreak)

        if setWinner == 0 {
            // Set continues — check if we just entered tiebreak
            let nowTiebreak = (t1Games[set] == 6 && t2Games[set] == 6)
            var s = state
            s.team1Points = 0
            s.team2Points = 0
            s.team1Games = t1Games
            s.team2Games = t2Games
            s.isTiebreak = nowTiebreak
            return s
        } else {
            var s = state
            s.team1Points = 0
            s.team2Points = 0
            s.team1Games = t1Games
            s.team2Games = t2Games
            return scoreSet(state: s, winner: setWinner, setsToWin: setsToWin)
        }
    }

    private static func checkSetWinner(t1g: Int, t2g: Int, wasTiebreak: Bool) -> Int {
        if t1g >= 6 && t1g - t2g >= 2 { return 1 }
        if t2g >= 6 && t2g - t1g >= 2 { return 2 }
        // Tiebreak won (score is now 7-6)
        if wasTiebreak && t1g == 7 { return 1 }
        if wasTiebreak && t2g == 7 { return 2 }
        return 0
    }

    private static func scoreSet(state: MatchState, winner: Int, setsToWin: Int) -> MatchState {
        let t1Sets = winner == 1 ? state.team1Sets + 1 : state.team1Sets
        let t2Sets = winner == 2 ? state.team2Sets + 1 : state.team2Sets

        // Check if match is won (0 = infinite, no match end)
        if setsToWin > 0 && (t1Sets >= setsToWin || t2Sets >= setsToWin) {
            var s = state
            s.team1Sets = t1Sets
            s.team2Sets = t2Sets
            s.isMatchOver = true
            s.winner = t1Sets >= setsToWin ? 1 : 2
            s.isTiebreak = false
            return s
        }

        // Start new set
        let newSet = state.currentSet + 1
        var s = state
        s.team1Sets = t1Sets
        s.team2Sets = t2Sets
        s.team1Games = state.team1Games + [0]
        s.team2Games = state.team2Games + [0]
        s.currentSet = newSet
        s.isTiebreak = false
        return s
    }
}
