package io.github.dominiklindorfer.padelcounter

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * A saved match record.
 */
data class SavedMatch(
    val id: Long,
    val timestamp: Long,
    val team1Name: String,
    val team2Name: String,
    val team1Sets: Int,
    val team2Sets: Int,
    val team1Games: List<Int>,
    val team2Games: List<Int>,
    val winner: Int,
    val durationMs: Long,
    val goldenPoint: Boolean,
    val team1PointsWon: Int,
    val team2PointsWon: Int,
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("id", id)
        put("timestamp", timestamp)
        put("team1Name", team1Name)
        put("team2Name", team2Name)
        put("team1Sets", team1Sets)
        put("team2Sets", team2Sets)
        put("team1Games", JSONArray(team1Games))
        put("team2Games", JSONArray(team2Games))
        put("winner", winner)
        put("durationMs", durationMs)
        put("goldenPoint", goldenPoint)
        put("team1PointsWon", team1PointsWon)
        put("team2PointsWon", team2PointsWon)
    }

    companion object {
        fun fromJson(json: JSONObject): SavedMatch {
            val t1g = json.getJSONArray("team1Games")
            val t2g = json.getJSONArray("team2Games")
            return SavedMatch(
                id = json.getLong("id"),
                timestamp = json.getLong("timestamp"),
                team1Name = json.getString("team1Name"),
                team2Name = json.getString("team2Name"),
                team1Sets = json.getInt("team1Sets"),
                team2Sets = json.getInt("team2Sets"),
                team1Games = (0 until t1g.length()).map { t1g.getInt(it) },
                team2Games = (0 until t2g.length()).map { t2g.getInt(it) },
                winner = json.getInt("winner"),
                durationMs = json.getLong("durationMs"),
                goldenPoint = json.optBoolean("goldenPoint", false),
                team1PointsWon = json.optInt("team1PointsWon", 0),
                team2PointsWon = json.optInt("team2PointsWon", 0),
            )
        }
    }
}

/**
 * Simple match storage using SharedPreferences + JSON.
 * No Room, no KSP, no annotation processing — just works.
 */
class MatchStorage(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("match_history", Context.MODE_PRIVATE)
    private var nextId: Long = prefs.getLong("next_id", 1)

    fun save(match: SavedMatch): SavedMatch {
        val withId = match.copy(id = nextId++)
        val matches = loadAll().toMutableList()
        matches.add(0, withId) // newest first
        persist(matches)
        prefs.edit().putLong("next_id", nextId).apply()
        return withId
    }

    fun loadAll(): List<SavedMatch> {
        val raw = prefs.getString("matches", null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { SavedMatch.fromJson(arr.getJSONObject(it)) }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun delete(id: Long) {
        val matches = loadAll().filter { it.id != id }
        persist(matches)
    }

    fun deleteAll() {
        prefs.edit().remove("matches").apply()
    }

    private fun persist(matches: List<SavedMatch>) {
        val arr = JSONArray()
        matches.forEach { arr.put(it.toJson()) }
        prefs.edit().putString("matches", arr.toString()).apply()
    }
}
