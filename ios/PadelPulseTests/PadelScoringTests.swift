import XCTest
@testable import PadelPulse

final class PadelScoringTests: XCTestCase {

    // MARK: - Display Points

    func testDisplayPointsNormal() {
        var state = MatchState()
        XCTAssertEqual(PadelScoring.displayPoints(state: state, goldenPoint: false), ("0", "0"))

        state.team1Points = 1
        XCTAssertEqual(PadelScoring.displayPoints(state: state, goldenPoint: false), ("15", "0"))

        state.team1Points = 2; state.team2Points = 1
        XCTAssertEqual(PadelScoring.displayPoints(state: state, goldenPoint: false), ("30", "15"))

        state.team1Points = 3; state.team2Points = 2
        XCTAssertEqual(PadelScoring.displayPoints(state: state, goldenPoint: false), ("40", "30"))
    }

    func testDisplayPointsDeuce() {
        var state = MatchState()
        state.team1Points = 3; state.team2Points = 3
        XCTAssertEqual(PadelScoring.displayPoints(state: state, goldenPoint: false), ("40", "40"))

        state.team1Points = 4; state.team2Points = 3
        XCTAssertEqual(PadelScoring.displayPoints(state: state, goldenPoint: false), ("AD", "-"))

        state.team1Points = 3; state.team2Points = 4
        XCTAssertEqual(PadelScoring.displayPoints(state: state, goldenPoint: false), ("-", "AD"))

        state.team1Points = 4; state.team2Points = 4
        XCTAssertEqual(PadelScoring.displayPoints(state: state, goldenPoint: false), ("40", "40"))
    }

    func testDisplayPointsGoldenPoint() {
        var state = MatchState()
        state.team1Points = 3; state.team2Points = 3
        XCTAssertEqual(PadelScoring.displayPoints(state: state, goldenPoint: true), ("40", "40"))
    }

    func testDisplayPointsTiebreak() {
        var state = MatchState()
        state.isTiebreak = true
        state.team1Points = 5; state.team2Points = 3
        XCTAssertEqual(PadelScoring.displayPoints(state: state, goldenPoint: false), ("5", "3"))
    }

    // MARK: - Standard Scoring

    func testScorePointBasic() {
        let state = MatchState()
        let s1 = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        XCTAssertEqual(s1.team1Points, 1)
        XCTAssertEqual(s1.team2Points, 0)

        let s2 = PadelScoring.scorePoint(state: s1, team: 2, goldenPoint: false, setsToWin: 2)
        XCTAssertEqual(s2.team1Points, 1)
        XCTAssertEqual(s2.team2Points, 1)
    }

    func testGameWinStandard() {
        // Score 4 points for team 1 (love game)
        var state = MatchState()
        for _ in 0..<4 {
            state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        }
        XCTAssertEqual(state.team1Games[0], 1)
        XCTAssertEqual(state.team1Points, 0)
        XCTAssertEqual(state.team2Points, 0)
    }

    func testDeuceAndAdvantage() {
        // Get to deuce (3-3 in raw points = 40-40)
        var state = MatchState()
        for _ in 0..<3 {
            state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
            state = PadelScoring.scorePoint(state: state, team: 2, goldenPoint: false, setsToWin: 2)
        }
        XCTAssertEqual(state.team1Points, 3)
        XCTAssertEqual(state.team2Points, 3)

        // Advantage team 1
        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        XCTAssertEqual(state.team1Points, 4)
        XCTAssertEqual(state.team2Points, 3)

        // Back to deuce
        state = PadelScoring.scorePoint(state: state, team: 2, goldenPoint: false, setsToWin: 2)
        XCTAssertEqual(state.team1Points, 4)
        XCTAssertEqual(state.team2Points, 4)

        // Advantage team 1 again, then win
        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        // Game should be won
        XCTAssertEqual(state.team1Games[0], 1)
        XCTAssertEqual(state.team1Points, 0)
    }

    // MARK: - Golden Point

    func testGoldenPointWin() {
        // Get to 40-40
        var state = MatchState()
        for _ in 0..<3 {
            state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: true, setsToWin: 2)
            state = PadelScoring.scorePoint(state: state, team: 2, goldenPoint: true, setsToWin: 2)
        }
        XCTAssertEqual(state.team1Points, 3)
        XCTAssertEqual(state.team2Points, 3)

