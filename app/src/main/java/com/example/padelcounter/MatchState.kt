package com.example.padelcounter

import androidx.compose.runtime.getValue
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

/** ViewModel that holds the match state and an undo history stack. */
class MatchViewModel : ViewModel() {
    var state by mutableStateOf(MatchState())
        private set

    var goldenPoint by mutableStateOf(false)
        private set

    // 0 = infinite (no match end), 1 = first to 1 set, 2 = first to 2, 3 = first to 3
    var setsToWin by mutableStateOf(0)
        private set

    private val history = mutableListOf<MatchState>()

    fun scorePoint(team: Int) {
        if (state.isMatchOver) return
        history.add(state)
        state = PadelScoring.scorePoint(state, team, goldenPoint, setsToWin)
    }

    fun toggleGoldenPoint() {
        goldenPoint = !goldenPoint
    }

    /** Cycle through: infinite → 1 → 2 → 3 → infinite */
    fun cycleSetsToWin() {
        setsToWin = when (setsToWin) {
            0 -> 1
            1 -> 2
            2 -> 3
            else -> 0
        }
    }

    fun undo() {
        if (history.isNotEmpty()) {
            state = history.removeLast()
        }
    }

    fun resetMatch() {
        history.clear()
        state = MatchState()
    }

    val canUndo: Boolean get() = history.isNotEmpty()
}
