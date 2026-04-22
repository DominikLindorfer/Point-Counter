import XCTest
@testable import PadelPulse

final class PadelScoringTests: XCTestCase {

    private func assertPoints(_ state: MatchState, goldenPoint: Bool, _ expected1: String, _ expected2: String,
                              file: StaticString = #filePath, line: UInt = #line) {
        let (d1, d2) = PadelScoring.displayPoints(state: state, goldenPoint: goldenPoint)
        XCTAssertEqual(d1, expected1, "team1 display", file: file, line: line)
        XCTAssertEqual(d2, expected2, "team2 display", file: file, line: line)
    }

    // MARK: - Display Points

    func testDisplayPointsNormal() {
        var state = MatchState()
        assertPoints(state, goldenPoint: false, "0", "0")

        state.team1Points = 1
        assertPoints(state, goldenPoint: false, "15", "0")

        state.team1Points = 2; state.team2Points = 1
        assertPoints(state, goldenPoint: false, "30", "15")

        state.team1Points = 3; state.team2Points = 2
        assertPoints(state, goldenPoint: false, "40", "30")
    }

    func testDisplayPointsDeuce() {
        var state = MatchState()
        state.team1Points = 3; state.team2Points = 3
        assertPoints(state, goldenPoint: false, "40", "40")

        state.team1Points = 4; state.team2Points = 3
        assertPoints(state, goldenPoint: false, "AD", "-")

        state.team1Points = 3; state.team2Points = 4
        assertPoints(state, goldenPoint: false, "-", "AD")

        state.team1Points = 4; state.team2Points = 4
        assertPoints(state, goldenPoint: false, "40", "40")
    }

    func testDisplayPointsGoldenPoint() {
        var state = MatchState()
        state.team1Points = 3; state.team2Points = 3
        assertPoints(state, goldenPoint: true, "40", "40")
    }

    func testDisplayPointsTiebreak() {
        var state = MatchState()
        state.isTiebreak = true
        state.team1Points = 5; state.team2Points = 3
        assertPoints(state, goldenPoint: false, "5", "3")
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
        var state = MatchState()
        for _ in 0..<4 {
            state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        }
        XCTAssertEqual(state.team1Games[0], 1)
        XCTAssertEqual(state.team1Points, 0)
        XCTAssertEqual(state.team2Points, 0)
    }

    func testDeuceAndAdvantage() {
        var state = MatchState()
        for _ in 0..<3 {
            state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
            state = PadelScoring.scorePoint(state: state, team: 2, goldenPoint: false, setsToWin: 2)
        }
        XCTAssertEqual(state.team1Points, 3)
        XCTAssertEqual(state.team2Points, 3)

        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        XCTAssertEqual(state.team1Points, 4)
        XCTAssertEqual(state.team2Points, 3)

        state = PadelScoring.scorePoint(state: state, team: 2, goldenPoint: false, setsToWin: 2)
        XCTAssertEqual(state.team1Points, 4)
        XCTAssertEqual(state.team2Points, 4)

        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        XCTAssertEqual(state.team1Games[0], 1)
        XCTAssertEqual(state.team1Points, 0)
    }

    // MARK: - Golden Point

