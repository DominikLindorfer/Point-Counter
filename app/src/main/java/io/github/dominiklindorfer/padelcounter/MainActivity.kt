package io.github.dominiklindorfer.padelcounter

import android.os.Bundle
import android.view.KeyEvent
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
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
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowLeft
import androidx.compose.material.icons.automirrored.filled.ArrowRight
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Repeat
import androidx.compose.material.icons.filled.SportsTennis
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
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

        // Keep screen on — prevents standby while the app is active
        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

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
                sidesSwapped = viewModel.sidesSwapped,
                onScore = { team -> viewModel.scorePoint(team) },
                onUndo = { viewModel.undo() },
                onReset = { viewModel.resetMatch() },
                onToggleGoldenPoint = { viewModel.toggleGoldenPoint() },
                onCycleSetsToWin = { viewModel.cycleSetsToWin() },
                onSwapSides = { viewModel.swapSides() },
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
            // Team 1 (blue): volume up, media next, or media play/pause
            KeyEvent.KEYCODE_VOLUME_UP,
            KeyEvent.KEYCODE_MEDIA_NEXT -> {
                viewModel.scorePoint(1); true
            }
            // Team 2 (red): volume down or media previous
            KeyEvent.KEYCODE_VOLUME_DOWN,
            KeyEvent.KEYCODE_MEDIA_PREVIOUS -> {
                viewModel.scorePoint(2); true
            }
            // Undo: media play/pause (center button)
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> {
                viewModel.undo(); true
            }
            else -> super.onKeyDown(keyCode, event)
        }
    }
}

// -- Colors --
private val DarkBg = Color(0xFF0D0D0D)
private val Team1Bg = Color(0xFF091426)
private val Team2Bg = Color(0xFF2A1215)
private val Team1Accent = Color(0xFF5BA8FF)
private val Team2Accent = Color(0xFFFF7A7A)
private val Team1Point = Color(0xFFFFFFFF)
private val Team2Point = Color(0xFFFFFFFF)
private val TextWhite = Color(0xFFFFFFFF)
private val DimColor = Color(0xFF999999)
private val GoldColor = Color(0xFFFFD700)
private val ButtonBg = Color(0xFF1A1A1A)
private val ButtonBgDisabled = Color(0xFF111111)