        // Next point wins (golden point)
        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: true, setsToWin: 2)
        XCTAssertEqual(state.team1Games[0], 1)
        XCTAssertEqual(state.team1Points, 0)
    }

    // MARK: - Set Winning

    func testSetWin() {
        // Win 6 games for team 1 (6-0)
        var state = MatchState()
        for _ in 0..<6 {
            for _ in 0..<4 {
                state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
            }
        }
        XCTAssertEqual(state.team1Sets, 1)
        XCTAssertEqual(state.currentSet, 1)
    }

    // MARK: - Tiebreak

    func testTiebreakTriggersAt6_6() {
        // Get to 6-6
        var state = MatchState()
        for _ in 0..<6 {
            // Team 1 wins a game
            for _ in 0..<4 {
                state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
            }
            // Team 2 wins a game
            for _ in 0..<4 {
                state = PadelScoring.scorePoint(state: state, team: 2, goldenPoint: false, setsToWin: 2)
            }
        }
        XCTAssertEqual(state.team1Games[0], 6)
        XCTAssertEqual(state.team2Games[0], 6)
        XCTAssertTrue(state.isTiebreak)
    }

    func testTiebreakScoring() {
        // Create a state already in tiebreak
        var state = MatchState()
        state.isTiebreak = true
        state.team1Games = [6]
        state.team2Games = [6]

        // Score to 7-5 — team 1 wins tiebreak
        for _ in 0..<7 {
            state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        }
        for _ in 0..<5 {
            state = PadelScoring.scorePoint(state: state, team: 2, goldenPoint: false, setsToWin: 2)
        }
        // At this point it's 7-5 in tiebreak points — but we need the scoring to flow naturally
        // Let's redo this properly
        state = MatchState()
        state.isTiebreak = true
        state.team1Games = [6]
        state.team2Games = [6]

        // Alternate scoring to get tiebreak going, then team 1 wins 7-2
        for _ in 0..<7 {
            state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        }
        // Team 1 has 7 points, team 2 has 0 → 7-0, lead ≥ 2 → set won
        XCTAssertEqual(state.team1Sets, 1)
        XCTAssertFalse(state.isTiebreak)
    }

    func testTiebreakNeedsTwoPointLead() {
        var state = MatchState()
        state.isTiebreak = true
        state.team1Games = [6]
        state.team2Games = [6]

        // Get to 6-6 in tiebreak points
        for _ in 0..<6 {
            state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
            state = PadelScoring.scorePoint(state: state, team: 2, goldenPoint: false, setsToWin: 2)
        }
        XCTAssertEqual(state.team1Points, 6)
        XCTAssertEqual(state.team2Points, 6)
        XCTAssertTrue(state.isTiebreak) // still in tiebreak

        // 7-6 — not enough
        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        XCTAssertTrue(state.isTiebreak) // still going

        // 7-7 — deuce in tiebreak
        state = PadelScoring.scorePoint(state: state, team: 2, goldenPoint: false, setsToWin: 2)

        // 8-7 — still not enough
        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        XCTAssertTrue(state.isTiebreak)

        // 9-7 — team 1 wins with 2-point lead
        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        XCTAssertEqual(state.team1Sets, 1)
        XCTAssertFalse(state.isTiebreak)
    }

    // MARK: - Match Winning

    func testMatchWinBestOf3() {
        var state = MatchState()

        // Team 1 wins first set 6-0
        for _ in 0..<6 {
            for _ in 0..<4 {
                state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
            }
        }
        XCTAssertEqual(state.team1Sets, 1)
        XCTAssertFalse(state.isMatchOver)

        // Team 1 wins second set 6-0
        for _ in 0..<6 {
            for _ in 0..<4 {
                state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
            }
        }
        XCTAssertEqual(state.team1Sets, 2)
        XCTAssertTrue(state.isMatchOver)
        XCTAssertEqual(state.winner, 1)
    }

    func testInfiniteMode() {
        var state = MatchState()

        // Win 3 sets for team 1 — match should NOT end (setsToWin = 0)
        for _ in 0..<3 {
            for _ in 0..<6 {
                for _ in 0..<4 {
                    state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 0)
                }
            }
        }
        XCTAssertEqual(state.team1Sets, 3)
        XCTAssertFalse(state.isMatchOver)
    }

    func testMatchOverDoesNotScoreMore() {
        var state = MatchState()
        state.isMatchOver = true
        state.winner = 1

        let after = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        XCTAssertEqual(after, state) // No change
    }
}
