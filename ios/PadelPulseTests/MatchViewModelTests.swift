import XCTest
@testable import PadelPulse

/// ViewModel-level behaviour tests that focus on Phase 0 fixes:
/// - Tiebreak serve rotation (per ITF rule)
/// - Undo restores timer state, including the very first point
/// Both Golden Point and standard modes are exercised because the user
/// mostly plays Golden Point but Tiebreak must remain first-class.
final class MatchViewModelTests: XCTestCase {

    private var vm: MatchViewModel!

    override func setUp() {
        super.setUp()
        // Clear any in-progress match left from prior runs.
        UserDefaults.standard.removeObject(forKey: "in_progress_match")
        vm = MatchViewModel(storage: MatchStorage())
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "in_progress_match")
        vm = nil
        super.tearDown()
    }

    // MARK: - 0.2 Tiebreak serve rotation

    /// Force the match into a tiebreak with the given starting server.
    private func enterTiebreak(startingServer: Int) {
        vm.updateServingTeam(startingServer)
        vm.state.team1Games = [6]
        vm.state.team2Games = [6]
        vm.state.isTiebreak = true
    }

    /// In a tiebreak, the server changes after points 1, 3, 5, 7, ...
    /// (server A serves point 1, B serves 2&3, A serves 4&5, ...).
    func testTiebreakServeRotationStandard() {
        enterTiebreak(startingServer: 1)

        // Score 8 points alternating, sequence of expected servers BEFORE each point.
        // Point # :   1  2  3  4  5  6  7  8
        // Server  :   1  2  2  1  1  2  2  1
        let expectedServerBeforePoint = [1, 2, 2, 1, 1, 2, 2, 1]

        for (i, expected) in expectedServerBeforePoint.enumerated() {
            XCTAssertEqual(vm.servingTeam, expected,
                           "before tiebreak point \(i + 1), server should be \(expected)")
            // Alternate scoring so games never end the tiebreak prematurely.
            vm.scorePoint(team: (i % 2 == 0) ? 1 : 2)
        }
    }

    /// Golden Point preference must not affect tiebreak serve rotation.
    func testTiebreakServeRotationGoldenPointEnabled() {
        vm.goldenPoint = true
        enterTiebreak(startingServer: 2)

        // Same alternation pattern, just with starting server B.
        let expectedServerBeforePoint = [2, 1, 1, 2, 2, 1, 1, 2]

        for (i, expected) in expectedServerBeforePoint.enumerated() {
            XCTAssertEqual(vm.servingTeam, expected,
                           "before tiebreak point \(i + 1) (GP mode), server should be \(expected)")
            vm.scorePoint(team: (i % 2 == 0) ? 1 : 2)
        }
    }

    /// Outside tiebreak, server must only change when a game ends.
    func testStandardServeRotationOnlyOnGameEnd() {
        vm.updateServingTeam(1)
        // Score 3 points to team 1 — no game finished, server must stay.
        vm.scorePoint(team: 1)
        vm.scorePoint(team: 1)
        vm.scorePoint(team: 1)
        XCTAssertEqual(vm.servingTeam, 1)

        // 4th point wins the game — server flips.
        vm.scorePoint(team: 1)
        XCTAssertEqual(vm.servingTeam, 2)
    }

    // MARK: - 0.4 Undo restores timer state

    func testUndoOfFirstPointResetsTimer() {
        XCTAssertFalse(vm.matchRunning)
        XCTAssertEqual(vm.matchStartTimeMs, 0)

        vm.scorePoint(team: 1)
        XCTAssertTrue(vm.matchRunning)
        XCTAssertGreaterThan(vm.matchStartTimeMs, 0)

        vm.undo()
        XCTAssertFalse(vm.matchRunning, "timer must stop after undoing first point")
        XCTAssertEqual(vm.matchStartTimeMs, 0, "start time must reset after undoing first point")
        XCTAssertEqual(vm.state.team1Points, 0)
        XCTAssertFalse(vm.canUndo)
    }

    func testUndoMidMatchPreservesTimer() {
        vm.scorePoint(team: 1)
        let startTime = vm.matchStartTimeMs
        vm.scorePoint(team: 2)
        vm.scorePoint(team: 1)

        vm.undo()
        XCTAssertTrue(vm.matchRunning, "timer keeps running on mid-match undo")
        XCTAssertEqual(vm.matchStartTimeMs, startTime, "start time stays stable on mid-match undo")
    }

    func testUndoRestoresTiebreakServer() {
        enterTiebreak(startingServer: 1)
        // Three points: server should now be A again (1->2 after pt1, 2 after pt2, 2->1 after pt3)
        vm.scorePoint(team: 1)   // server now 2
        vm.scorePoint(team: 2)   // still 2
        vm.scorePoint(team: 1)   // server now 1
        XCTAssertEqual(vm.servingTeam, 1)

        vm.undo()                // back to before pt3 → server was 2
        XCTAssertEqual(vm.servingTeam, 2)

        vm.undo()                // back to before pt2 → server was 2
        XCTAssertEqual(vm.servingTeam, 2)

        vm.undo()                // back to before pt1 → server was 1
        XCTAssertEqual(vm.servingTeam, 1)
    }

    // MARK: - Auto side swap + undo

    /// When a set ends and `autoSwapMode == .afterSet` toggles `sidesSwapped`,
    /// an undo of that set-winning point must restore the previous swap state.
    func testUndoRestoresSidesSwappedAfterAutoSwap() {
        vm.autoSwapMode = .afterSet
        vm.goldenPoint = true
        vm.setsToWin = 2
        vm.updateServingTeam(1)

        // Position team 1 to win the set on the next point:
        // 5 games already, 40 in the current game, golden-point → next point wins game, game wins set.
        vm.state.team1Games = [5]
        vm.state.team2Games = [0]
        vm.state.team1Points = 3

        let swappedBefore = vm.sidesSwapped
        vm.scorePoint(team: 1)
        XCTAssertEqual(vm.state.team1Sets, 1, "set should be won")
        XCTAssertEqual(vm.state.currentSet, 1, "a new set should be started")
        XCTAssertNotEqual(vm.sidesSwapped, swappedBefore,
                          "auto-swap should toggle sidesSwapped at set end")

        vm.undo()
        XCTAssertEqual(vm.sidesSwapped, swappedBefore,
                       "undo must restore sidesSwapped that was toggled by auto-swap")
    }

    func testUndoAcrossGameBoundaryGoldenPoint() {
        vm.goldenPoint = true
        vm.updateServingTeam(1)
        // Win the game in 4 points (golden point: first to 4, no AD).
        for _ in 0..<4 { vm.scorePoint(team: 1) }
        XCTAssertEqual(vm.state.team1Games[0], 1)
        XCTAssertEqual(vm.servingTeam, 2, "server flips when game ends")

        vm.undo()
        XCTAssertEqual(vm.state.team1Games[0], 0, "game-won state reverts on undo")
        XCTAssertEqual(vm.state.team1Points, 3, "point state reverts to 40-0")
        XCTAssertEqual(vm.servingTeam, 1, "server flip reverts on undo")
    }
}