@Composable
fun ScoreBoard(
    state: MatchState,
    canUndo: Boolean,
    goldenPoint: Boolean,
    setsToWin: Int,
    sidesSwapped: Boolean,
    onScore: (Int) -> Unit,
    onUndo: () -> Unit,
    onReset: () -> Unit,
    onToggleGoldenPoint: () -> Unit,
    onCycleSetsToWin: () -> Unit,
    onSwapSides: () -> Unit,
) {
    val (display1, display2) = PadelScoring.displayPoints(state, goldenPoint)

    // Determine which team shows on which side
    val leftLabel = if (sidesSwapped) "TEAM 2" else "TEAM 1"
    val rightLabel = if (sidesSwapped) "TEAM 1" else "TEAM 2"
    val leftDisplay = if (sidesSwapped) display2 else display1
    val rightDisplay = if (sidesSwapped) display1 else display2
    val leftBg = if (sidesSwapped) Team2Bg else Team1Bg
    val rightBg = if (sidesSwapped) Team1Bg else Team2Bg
    val leftAccent = if (sidesSwapped) Team2Accent else Team1Accent
    val rightAccent = if (sidesSwapped) Team1Accent else Team2Accent
    val leftTeam = if (sidesSwapped) 2 else 1
    val rightTeam = if (sidesSwapped) 1 else 2

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBg),
    ) {
        // Main content: two halves
        Row(modifier = Modifier.fillMaxSize()) {
            TeamPanel(
                teamLabel = leftLabel,
                pointDisplay = leftDisplay,
                backgroundColor = leftBg,
                accentColor = leftAccent,
                pointColor = Team1Point,
                modifier = Modifier.weight(1f),
                onClick = { onScore(leftTeam) },
            )

            // Vertical divider
            Box(
                modifier = Modifier
                    .fillMaxHeight()
                    .width(2.dp)
                    .background(Color(0xFF222222)),
            )

            TeamPanel(
                teamLabel = rightLabel,
                pointDisplay = rightDisplay,
                backgroundColor = rightBg,
                accentColor = rightAccent,
                pointColor = Team2Point,
                modifier = Modifier.weight(1f),
                onClick = { onScore(rightTeam) },
            )
        }

        // Top-left buttons
        Row(
            modifier = Modifier
                .align(Alignment.TopStart)
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Button(
                onClick = onUndo,
                enabled = canUndo,
                colors = ButtonDefaults.buttonColors(
                    containerColor = ButtonBg,
                    contentColor = TextWhite,
                    disabledContainerColor = ButtonBgDisabled,
                    disabledContentColor = Color(0xFF444444),
                ),
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.Undo,
                    contentDescription = "Undo",
                    modifier = Modifier.size(20.dp),
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text("UNDO", fontSize = 14.sp, fontWeight = FontWeight.Bold)
            }

            Button(
                onClick = onToggleGoldenPoint,
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (goldenPoint) GoldColor else ButtonBg,
                    contentColor = if (goldenPoint) Color.Black else DimColor,
                ),
            ) {
                Icon(
                    imageVector = Icons.Filled.AutoAwesome,
                    contentDescription = "Golden Point",
                    modifier = Modifier.size(20.dp),
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = if (goldenPoint) "GOLDEN PT" else "ADVANTAGE",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                )
            }
        }

        // Top-right buttons
        Row(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Button(
                onClick = onSwapSides,
                colors = ButtonDefaults.buttonColors(
                    containerColor = ButtonBg,
                    contentColor = TextWhite,
                ),
            ) {
                Icon(
                    imageVector = Icons.Filled.SwapHoriz,
                    contentDescription = "Swap sides",
                    modifier = Modifier.size(20.dp),
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text("SWAP", fontSize = 14.sp, fontWeight = FontWeight.Bold)
            }

            Button(
                onClick = onCycleSetsToWin,
                colors = ButtonDefaults.buttonColors(
                    containerColor = ButtonBg,
                    contentColor = TextWhite,
                ),
            ) {
                Icon(
                    imageVector = Icons.Filled.Repeat,
                    contentDescription = "Sets to win",
                    modifier = Modifier.size(20.dp),
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = if (setsToWin == 0) "SETS: \u221E" else "SETS: $setsToWin",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                )
            }

            Button(
                onClick = onReset,
                colors = ButtonDefaults.buttonColors(
                    containerColor = ButtonBg,
                    contentColor = TextWhite,
                ),
            ) {
                Icon(
                    imageVector = Icons.Filled.Refresh,
                    contentDescription = "New Match",
                    modifier = Modifier.size(20.dp),
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text("NEW MATCH", fontSize = 14.sp, fontWeight = FontWeight.Bold)
            }
        }

        // Center-top: sets & games tracker — grows downward
        Box(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(top = 16.dp)
                .background(
                    color = ButtonBg,
                    shape = RoundedCornerShape(16.dp),
                )
                .padding(horizontal = 28.dp, vertical = 12.dp),
            contentAlignment = Alignment.Center,
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                val leftGames = if (sidesSwapped) state.team2Games else state.team1Games
                val rightGames = if (sidesSwapped) state.team1Games else state.team2Games

                leftGames.forEachIndexed { index, g ->
                    val isCurrentSet = index == state.currentSet && !state.isMatchOver
                    AnimatedVisibility(
                        visible = true,
                        enter = fadeIn(tween(300)) + slideInVertically(tween(300)),
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp),
                        ) {
                            Text(
                                text = "S${index + 1}",
                                color = if (isCurrentSet) TextWhite else DimColor,
                                fontSize = 28.sp,
                                fontWeight = FontWeight.Medium,
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            AnimatedContent(
                                targetState = g,
                                transitionSpec = {
                                    (slideInVertically { -it } + fadeIn()) togetherWith
                                            (slideOutVertically { it } + fadeOut())
                                },
                                label = "leftGames$index",
                            ) { games ->
                                Text(
                                    text = games.toString(),
                                    color = leftAccent,
                                    fontSize = 40.sp,
                                    fontWeight = FontWeight.Bold,
                                )
                            }
                            Text(
                                text = ":",
                                color = if (isCurrentSet) TextWhite else DimColor,
                                fontSize = 40.sp,
                                fontWeight = FontWeight.Bold,
                            )
                            AnimatedContent(
                                targetState = rightGames[index],
                                transitionSpec = {
                                    (slideInVertically { -it } + fadeIn()) togetherWith
                                            (slideOutVertically { it } + fadeOut())
                                },
                                label = "rightGames$index",
                            ) { games ->
                                Text(
                                    text = games.toString(),
                                    color = rightAccent,
                                    fontSize = 40.sp,
                                    fontWeight = FontWeight.Bold,
                                )
                            }
                        }
                    }
                }
                AnimatedVisibility(
                    visible = state.isTiebreak,
                    enter = fadeIn(tween(300)) + scaleIn(tween(300)),
                    exit = fadeOut(tween(200)) + scaleOut(tween(200)),
                ) {
                    Text(
                        text = "TIEBREAK",
                        color = GoldColor,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                    )
                }
            }
        }

        // Serve side indicator — bottom center
        if (!state.isMatchOver) {
            val totalPoints = state.team1Points + state.team2Points
            val serveRight = totalPoints % 2 == 0

            AnimatedContent(
                targetState = serveRight,
                transitionSpec = {
                    (fadeIn(tween(200)) + scaleIn(tween(200))) togetherWith
                            (fadeOut(tween(150)) + scaleOut(tween(150)))
                },
                label = "serveSide",
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 16.dp),
            ) { isRight ->
                Box(
                    modifier = Modifier
                        .background(
                            color = ButtonBg,
                            shape = RoundedCornerShape(16.dp),
                        )
                        .padding(horizontal = 24.dp, vertical = 12.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        if (!isRight) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.ArrowLeft,
                                contentDescription = "Serve left",
                                tint = GoldColor,
                                modifier = Modifier.size(48.dp),
                            )
                        }
                        Icon(
                            imageVector = Icons.Filled.SportsTennis,
                            contentDescription = "Serve",
                            tint = GoldColor,
                            modifier = Modifier.size(44.dp),
                        )
                        Text(
                            text = if (isRight) "RIGHT" else "LEFT",
                            color = GoldColor,
                            fontSize = 36.sp,
                            fontWeight = FontWeight.Bold,
                        )
                        if (isRight) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.ArrowRight,
                                contentDescription = "Serve right",
                                tint = GoldColor,
                                modifier = Modifier.size(48.dp),
                            )
                        }
                    }
                }
            }
        }

        // Match over overlay with animation
        AnimatedVisibility(
            visible = state.isMatchOver,
            enter = fadeIn(tween(500)),
            exit = fadeOut(tween(300)),
            modifier = Modifier.fillMaxSize(),
        ) {
            val winnerColor = if (state.winner == 1) Team1Accent else Team2Accent
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color(0xDD000000))
                    .clickable { /* absorb taps */ },
                contentAlignment = Alignment.Center,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    // Trophy with bounce animation
                    val trophyScale = remember { Animatable(0f) }
                    LaunchedEffect(Unit) {
                        trophyScale.animateTo(
                            targetValue = 1f,
                            animationSpec = spring(
                                dampingRatio = Spring.DampingRatioMediumBouncy,
                                stiffness = Spring.StiffnessLow,
                            ),
                        )
                    }
                    Icon(
                        imageVector = Icons.Filled.EmojiEvents,
                        contentDescription = "Trophy",
                        tint = GoldColor,
                        modifier = Modifier
                            .size(80.dp)
                            .scale(trophyScale.value),
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "MATCH OVER",
                        color = TextWhite,
                        fontSize = 52.sp,
                        fontWeight = FontWeight.Bold,
                    )
                    Spacer(modifier = Modifier.height(12.dp))
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
                        Icon(
                            imageVector = Icons.Filled.Refresh,
                            contentDescription = "New Match",
                            modifier = Modifier.size(24.dp),
                        )
                        Spacer(modifier = Modifier.width(8.dp))
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
    // Pulse animation on score change
    val scale = remember { Animatable(1f) }
    var scoreVersion by remember { mutableIntStateOf(0) }
    LaunchedEffect(pointDisplay) {
        scoreVersion++
        if (scoreVersion > 1) { // skip the initial composition
            scale.snapTo(1.08f)
            scale.animateTo(
                targetValue = 1f,
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioMediumBouncy,
                    stiffness = Spring.StiffnessMedium,
                ),
            )
        }
    }

    Box(
        modifier = modifier
            .fillMaxHeight()
            .background(backgroundColor)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
            ) { onClick() },
    ) {
        // Current game score — THE BIG NUMBER, centered
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center,
        ) {
            AnimatedContent(
                targetState = pointDisplay,
                transitionSpec = {
                    (slideInVertically { -it / 3 } + fadeIn(tween(200))) togetherWith
                            (slideOutVertically { it / 3 } + fadeOut(tween(150)))
                },
                label = "pointScore",
            ) { display ->
                Text(
                    text = display,
                    color = pointColor,
                    fontSize = 480.sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.graphicsLayer {
                        scaleX = scale.value
                        scaleY = scale.value
                    },
                )
            }
        }

        // Team name at the bottom with tennis icon
        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 24.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Icon(
                imageVector = Icons.Filled.SportsTennis,
                contentDescription = null,
                tint = accentColor,
                modifier = Modifier.size(28.dp),
            )
            Text(
                text = teamLabel,
                color = accentColor,
                fontSize = 36.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 3.sp,
            )
        }
    }
}
