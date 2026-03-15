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
import androidx.compose.foundation.shape.RoundedCornerShape
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
                goldenPoint = viewModel.goldenPoint,
                setsToWin = viewModel.setsToWin,
                onScore = { team -> viewModel.scorePoint(team) },
                onUndo = { viewModel.undo() },
                onReset = { viewModel.resetMatch() },
                onToggleGoldenPoint = { viewModel.toggleGoldenPoint() },
                onCycleSetsToWin = { viewModel.cycleSetsToWin() },
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
private val DarkBg = Color(0xFF0D0D0D)
private val Team1Bg = Color(0xFF091426)       // deep navy blue
private val Team2Bg = Color(0xFF260808)       // deep dark red
private val Team1Accent = Color(0xFF5BA8FF)   // vivid blue for labels
private val Team2Accent = Color(0xFFFF5555)   // vivid red for labels
private val Team1Point = Color(0xFFFFFFFF)    // pure white on blue — max contrast
private val Team2Point = Color(0xFFFFFFFF)    // pure white on red — max contrast
private val TextWhite = Color(0xFFFFFFFF)
private val DimColor = Color(0xFF999999)      // brighter gray for opponent scores
private val GoldColor = Color(0xFFFFD700)

@Composable
fun ScoreBoard(
    state: MatchState,
    canUndo: Boolean,
    goldenPoint: Boolean,
    setsToWin: Int,
    onScore: (Int) -> Unit,
    onUndo: () -> Unit,
    onReset: () -> Unit,
    onToggleGoldenPoint: () -> Unit,
    onCycleSetsToWin: () -> Unit,
) {
    val (display1, display2) = PadelScoring.displayPoints(state, goldenPoint)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBg),
    ) {
        // Main content: two halves
        Row(modifier = Modifier.fillMaxSize()) {
            // Team 1 - left half (Blue)
            TeamPanel(
                teamLabel = "TEAM 1",
                pointDisplay = display1,
                backgroundColor = Team1Bg,
                accentColor = Team1Accent,
                pointColor = Team1Point,
                modifier = Modifier.weight(1f),
                onClick = { onScore(1) },
            )

            // Vertical divider
            Box(
                modifier = Modifier
                    .fillMaxHeight()
                    .width(2.dp)
                    .background(Color(0xFF222222)),
            )

            // Team 2 - right half (Red)
            TeamPanel(
                teamLabel = "TEAM 2",
                pointDisplay = display2,
                backgroundColor = Team2Bg,
                accentColor = Team2Accent,
                pointColor = Team2Point,
                modifier = Modifier.weight(1f),
                onClick = { onScore(2) },
            )
        }

        // Top bar: Undo | Sets tracker | New Match
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(
                    onClick = onUndo,
                    enabled = canUndo,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFF1A1A1A),
                        contentColor = TextWhite,
                        disabledContainerColor = Color(0xFF111111),
                        disabledContentColor = Color(0xFF444444),
                    ),
                ) {
                    Text("UNDO", fontSize = 14.sp, fontWeight = FontWeight.Bold)
                }

                Button(
                    onClick = onToggleGoldenPoint,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (goldenPoint) GoldColor else Color(0xFF1A1A1A),
                        contentColor = if (goldenPoint) Color.Black else DimColor,
                    ),
                ) {
                    Text(
                        text = if (goldenPoint) "GOLDEN PT" else "ADVANTAGE",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                    )
                }
            }

            // Central sets & games tracker box
            Box(
                modifier = Modifier
                    .background(
                        color = Color(0xFF1A1A1A),
                        shape = RoundedCornerShape(12.dp),
                    )
                    .padding(horizontal = 24.dp, vertical = 12.dp),
                contentAlignment = Alignment.Center,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    // Set scores header
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        state.team1Games.forEachIndexed { index, g ->
                            // Blue score
                            Text(
                                text = g.toString(),
                                color = Team1Accent,
                                fontSize = 36.sp,
                                fontWeight = FontWeight.Bold,
                            )
                            Text(
                                text = "-",
                                color = DimColor,
                                fontSize = 36.sp,
                                fontWeight = FontWeight.Bold,
                            )
                            // Red score
                            Text(
                                text = state.team2Games[index].toString(),
                                color = Team2Accent,
                                fontSize = 36.sp,
                                fontWeight = FontWeight.Bold,
                            )
                            // Separator between sets
                            if (index < state.team1Games.lastIndex) {
                                Text(
                                    text = "  ",
                                    fontSize = 36.sp,
                                )
                            }
                        }
                    }
                    if (state.isTiebreak) {
                        Text(
                            text = "TIEBREAK",
                            color = GoldColor,
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                }
            }

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(
                    onClick = onCycleSetsToWin,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFF1A1A1A),
                        contentColor = TextWhite,
                    ),
                ) {
                    Text(
                        text = if (setsToWin == 0) "SETS: \u221E" else "SETS: $setsToWin",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                    )
                }

                Button(
                    onClick = onReset,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFF1A1A1A),
                        contentColor = TextWhite,
                    ),
                ) {
                    Text("NEW MATCH", fontSize = 14.sp, fontWeight = FontWeight.Bold)
                }
            }
        }

        // Match over overlay
        if (state.isMatchOver) {
            val winnerColor = if (state.winner == 1) Team1Accent else Team2Accent
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color(0xDD000000))
                    .clickable { /* absorb taps */ },
                contentAlignment = Alignment.Center,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "MATCH OVER",
                        color = TextWhite,
                        fontSize = 52.sp,
                        fontWeight = FontWeight.Bold,
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Team ${state.winner} wins!",
                        color = winnerColor,
                        fontSize = 36.sp,
                        fontWeight = FontWeight.Bold,
                    )
                    Spacer(modifier = Modifier.height(40.dp))
                    Button(
                        onClick = onReset,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = winnerColor,
                            contentColor = Color.White,
                        ),
                    ) {
                        Text("NEW MATCH", fontSize = 20.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

@Composable
fun TeamPanel(
    teamLabel: String,
    pointDisplay: String,
    backgroundColor: Color,
    accentColor: Color,
    pointColor: Color,
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
        ) {
            // Team name
            Text(
                text = teamLabel,
                color = accentColor,
                fontSize = 36.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 3.sp,
            )

            // Current game score — THE BIG NUMBER
            Text(
                text = pointDisplay,
                color = pointColor,
                fontSize = 480.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
            )
        }
    }
}
