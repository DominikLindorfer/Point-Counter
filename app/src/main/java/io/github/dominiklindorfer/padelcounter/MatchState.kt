package io.github.dominiklindorfer.padelcounter

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel

/**
 * The complete state of a padel match.
 * Points are stored as raw integers (0,1,2,3,...) and converted to display strings separately.
 */
data class MatchState(
    val team1Sets: Int = 0,
    val team2Sets: Int = 0,
    val team1Games: List<Int> = listOf(0), // games won per set (index = set number)
    val team2Games: List<Int> = listOf(0),
    val team1Points: Int = 0,
    val team2Points: Int = 0,
    val currentSet: Int = 0,
    val isTiebreak: Boolean = false,
    val isMatchOver: Boolean = false,
    val winner: Int = 0, // 0 = none, 1 = team1, 2 = team2
)

/** Pure scoring logic — no Android dependencies, easy to test. */
object PadelScoring {

    fun scorePoint(state: MatchState, team: Int, goldenPoint: Boolean, setsToWin: Int): MatchState {
        if (state.isMatchOver) return state

        val t1 = if (team == 1) state.team1Points + 1 else state.team1Points
        val t2 = if (team == 2) state.team2Points + 1 else state.team2Points

        val gameWinner = checkGameWinner(t1, t2, state.isTiebreak, goldenPoint)

        return if (gameWinner == 0) {
            state.copy(team1Points = t1, team2Points = t2)
        } else {
            scoreGame(state, gameWinner, setsToWin)
        }
    }

    /** Display the current point score as padel-style strings. */
    fun displayPoints(state: MatchState, goldenPoint: Boolean): Pair<String, String> {
        if (state.isTiebreak) {
            return Pair(state.team1Points.toString(), state.team2Points.toString())
        }

        val map = listOf("0", "15", "30", "40")
        val t1 = state.team1Points
        val t2 = state.team2Points

        // Before deuce territory
        if (t1 < 3 || t2 < 3) {
            return Pair(
                if (t1 <= 3) map[t1] else "40",
                if (t2 <= 3) map[t2] else "40",
            )
        }

        // Deuce territory (both reached 40 at some point)
        if (goldenPoint) {
            // Golden point: at 40-40, just show 40-40 (next point wins)
            return Pair("40", "40")
        }
        if (t1 == t2) return Pair("40", "40") // Deuce
        if (t1 > t2) return Pair("AD", "-")   // Advantage team 1
        return Pair("-", "AD")                  // Advantage team 2
    }

    private fun checkGameWinner(t1: Int, t2: Int, isTiebreak: Boolean, goldenPoint: Boolean): Int {
        if (isTiebreak) {
            // Tiebreak: always need 7+ with 2-point lead
            if (t1 >= 7 && t1 - t2 >= 2) return 1
            if (t2 >= 7 && t2 - t1 >= 2) return 2
            return 0
        }
        if (goldenPoint) {
            // Golden point: first to 4 wins, no deuce/advantage
            if (t1 >= 4) return 1
            if (t2 >= 4) return 2
            return 0
        }
        // Standard advantage scoring: need 4+ with 2-point lead
        if (t1 >= 4 && t1 - t2 >= 2) return 1
        if (t2 >= 4 && t2 - t1 >= 2) return 2
        return 0
    }

    private fun scoreGame(state: MatchState, winner: Int, setsToWin: Int): MatchState {
        val set = state.currentSet
        val t1Games = state.team1Games.toMutableList()
        val t2Games = state.team2Games.toMutableList()

        if (winner == 1) t1Games[set]++ else t2Games[set]++

        val setWinner = checkSetWinner(t1Games[set], t2Games[set], state.isTiebreak)

        return if (setWinner == 0) {
            // Set continues — check if we just entered tiebreak
            val nowTiebreak = (t1Games[set] == 6 && t2Games[set] == 6)
            state.copy(
                team1Points = 0, team2Points = 0,
                team1Games = t1Games, team2Games = t2Games,
                isTiebreak = nowTiebreak,
            )
        } else {
            scoreSet(
                state.copy(
                    team1Points = 0, team2Points = 0,
                    team1Games = t1Games, team2Games = t2Games,
                ),
                setWinner,
                setsToWin,
            )
        }
    }

    private fun checkSetWinner(t1g: Int, t2g: Int, wasTiebreak: Boolean): Int {
        if (t1g >= 6 && t1g - t2g >= 2) return 1
        if (t2g >= 6 && t2g - t1g >= 2) return 2
        // Tiebreak won (score is now 7-6)
        if (wasTiebreak && t1g == 7) return 1
        if (wasTiebreak && t2g == 7) return 2
        return 0
    }

    private fun scoreSet(state: MatchState, winner: Int, setsToWin: Int): MatchState {
        val t1Sets = if (winner == 1) state.team1Sets + 1 else state.team1Sets
        val t2Sets = if (winner == 2) state.team2Sets + 1 else state.team2Sets

        // Check if match is won (0 = infinite, no match end)
        if (setsToWin > 0 && (t1Sets >= setsToWin || t2Sets >= setsToWin)) {
            return state.copy(
                team1Sets = t1Sets, team2Sets = t2Sets,
                isMatchOver = true,
                winner = if (t1Sets >= setsToWin) 1 else 2,
                isTiebreak = false,
            )
        }

        // Start new set
        val newSet = state.currentSet + 1
        return state.copy(
            team1Sets = t1Sets, team2Sets = t2Sets,
            team1Games = state.team1Games + 0,
            team2Games = state.team2Games + 0,
            currentSet = newSet,
            isTiebreak = false,
        )
    }
}