    func testGoldenPointWin() {
        var state = MatchState()
        for _ in 0..<3 {
            state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: true, setsToWin: 2)
            state = PadelScoring.scorePoint(state: state, team: 2, goldenPoint: true, setsToWin: 2)
        }
        XCTAssertEqual(state.team1Points, 3)
        XCTAssertEqual(state.team2Points, 3)

        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: true, setsToWin: 2)
        XCTAssertEqual(state.team1Games[0], 1)
        XCTAssertEqual(state.team1Points, 0)
    }

    // MARK: - Set Winning

    func testSetWin() {
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
        var state = MatchState()
        for _ in 0..<6 {
            for _ in 0..<4 {
                state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
            }
            for _ in 0..<4 {
                state = PadelScoring.scorePoint(state: state, team: 2, goldenPoint: false, setsToWin: 2)
            }
        }
        XCTAssertEqual(state.team1Games[0], 6)
        XCTAssertEqual(state.team2Games[0], 6)
        XCTAssertTrue(state.isTiebreak)
    }

    func testTiebreakScoring() {
        var state = MatchState()
        state.isTiebreak = true
        state.team1Games = [6]
        state.team2Games = [6]

        for _ in 0..<7 {
            state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        }
        XCTAssertEqual(state.team1Sets, 1)
        XCTAssertFalse(state.isTiebreak)
    }

    /// A dogged tiebreak that runs past 12-10. The 2-point-lead rule applies
    /// the whole way: at 11-11 the set is still live; 13-11 is the first valid
    /// set-winning score.
    func testTiebreakBeyond12_10() {
        var state = MatchState()
        state.isTiebreak = true
        state.team1Games = [6]
        state.team2Games = [6]

        // Alternate to 10-10.
        for _ in 0..<10 {
            state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
            state = PadelScoring.scorePoint(state: state, team: 2, goldenPoint: false, setsToWin: 2)
        }
        XCTAssertEqual(state.team1Points, 10)
        XCTAssertEqual(state.team2Points, 10)
        XCTAssertTrue(state.isTiebreak)

        // 11-10: 1-point lead, not a win.
        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        XCTAssertTrue(state.isTiebreak)

        // 11-11.
        state = PadelScoring.scorePoint(state: state, team: 2, goldenPoint: false, setsToWin: 2)
        XCTAssertTrue(state.isTiebreak)

        // 12-11: still not a win.
        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        XCTAssertTrue(state.isTiebreak)

        // 13-11: 2-point lead, set won.
        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        XCTAssertEqual(state.team1Sets, 1, "13-11 wins the tiebreak")
        XCTAssertFalse(state.isTiebreak)
    }

    func testTiebreakNeedsTwoPointLead() {
        var state = MatchState()
        state.isTiebreak = true
        state.team1Games = [6]
        state.team2Games = [6]

        for _ in 0..<6 {
            state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
            state = PadelScoring.scorePoint(state: state, team: 2, goldenPoint: false, setsToWin: 2)
        }
        XCTAssertEqual(state.team1Points, 6)
        XCTAssertEqual(state.team2Points, 6)
        XCTAssertTrue(state.isTiebreak)

        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        XCTAssertTrue(state.isTiebreak)

        state = PadelScoring.scorePoint(state: state, team: 2, goldenPoint: false, setsToWin: 2)

        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        XCTAssertTrue(state.isTiebreak)

        state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        XCTAssertEqual(state.team1Sets, 1)
        XCTAssertFalse(state.isTiebreak)
    }

    // MARK: - Set Edge Cases

    /// 5-5 does not trigger the tiebreak; a set can end 7-5 when the leading
    /// team wins the next two games. Guards against a buggy set-checker that
    /// might wrongly force tiebreak at 6-5 or short-circuit at 6-5.
    func test7_5SetWin() {
        var state = MatchState()
        // Team 1 wins 5 games (5-0).
        for _ in 0..<5 {
            for _ in 0..<4 {
                state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
            }
        }
        // Team 2 equalizes (5-5).
        for _ in 0..<5 {
            for _ in 0..<4 {
                state = PadelScoring.scorePoint(state: state, team: 2, goldenPoint: false, setsToWin: 2)
            }
        }
        XCTAssertEqual(state.team1Games[0], 5)
        XCTAssertEqual(state.team2Games[0], 5)
        XCTAssertFalse(state.isTiebreak, "5-5 must not enter tiebreak")

        // 6-5: only a 1-game lead, set continues.
        for _ in 0..<4 {
            state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        }
        XCTAssertEqual(state.team1Games[0], 6)
        XCTAssertEqual(state.team2Games[0], 5)
        XCTAssertEqual(state.team1Sets, 0, "6-5 must not win the set")

        // 7-5: 2-game lead, set is won.
        for _ in 0..<4 {
            state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
        }
        XCTAssertEqual(state.team1Sets, 1, "7-5 wins the set")
    }

    /// A clean 6-0 bagel: the winning side wins every game without the loser
    /// getting on the scoreboard at all. Also checks that a new (empty) set
    /// is appended to the game arrays.
    func test6_0Bagel() {
        var state = MatchState()
        for _ in 0..<6 {
            for _ in 0..<4 {
                state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
            }
        }
        XCTAssertEqual(state.team1Sets, 1, "6-0 wins the set")
        XCTAssertEqual(state.team1Games, [6, 0], "set 0 closed at 6, new set appended at 0")
        XCTAssertEqual(state.team2Games, [0, 0])
        XCTAssertEqual(state.currentSet, 1, "new set started")
    }

    // MARK: - Match Winning

    func testMatchWinBestOf3() {
        var state = MatchState()

        for _ in 0..<6 {
            for _ in 0..<4 {
                state = PadelScoring.scorePoint(state: state, team: 1, goldenPoint: false, setsToWin: 2)
            }
        }
        XCTAssertEqual(state.team1Sets, 1)
        XCTAssertFalse(state.isMatchOver)

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
        XCTAssertEqual(after, state)
    }
}
