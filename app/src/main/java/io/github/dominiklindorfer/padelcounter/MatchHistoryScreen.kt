package io.github.dominiklindorfer.padelcounter

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.DeleteSweep
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

private val DarkBg = Color(0xFF0D0D0D)
private val CardBg = Color(0xFF1A1A1A)
private val TextWhite = Color(0xFFFFFFFF)
private val DimColor = Color(0xFF999999)
private val GoldColor = Color(0xFFFFD700)
private val Team1Blue = Color(0xFF5BA8FF)
private val Team2Red = Color(0xFFFF7A7A)

@Composable
fun MatchHistoryScreen(
    vm: MatchViewModel,
    onBack: () -> Unit,
) {
    val matches = vm.matchHistory
    val context = LocalContext.current

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBg),
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(CardBg)
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back",
                            tint = TextWhite, modifier = Modifier.size(28.dp))
                    }
                    Spacer(Modifier.width(8.dp))
                    Text("MATCH HISTORY", color = TextWhite, fontSize = 24.sp, fontWeight = FontWeight.Bold)
                }
                if (matches.isNotEmpty()) {
                    IconButton(onClick = { vm.deleteAllHistory() }) {
                        Icon(Icons.Filled.DeleteSweep, "Clear all",
                            tint = Color(0xFFFF5555), modifier = Modifier.size(28.dp))
                    }
                }
            }

            if (matches.isEmpty()) {
                // Empty state
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center,
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(Icons.Filled.EmojiEvents, "No matches",
                            tint = DimColor, modifier = Modifier.size(64.dp))
                        Spacer(Modifier.height(16.dp))
                        Text("No matches yet", color = DimColor, fontSize = 20.sp)
                        Spacer(Modifier.height(8.dp))
                        Text("Completed matches will appear here",
                            color = DimColor.copy(alpha = 0.6f), fontSize = 14.sp)
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize().padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    items(matches, key = { it.id }) { match ->
                        MatchCard(match, context,
                            onDelete = { vm.deleteMatch(match.id) })
                    }
                }
            }
        }
    }
}

@Composable
private fun MatchCard(
    match: SavedMatch,
    context: Context,
    onDelete: () -> Unit,
) {
    val dateFormat = SimpleDateFormat("MMM dd, yyyy  HH:mm", Locale.getDefault())
    val dateStr = dateFormat.format(Date(match.timestamp))
    val durationMin = match.durationMs / 60000
    val durationSec = (match.durationMs % 60000) / 1000
    val winnerName = if (match.winner == 1) match.team1Name else match.team2Name

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(CardBg, RoundedCornerShape(16.dp))
            .padding(20.dp),
    ) {
        // Date and actions
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(dateStr, color = DimColor, fontSize = 13.sp)
            Row {
                IconButton(onClick = { shareMatch(context, match) }) {
                    Icon(Icons.Filled.Share, "Share", tint = TextWhite, modifier = Modifier.size(22.dp))
                }
                IconButton(onClick = onDelete) {
                    Icon(Icons.Filled.Delete, "Delete", tint = Color(0xFFFF5555), modifier = Modifier.size(22.dp))
                }
            }
        }

        Spacer(Modifier.height(8.dp))

        // Team names and set score
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // Team 1
            Column(horizontalAlignment = Alignment.Start) {
                Text(
                    match.team1Name,
                    color = Team1Blue,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                )
            }

            // Sets score
            Text(
                "${match.team1Sets} - ${match.team2Sets}",
                color = TextWhite,
                fontSize = 32.sp,
                fontWeight = FontWeight.Bold,
            )

            // Team 2
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    match.team2Name,
                    color = Team2Red,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                )
            }
        }

        Spacer(Modifier.height(8.dp))

        // Game scores per set
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            match.team1Games.forEachIndexed { i, g1 ->
                if (i > 0) {
                    Text("  ", color = DimColor, fontSize = 16.sp)
                }
                val g2 = match.team2Games.getOrElse(i) { 0 }
                Text(
                    "$g1-$g2",
                    color = DimColor,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium,
                )
            }
        }

        Spacer(Modifier.height(12.dp))
        HorizontalDivider(color = Color(0xFF333333))
        Spacer(Modifier.height(12.dp))

        // Stats row
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly,
        ) {
            StatItem(Icons.Filled.EmojiEvents, "Winner", winnerName,
                if (match.winner == 1) Team1Blue else Team2Red)
            StatItem(Icons.Filled.Timer, "Duration", "%d:%02d".format(durationMin, durationSec), TextWhite)

            val totalPoints = match.team1PointsWon + match.team2PointsWon
            if (totalPoints > 0) {
                val t1Pct = (match.team1PointsWon * 100) / totalPoints
                StatItem(null, "Points Won", "$t1Pct% - ${100 - t1Pct}%", GoldColor)
            }
        }
    }
}

@Composable
private fun StatItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector?,
    label: String,
    value: String,
    valueColor: Color,
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        if (icon != null) {
            Icon(icon, label, tint = DimColor, modifier = Modifier.size(18.dp))
            Spacer(Modifier.height(4.dp))
        }
        Text(label, color = DimColor, fontSize = 11.sp)
        Spacer(Modifier.height(2.dp))
        Text(value, color = valueColor, fontSize = 14.sp, fontWeight = FontWeight.Bold)
    }
}

/** Build a shareable text summary and launch Android share intent. */
private fun shareMatch(context: Context, match: SavedMatch) {
    val dateFormat = SimpleDateFormat("MMM dd, yyyy HH:mm", Locale.getDefault())
    val durationMin = match.durationMs / 60000
    val durationSec = (match.durationMs % 60000) / 1000
    val winnerName = if (match.winner == 1) match.team1Name else match.team2Name

    val gameScores = match.team1Games.mapIndexed { i, g1 ->
        val g2 = match.team2Games.getOrElse(i) { 0 }
        "  Set ${i + 1}: $g1-$g2"
    }.joinToString("\n")

    val totalPoints = match.team1PointsWon + match.team2PointsWon
    val pointsLine = if (totalPoints > 0) {
        "\nPoints won: ${match.team1Name} ${match.team1PointsWon} - ${match.team2PointsWon} ${match.team2Name}"
    } else ""

    val text = buildString {
        appendLine("Padel Match Result")
        appendLine("${dateFormat.format(Date(match.timestamp))}")
        appendLine()
        appendLine("${match.team1Name}  ${match.team1Sets} - ${match.team2Sets}  ${match.team2Name}")
        appendLine()
        appendLine("Game scores:")
        appendLine(gameScores)
        appendLine()
        appendLine("Winner: $winnerName")
        appendLine("Duration: ${durationMin}m ${durationSec}s")
        append(pointsLine)
        if (match.goldenPoint) appendLine("\nScoring: Golden Point")
    }

    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_SUBJECT, "Padel Match: ${match.team1Name} vs ${match.team2Name}")
        putExtra(Intent.EXTRA_TEXT, text)
    }
    context.startActivity(Intent.createChooser(intent, "Share match result"))
}