/** Preset color options for team customization. */
data class TeamColor(val name: String, val bg: Long, val accent: Long)

val teamColorPresets = listOf(
    TeamColor("Blue", 0xFF1565C0, 0xFFFFFFFF),
    TeamColor("Red", 0xFFC62828, 0xFFFFFFFF),
    TeamColor("Green", 0xFF2E7D32, 0xFFFFFFFF),
    TeamColor("Purple", 0xFF6A1B9A, 0xFFFFFFFF),
    TeamColor("Orange", 0xFFE65100, 0xFFFFFFFF),
    TeamColor("Cyan", 0xFF00838F, 0xFFFFFFFF),
    TeamColor("Pink", 0xFFAD1457, 0xFFFFFFFF),
    TeamColor("Yellow", 0xFFC88600, 0xFFFFFFFF),
)

/** ViewModel that holds the match state and an undo history stack. */
class MatchViewModel(private val storage: MatchStorage? = null) : ViewModel() {
    var state by mutableStateOf(MatchState())
        private set

    var goldenPoint by mutableStateOf(false)
        private set

    var sidesSwapped by mutableStateOf(false)
        private set

    var setsToWin by mutableStateOf(0)
        private set

    var team1Name by mutableStateOf("TEAM 1")
        private set
    var team2Name by mutableStateOf("TEAM 2")
        private set

    var team1ColorIndex by mutableStateOf(0)
        private set
    var team2ColorIndex by mutableStateOf(1)
        private set

    var servingTeam by mutableStateOf(1)
        private set

    var matchStartTimeMs by mutableStateOf(0L)
        private set
    var matchRunning by mutableStateOf(false)
        private set

    var team1PointsWon by mutableIntStateOf(0)
        private set
    var team2PointsWon by mutableIntStateOf(0)
        private set

    // Match history — loaded from SharedPreferences
    var matchHistory by mutableStateOf(storage?.loadAll() ?: emptyList())
        private set

    private val history = mutableListOf<MatchState>()
    private val servingHistory = mutableListOf<Int>()
    private val pointsHistory = mutableListOf<Pair<Int, Int>>()

    fun scorePoint(team: Int) {
        if (state.isMatchOver) return
        if (!matchRunning) {
            matchStartTimeMs = System.currentTimeMillis()
            matchRunning = true
        }
        history.add(state)
        servingHistory.add(servingTeam)
        pointsHistory.add(Pair(team1PointsWon, team2PointsWon))

        if (team == 1) team1PointsWon++ else team2PointsWon++

        val oldGames = state.team1Games[state.currentSet] + state.team2Games[state.currentSet]
        state = PadelScoring.scorePoint(state, team, goldenPoint, setsToWin)
        val newGames = if (!state.isMatchOver) {
            state.team1Games[state.currentSet] + state.team2Games[state.currentSet]
        } else {
            oldGames + 1
        }
        if (newGames != oldGames) {
            servingTeam = if (servingTeam == 1) 2 else 1
        }
        if (state.isMatchOver) {
            matchRunning = false
            saveMatch()
        }
    }

    fun toggleGoldenPoint() { goldenPoint = !goldenPoint }
    fun swapSides() { sidesSwapped = !sidesSwapped }

    fun cycleSetsToWin() {
        setsToWin = when (setsToWin) {
            0 -> 1; 1 -> 2; 2 -> 3; else -> 0
        }
    }

    fun updateTeam1Name(name: String) { team1Name = name }
    fun updateTeam2Name(name: String) { team2Name = name }
    fun updateTeam1Color(index: Int) { team1ColorIndex = index }
    fun updateTeam2Color(index: Int) { team2ColorIndex = index }
    fun updateServingTeam(team: Int) { servingTeam = team }

    fun undo() {
        if (history.isNotEmpty()) {
            state = history.removeLast()
            if (servingHistory.isNotEmpty()) servingTeam = servingHistory.removeLast()
            if (pointsHistory.isNotEmpty()) {
                val (t1, t2) = pointsHistory.removeLast()
                team1PointsWon = t1
                team2PointsWon = t2
            }
        }
    }

    fun resetMatch() {
        history.clear()
        servingHistory.clear()
        pointsHistory.clear()
        state = MatchState()
        servingTeam = 1
        matchStartTimeMs = 0L
        matchRunning = false
        team1PointsWon = 0
        team2PointsWon = 0
    }

    private fun saveMatch() {
        val s = storage ?: return
        val duration = if (matchStartTimeMs > 0) System.currentTimeMillis() - matchStartTimeMs else 0L
        s.save(
            SavedMatch(
                id = 0,
                timestamp = System.currentTimeMillis(),
                team1Name = team1Name,
                team2Name = team2Name,
                team1Sets = state.team1Sets,
                team2Sets = state.team2Sets,
                team1Games = state.team1Games,
                team2Games = state.team2Games,
                winner = state.winner,
                durationMs = duration,
                goldenPoint = goldenPoint,
                team1PointsWon = team1PointsWon,
                team2PointsWon = team2PointsWon,
            )
        )
        matchHistory = s.loadAll()
    }

    fun deleteMatch(id: Long) {
        storage?.delete(id)
        matchHistory = storage?.loadAll() ?: emptyList()
    }

    fun deleteAllHistory() {
        storage?.deleteAll()
        matchHistory = emptyList()
    }

    val canUndo: Boolean get() = history.isNotEmpty()
}
