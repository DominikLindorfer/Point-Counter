import XCTest
@testable import PadelPulse

/// Tests covering UserDefaults-backed match persistence: Codable roundtrips
/// and restore edge cases. These guard against regressions in the save/restore
/// flow that the view model relies on when the app is backgrounded or killed.
final class PersistenceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: DefaultsKey.inProgressMatch)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: DefaultsKey.inProgressMatch)
        super.tearDown()
    }

    // MARK: - Codable roundtrip

    /// PersistedMatchState must round-trip through JSON without losing data —
    /// including a populated undoStack (the largest nested field).
    func testPersistedMatchStateCodableRoundtrip() throws {
        var state = MatchState()
        state.team1Points = 3
        state.team2Points = 3
        state.team1Games = [3, 2]
        state.team2Games = [5, 1]
        state.team1Sets = 0
        state.team2Sets = 1
        state.currentSet = 1

        let snapshot = UndoSnapshot(
            state: state,
            servingTeam: 1,
            team1PointsWon: 12,
            team2PointsWon: 10,
            matchStartTimeMs: 1_700_000_000_000,
            matchRunning: true,
            pausedElapsedMs: 0,
            sidesSwapped: true
        )

        let persisted = PersistedMatchState(
            state: state,
            goldenPoint: true,
            sidesSwapped: true,
            setsToWin: 2,
            team1Name: "ACE VENTURA",
            team2Name: "NET NINJAS",
            team1ColorRGB: [0.1, 0.2, 0.3],
            team2ColorRGB: [0.4, 0.5, 0.6],
            servingTeam: 1,
            showServeSide: true,
            matchStartTimeMs: 1_700_000_000_000,
            matchRunning: true,
            team1PointsWon: 12,
            team2PointsWon: 10,
            pausedElapsedMs: 0,
            undoStack: [snapshot, snapshot],
            autoSwapMode: .afterSet
        )

        let data = try JSONEncoder().encode(persisted)
        let decoded = try JSONDecoder().decode(PersistedMatchState.self, from: data)

        XCTAssertEqual(decoded.state, persisted.state)
        XCTAssertEqual(decoded.goldenPoint, persisted.goldenPoint)
        XCTAssertEqual(decoded.sidesSwapped, persisted.sidesSwapped)
        XCTAssertEqual(decoded.setsToWin, persisted.setsToWin)
        XCTAssertEqual(decoded.team1Name, persisted.team1Name)
        XCTAssertEqual(decoded.team2Name, persisted.team2Name)
        XCTAssertEqual(decoded.team1ColorRGB, persisted.team1ColorRGB)
        XCTAssertEqual(decoded.team2ColorRGB, persisted.team2ColorRGB)
        XCTAssertEqual(decoded.servingTeam, persisted.servingTeam)
        XCTAssertEqual(decoded.undoStack.count, 2)
        XCTAssertEqual(decoded.undoStack.first?.sidesSwapped, true)
        XCTAssertEqual(decoded.autoSwapMode, .afterSet)
    }

    // MARK: - Restore does not inflate elapsed after background

    /// With the .inactive-pauses-first fix, saving backgrounded state always
    /// records matchRunning=false with a frozen pausedElapsedMs. Restoring
    /// hours later must NOT compute elapsed against wall-clock — the duration
    /// stays frozen until resumeTimer recomputes it on scenePhase .active.
    func testRestoreDoesNotInflateElapsedAfterBackground() {
        let vm = MatchViewModel(storage: MatchStorage())
        vm.scorePoint(team: 1)
        let realStartedAt = vm.matchStartTimeMs
        XCTAssertTrue(vm.matchRunning)

        // Simulate: scene inactive → pause, save.
        vm.pauseTimer()
        vm.saveInProgressMatch()
        XCTAssertFalse(vm.matchRunning)

        // App is killed; much later the user re-opens.
        let fresh = MatchViewModel(storage: MatchStorage())
        fresh.restoreInProgressMatch()

        XCTAssertFalse(fresh.matchRunning, "restored match is paused, not running")
        XCTAssertGreaterThan(fresh.matchStartTimeMs, 0, "startTime must be seeded for resume")

        // resumeTimer uses pausedElapsedMs; it was frozen at pause time so
        // the recomputed startTime is (now - small elapsed), NOT (realStartedAt - huge_offline_delta).
        fresh.resumeTimer()
        XCTAssertTrue(fresh.matchRunning)
        let restoredElapsed = Int64(Date().timeIntervalSince1970 * 1000) - fresh.matchStartTimeMs
        let originalElapsed = Int64(Date().timeIntervalSince1970 * 1000) - realStartedAt
        XCTAssertLessThanOrEqual(restoredElapsed, originalElapsed + 100,
                                 "restored elapsed must not exceed real elapsed since first point")
    }

    // MARK: - Auto-swap behaviour

    /// With autoSwapMode = .afterSet, sidesSwapped must toggle exactly once
    /// when a set ends, regardless of how many points end the game.
    func testAutoSwapToggleTriggersExactlyOncePerSet() {
        let vm = MatchViewModel(storage: MatchStorage())
        vm.autoSwapMode = .afterSet
        vm.goldenPoint = true
        vm.setsToWin = 2
        vm.updateServingTeam(1)

        let before = vm.sidesSwapped
        // Win 6 games to win the set (goldenPoint → 4 points per game).
        for _ in 0..<6 {
            for _ in 0..<4 {
                vm.scorePoint(team: 1)
            }
        }
        XCTAssertEqual(vm.state.team1Sets, 1, "set won")
        XCTAssertEqual(vm.state.currentSet, 1, "new set started")
        XCTAssertNotEqual(vm.sidesSwapped, before, "auto-swap toggled once")

        // Score more points in set 2 — no additional toggle until set 2 ends.
        let afterSet1 = vm.sidesSwapped
        vm.scorePoint(team: 1)
        vm.scorePoint(team: 2)
        XCTAssertEqual(vm.sidesSwapped, afterSet1, "no toggle mid-set")
    }

    /// autoSwapMode = .off must never toggle sidesSwapped, even across set boundaries.
    func testAutoSwapOffDoesNotToggleSides() {
        let vm = MatchViewModel(storage: MatchStorage())
        vm.autoSwapMode = .off
        vm.goldenPoint = true
        vm.setsToWin = 2
        vm.updateServingTeam(1)

        let before = vm.sidesSwapped
        for _ in 0..<6 {
            for _ in 0..<4 {
                vm.scorePoint(team: 1)
            }
        }
        XCTAssertEqual(vm.state.team1Sets, 1)
        XCTAssertEqual(vm.sidesSwapped, before, "off mode never toggles")
    }
}
