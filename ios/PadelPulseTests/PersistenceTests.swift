import XCTest
@testable import PadelPulse

/// Tests covering UserDefaults-backed match persistence: Codable roundtrips
/// and restore edge cases. These guard against regressions in the save/restore
/// flow that the view model relies on when the app is backgrounded or killed.
final class PersistenceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: DefaultsKey.inProgressMatch)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.matchHistory)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: DefaultsKey.inProgressMatch)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.matchHistory)
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

    // MARK: - ID generation

    /// New saves get random Int64 IDs. Over a realistic batch of inserts the
    /// IDs must all be unique (the old monotonic counter had a read-modify-write
    /// race this test also locks in against a regression).
    func testRandomIdsAreUniqueAcrossManySaves() {
        let storage = MatchStorage()
        storage.deleteAll()
        defer { storage.deleteAll() }

        let sample = SavedMatch(
            id: 0, timestamp: 0,
            team1Name: "A", team2Name: "B",
            team1Sets: 1, team2Sets: 0,
            team1Games: [6], team2Games: [3],
            winner: 1, durationMs: 0, goldenPoint: true,
            team1PointsWon: 0, team2PointsWon: 0
        )

        var seen = Set<Int64>()
        for _ in 0..<200 {
            let saved = storage.save(sample)
            XCTAssertGreaterThan(saved.id, 0, "generated id must be positive")
            XCTAssertFalse(seen.contains(saved.id), "duplicate id generated: \(saved.id)")
            seen.insert(saved.id)
        }
    }

    // MARK: - Schema version

    /// New saves must tag schemaVersion = 1 so future migrations can detect them.
    func testNewSavesAreTaggedAsSchemaV1() throws {
        let state = MatchState()
        let persisted = PersistedMatchState(
            state: state, goldenPoint: true, sidesSwapped: false, setsToWin: 2,
            team1Name: "A", team2Name: "B",
            team1ColorRGB: [0, 0, 0], team2ColorRGB: [1, 1, 1],
            servingTeam: 1, showServeSide: true,
            matchStartTimeMs: 0, matchRunning: false,
            team1PointsWon: 0, team2PointsWon: 0, pausedElapsedMs: 0,
            undoStack: [], autoSwapMode: .afterSet
        )
        XCTAssertEqual(persisted.schemaVersion, 1, "new persisted match snapshot defaults to v1")

        let match = SavedMatch(
            id: 1, timestamp: 0, team1Name: "A", team2Name: "B",
            team1Sets: 0, team2Sets: 0, team1Games: [0], team2Games: [0],
            winner: 0, durationMs: 0, goldenPoint: true,
            team1PointsWon: 0, team2PointsWon: 0
        )
        XCTAssertEqual(match.schemaVersion, 1, "new SavedMatch defaults to v1")
    }

    /// Legacy records written before schemaVersion existed must still decode cleanly —
    /// their schemaVersion surfaces as nil (treated as v1 by any future migrator).
    func testLegacySavesDecodeWithNilSchemaVersion() throws {
        let legacyJSON = """
        [{
          "id": 42,
          "timestamp": 1700000000000,
          "team1Name": "Legacy A",
          "team2Name": "Legacy B",
          "team1Sets": 2,
          "team2Sets": 1,
          "team1Games": [6, 4, 7],
          "team2Games": [4, 6, 5],
          "winner": 1,
          "durationMs": 3600000,
          "goldenPoint": true,
          "team1PointsWon": 50,
          "team2PointsWon": 42
        }]
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode([SavedMatch].self, from: legacyJSON)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertNil(decoded[0].schemaVersion, "missing field must decode to nil (legacy marker)")
        XCTAssertEqual(decoded[0].team1Name, "Legacy A")
        XCTAssertEqual(decoded[0].winner, 1)
    }

    // MARK: - Corrupt storage quarantine

    /// Corrupt JSON in UserDefaults must not wipe silently: loadAll() quarantines
    /// the bytes to Documents/ and clears the key so the app stays usable.
    func testLoadAllQuarantinesCorruptData() throws {
        let corrupt = Data("{this is not valid json".utf8)
        UserDefaults.standard.set(corrupt, forKey: DefaultsKey.matchHistory)

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let priorQuarantine = (try? FileManager.default.contentsOfDirectory(atPath: docs.path)) ?? []
        let priorCount = priorQuarantine.filter { $0.hasPrefix("matches_corrupt_") }.count

        let matches = MatchStorage().loadAll()

        XCTAssertTrue(matches.isEmpty, "corrupt JSON should decode to an empty history, not crash")
        XCTAssertNil(UserDefaults.standard.data(forKey: DefaultsKey.matchHistory),
                     "corrupt key should be cleared so next launch starts clean")

        let afterQuarantine = (try? FileManager.default.contentsOfDirectory(atPath: docs.path)) ?? []
        let afterCount = afterQuarantine.filter { $0.hasPrefix("matches_corrupt_") }.count
        XCTAssertGreaterThan(afterCount, priorCount, "quarantine file should be written to Documents/")

        // Cleanup: remove the quarantine file we just created so tests stay idempotent.
        for name in afterQuarantine where name.hasPrefix("matches_corrupt_") && !priorQuarantine.contains(name) {
            try? FileManager.default.removeItem(at: docs.appendingPathComponent(name))
        }
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
