package com.example.padelcounter

import android.os.Bundle
import android.view.KeyEvent
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

class MainActivity : ComponentActivity() {

    private val viewModel: MatchViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Immersive full-screen: hide status bar and navigation
        WindowCompat.setDecorFitsSystemWindows(window, false)
        WindowInsetsControllerCompat(window, window.decorView).let { controller ->
            controller.hide(WindowInsetsCompat.Type.systemBars())
            controller.systemBarsBehavior =
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }

        setContent {
            ScoreBoard(
                state = viewModel.state,
                canUndo = viewModel.canUndo,
                onScore = { team -> viewModel.scorePoint(team) },
                onUndo = { viewModel.undo() },
                onReset = { viewModel.resetMatch() },
            )
        }
    }

    /**
     * Catch hardware key events from Bluetooth HID buttons.
     * Most cheap Bluetooth camera shutters send VOLUME_UP, VOLUME_DOWN, ENTER, or CAMERA.
     * Change these mappings to match your specific button!
     */
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP -> { viewModel.scorePoint(1); true }
            KeyEvent.KEYCODE_VOLUME_DOWN -> { viewModel.scorePoint(2); true }
            else -> super.onKeyDown(keyCode, event)
        }
    }
}

// -- Colors --
private val DarkBg = Color(0xFF0A0A14)
private val Team1Bg = Color(0xFF0D1B2A)
private val Team2Bg = Color(0xFF1B0D1A)
private val AccentColor = Color(0xFFE0E0E0)
private val DimColor = Color(0xFF888888)

@Composable
fun ScoreBoard(
    state: MatchState,
    canUndo: Boolean,
    onScore: (Int) -> Unit,
    onUndo: () -> Unit,
    onReset: () -> Unit,
) {
    val (display1, display2) = PadelScoring.displayPoints(state)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBg),
    ) {
        // Main content: two halves
        Row(modifier = Modifier.fillMaxSize()) {
            // Team 1 - left half
            TeamPanel(
                teamLabel = "TEAM 1",
                sets = state.team1Sets,
                games = state.team1Games,
                opponentGames = state.team2Games,
                pointDisplay = display1,
                backgroundColor = Team1Bg,
                modifier = Modifier.weight(1f),
                onClick = { onScore(1) },
            )

            // Vertical divider
            Box(
                modifier = Modifier
                    .fillMaxHeight()
                    .width(2.dp)
                    .background(Color(0xFF333333)),
            )

            // Team 2 - right half
            TeamPanel(
                teamLabel = "TEAM 2",
                sets = state.team2Sets,
                games = state.team2Games,
                opponentGames = state.team1Games,
                pointDisplay = display2,
                backgroundColor = Team2Bg,
                modifier = Modifier.weight(1f),
                onClick = { onScore(2) },
            )
        }

        // Top bar with Undo and New Match
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Button(
                onClick = onUndo,
                enabled = canUndo,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF333333),
                    contentColor = AccentColor,
                ),
            ) {
                Text("UNDO", fontSize = 14.sp)
            }

            if (state.isTiebreak) {
                Text(
                    text = "TIEBREAK",
                    color = Color(0xFFFFD700),
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.align(Alignment.CenterVertically),
                )
            }

            Button(
                onClick = onReset,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF333333),
                    contentColor = AccentColor,
                ),
            ) {
                Text("NEW MATCH", fontSize = 14.sp)
            }
        }

        // Match over overlay
        if (state.isMatchOver) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color(0xCC000000))
                    .clickable { /* absorb taps */ },
                contentAlignment = Alignment.Center,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "MATCH OVER",
                        color = Color.White,
                        fontSize = 48.sp,
                        fontWeight = FontWeight.Bold,
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Team ${state.winner} wins!",
                        color = Color(0xFFFFD700),
                        fontSize = 32.sp,
                    )
                    Spacer(modifier = Modifier.height(32.dp))
                    Button(
                        onClick = onReset,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFFFFD700),
                            contentColor = Color.Black,
                        ),
                    ) {
                        Text("NEW MATCH", fontSize = 20.sp)
                    }
                }
            }
        }
    }
}

@Composable
fun TeamPanel(
    teamLabel: String,
    sets: Int,
    games: List<Int>,
    opponentGames: List<Int>,
    pointDisplay: String,
    backgroundColor: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    Box(
        modifier = modifier
            .fillMaxHeight()
            .background(backgroundColor)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null, // no ripple — cleaner for a scoreboard
            ) { onClick() },
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.padding(16.dp),
        ) {
            // Team name
            Text(
                text = teamLabel,
                color = DimColor,
                fontSize = 22.sp,
                fontWeight = FontWeight.Medium,
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Sets won
            Text(
                text = "SETS: $sets",
                color = AccentColor,
                fontSize = 20.sp,
            )

            Spacer(modifier = Modifier.height(4.dp))

            // Games per set (e.g., "6  4  2")
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                games.forEachIndexed { index, g ->
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = g.toString(),
                            color = AccentColor,
                            fontSize = 24.sp,
                            fontWeight = FontWeight.Bold,
                        )
                        Text(
                            text = opponentGames[index].toString(),
                            color = DimColor,
                            fontSize = 16.sp,
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Current game score — THE BIG NUMBER
            Text(
                text = pointDisplay,
                color = Color.White,
                fontSize = 120.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
            )
        }
    }
}
