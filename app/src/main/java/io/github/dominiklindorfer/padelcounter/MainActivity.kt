package io.github.dominiklindorfer.padelcounter

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
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
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowLeft
import androidx.compose.material.icons.automirrored.filled.ArrowRight
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Repeat
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.SportsTennis
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import kotlinx.coroutines.delay

class MainActivity : ComponentActivity() {

    private val viewModel: MatchViewModel by viewModels {
        MatchViewModelFactory(MatchStorage(this))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        WindowCompat.setDecorFitsSystemWindows(window, false)
        WindowInsetsControllerCompat(window, window.decorView).let { controller ->
            controller.hide(WindowInsetsCompat.Type.systemBars())
            controller.systemBarsBehavior =
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }

        setContent {
            var showHistory by remember { mutableStateOf(false) }

            if (showHistory) {
                MatchHistoryScreen(
                    vm = viewModel,
                    onBack = { showHistory = false },
                )
            } else {
                ScoreBoard(
                    vm = viewModel,
                    onShowHistory = { showHistory = true },
                )
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP,
            KeyEvent.KEYCODE_MEDIA_NEXT -> {
                viewModel.scorePoint(1); true
            }
            KeyEvent.KEYCODE_VOLUME_DOWN,
            KeyEvent.KEYCODE_MEDIA_PREVIOUS -> {
                viewModel.scorePoint(2); true
            }
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> {
                viewModel.undo(); true
            }
            else -> super.onKeyDown(keyCode, event)
        }
    }
}

// -- Colors --
private val DarkBg = Color(0xFF0D0D0D)
private val TextWhite = Color(0xFFFFFFFF)
private val DimColor = Color(0xFF999999)
private val GoldColor = Color(0xFFFFD700)
private val ButtonBg = Color(0xFF1A1A1A)
private val ButtonBgDisabled = Color(0xFF111111)
private val SettingsBg = Color(0xFF161616)
private val SettingsSurface = Color(0xFF222222)

@Composable
fun ScoreBoard(vm: MatchViewModel, onShowHistory: () -> Unit = {}) {
    val state = vm.state
    val (display1, display2) = PadelScoring.displayPoints(state, vm.goldenPoint)

    // Dynamic colors from settings
    val t1Color = teamColorPresets[vm.team1ColorIndex]
    val t2Color = teamColorPresets[vm.team2ColorIndex]
    val team1Bg = Color(t1Color.bg)
    val team1Accent = Color(t1Color.accent)
    val team2Bg = Color(t2Color.bg)
    val team2Accent = Color(t2Color.accent)

    // Determine which team shows on which side
    val leftName = if (vm.sidesSwapped) vm.team2Name else vm.team1Name
    val rightName = if (vm.sidesSwapped) vm.team1Name else vm.team2Name
    val leftDisplay = if (vm.sidesSwapped) display2 else display1
    val rightDisplay = if (vm.sidesSwapped) display1 else display2
    val leftBg = if (vm.sidesSwapped) team2Bg else team1Bg
    val rightBg = if (vm.sidesSwapped) team1Bg else team2Bg
    val leftAccent = if (vm.sidesSwapped) team2Accent else team1Accent
    val rightAccent = if (vm.sidesSwapped) team1Accent else team2Accent
    val leftTeam = if (vm.sidesSwapped) 2 else 1
    val rightTeam = if (vm.sidesSwapped) 1 else 2
    val leftSets = if (vm.sidesSwapped) state.team2Sets else state.team1Sets
    val rightSets = if (vm.sidesSwapped) state.team1Sets else state.team2Sets
    val leftGamesList = if (vm.sidesSwapped) state.team2Games else state.team1Games
    val rightGamesList = if (vm.sidesSwapped) state.team1Games else state.team2Games

    // Serving team mapped to left/right
    val servingOnLeft = (vm.servingTeam == 1 && !vm.sidesSwapped) ||
            (vm.servingTeam == 2 && vm.sidesSwapped)

    var showSettings by remember { mutableStateOf(false) }
    var showCamera by remember { mutableStateOf(false) }
    val context = LocalContext.current

    val cameraPermissions = remember {
        buildList {
            add(Manifest.permission.CAMERA)
            add(Manifest.permission.RECORD_AUDIO)
            if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
                add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            }
        }.toTypedArray()
    }

    val cameraPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        if (permissions.values.all { it }) {
            showCamera = true
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBg),
    ) {
        // Main content: two halves
        Row(modifier = Modifier.fillMaxSize()) {
            TeamPanel(
                teamLabel = leftName,
                pointDisplay = leftDisplay,
                backgroundColor = leftBg,
                accentColor = leftAccent,
                isServing = servingOnLeft,
                setsWon = leftSets,
                gamesList = leftGamesList,
                opponentGamesList = rightGamesList,
                currentSet = state.currentSet,
                isMatchOver = state.isMatchOver,
                isTiebreak = state.isTiebreak,
                modifier = Modifier.weight(1f),
                onClick = { vm.scorePoint(leftTeam) },
            )

            Box(
                modifier = Modifier
                    .fillMaxHeight()
                    .width(2.dp)
                    .background(Color(0xFF222222)),
            )

            TeamPanel(
                teamLabel = rightName,
                pointDisplay = rightDisplay,
                backgroundColor = rightBg,
                accentColor = rightAccent,
                isServing = !servingOnLeft,
                setsWon = rightSets,
                gamesList = rightGamesList,
                opponentGamesList = leftGamesList,
                currentSet = state.currentSet,
                isMatchOver = state.isMatchOver,
                isTiebreak = state.isTiebreak,
                gamesBoxAtStart = true,
                modifier = Modifier.weight(1f),
                onClick = { vm.scorePoint(rightTeam) },
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
                onClick = { vm.undo() },
                enabled = vm.canUndo,
                colors = ButtonDefaults.buttonColors(
                    containerColor = ButtonBg,
                    contentColor = TextWhite,
                    disabledContainerColor = ButtonBgDisabled,
                    disabledContentColor = Color(0xFF444444),
                ),
            ) {
                Icon(Icons.AutoMirrored.Filled.Undo, "Undo", Modifier.size(20.dp))
                Spacer(Modifier.width(6.dp))
                Text("UNDO", fontSize = 14.sp, fontWeight = FontWeight.Bold)
            }

            Button(
                onClick = { vm.swapSides() },
                colors = ButtonDefaults.buttonColors(
                    containerColor = ButtonBg,
                    contentColor = TextWhite,
                ),
            ) {
                Icon(Icons.Filled.SwapHoriz, "Swap", Modifier.size(20.dp))
                Spacer(Modifier.width(6.dp))
                Text("SWAP", fontSize = 14.sp, fontWeight = FontWeight.Bold)
            }

            Button(
                onClick = {
                    if (showCamera) {
                        showCamera = false
                    } else {
                        val allGranted = cameraPermissions.all {
                            ContextCompat.checkSelfPermission(context, it) ==
                                PackageManager.PERMISSION_GRANTED
                        }
                        if (allGranted) {
                            showCamera = true
                        } else {
                            cameraPermissionLauncher.launch(cameraPermissions)
                        }
                    }
                },
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (showCamera) Color(0xFF8B0000) else ButtonBg,
                    contentColor = TextWhite,
                ),
            ) {
                Icon(Icons.Filled.Videocam, "Camera", Modifier.size(20.dp))
            }
        }

        // Top-right buttons
        Row(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            // Match timer
            MatchTimer(vm)

            Button(
                onClick = { vm.resetMatch() },
                colors = ButtonDefaults.buttonColors(
                    containerColor = ButtonBg,
                    contentColor = TextWhite,
                ),
            ) {
                Icon(Icons.Filled.Refresh, "New Match", Modifier.size(20.dp))
                Spacer(Modifier.width(6.dp))
                Text("NEW MATCH", fontSize = 14.sp, fontWeight = FontWeight.Bold)
            }

            Button(
                onClick = { showSettings = true },
                colors = ButtonDefaults.buttonColors(
                    containerColor = ButtonBg,
                    contentColor = TextWhite,
                ),
            ) {
                Icon(Icons.Filled.Settings, "Settings", Modifier.size(20.dp))
            }
        }

        // Completed set scores — bottom center
        if (leftGamesList.size > 1 || (leftGamesList.size == 1 && !state.isMatchOver && state.currentSet > 0)) {
            Row(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                leftGamesList.forEachIndexed { index, _ ->
                    if (index < state.currentSet || (state.isMatchOver && index <= state.currentSet)) {
                        val lg = leftGamesList[index]
                        val rg = rightGamesList[index]
                        Box(
                            modifier = Modifier
                                .background(ButtonBg, RoundedCornerShape(10.dp))
                                .padding(horizontal = 16.dp, vertical = 6.dp),
                            contentAlignment = Alignment.Center,
                        ) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(
                                    "SET ${index + 1}",
                                    color = DimColor,
                                    fontSize = 16.sp,
                                    fontWeight = FontWeight.Medium,
                                    letterSpacing = 1.sp,
                                )
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                                ) {
                                    Text(
                                        lg.toString(),
                                        color = leftAccent,
                                        fontSize = 40.sp,
                                        fontWeight = FontWeight.Bold,
                                    )
                                    Text(
                                        ":",
                                        color = DimColor,
                                        fontSize = 40.sp,
                                        fontWeight = FontWeight.Bold,
                                    )
                                    Text(
                                        rg.toString(),
                                        color = rightAccent,
                                        fontSize = 40.sp,
                                        fontWeight = FontWeight.Bold,
                                    )
                                }
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
                        "TIEBREAK",
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
                    .padding(bottom = 130.dp),
            ) { isRight ->
                Box(
                    modifier = Modifier
                        .background(ButtonBg, RoundedCornerShape(16.dp))
                        .padding(horizontal = 24.dp, vertical = 12.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        if (!isRight) {
                            Icon(Icons.AutoMirrored.Filled.ArrowLeft, "Left",
                                tint = GoldColor, modifier = Modifier.size(48.dp))
                        }
                        Icon(Icons.Filled.SportsTennis, "Serve",
                            tint = GoldColor, modifier = Modifier.size(44.dp))
                        Text(
                            text = if (isRight) "RIGHT" else "LEFT",
                            color = GoldColor, fontSize = 36.sp, fontWeight = FontWeight.Bold,
                        )
                        if (isRight) {
                            Icon(Icons.AutoMirrored.Filled.ArrowRight, "Right",
                                tint = GoldColor, modifier = Modifier.size(48.dp))
                        }
                    }
                }
            }
        }

        // Match over overlay
        AnimatedVisibility(
            visible = state.isMatchOver,
            enter = fadeIn(tween(500)),
            exit = fadeOut(tween(300)),
            modifier = Modifier.fillMaxSize(),
        ) {
            val winnerName = if (state.winner == 1) vm.team1Name else vm.team2Name
            val winnerColor = if (state.winner == 1) team1Accent else team2Accent
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color(0xDD000000))
                    .clickable { },
                contentAlignment = Alignment.Center,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    val trophyScale = remember { Animatable(0f) }
                    LaunchedEffect(Unit) {
                        trophyScale.animateTo(1f, spring(
                            Spring.DampingRatioMediumBouncy, Spring.StiffnessLow))
                    }
                    Icon(Icons.Filled.EmojiEvents, "Trophy", tint = GoldColor,
                        modifier = Modifier.size(80.dp).scale(trophyScale.value))
                    Spacer(Modifier.height(16.dp))
                    Text("MATCH OVER", color = TextWhite, fontSize = 52.sp, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.height(12.dp))
                    Text("$winnerName wins!", color = winnerColor, fontSize = 36.sp, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.height(40.dp))
                    Button(
                        onClick = { vm.resetMatch() },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = winnerColor, contentColor = Color.White),
                    ) {
                        Icon(Icons.Filled.Refresh, "New Match", Modifier.size(24.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("NEW MATCH", fontSize = 20.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }

        // Camera overlay — bottom left
        AnimatedVisibility(
            visible = showCamera,
            enter = fadeIn(tween(300)) + scaleIn(tween(300)),
            exit = fadeOut(tween(200)) + scaleOut(tween(200)),
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(start = 16.dp, bottom = 80.dp),
        ) {
            CameraPreviewOverlay(
                onClose = { showCamera = false },
            )
        }

        // Settings sidebar
        SettingsSidebar(
            visible = showSettings,
            vm = vm,
            team1Accent = team1Accent,
            team2Accent = team2Accent,
            onClose = { showSettings = false },
            onShowHistory = onShowHistory,
        )
    }
}

@Composable
fun MatchTimer(vm: MatchViewModel) {
    var elapsed by remember { mutableLongStateOf(0L) }

    LaunchedEffect(vm.matchRunning) {
        while (vm.matchRunning) {
            elapsed = System.currentTimeMillis() - vm.matchStartTimeMs
            delay(1000)
        }
    }

    if (vm.matchRunning || elapsed > 0) {
        val totalSec = elapsed / 1000
        val min = totalSec / 60
        val sec = totalSec % 60
        Box(
            modifier = Modifier
                .background(ButtonBg, RoundedCornerShape(50))
                .padding(horizontal = 16.dp, vertical = 10.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Timer, "Timer", tint = GoldColor, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(6.dp))
                Text(
                    text = "%d:%02d".format(min, sec),
                    color = TextWhite,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                )
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun SettingsSidebar(
    visible: Boolean,
    vm: MatchViewModel,
    team1Accent: Color,
    team2Accent: Color,
    onClose: () -> Unit,
    onShowHistory: () -> Unit = {},
) {
    val offsetX by animateFloatAsState(
        targetValue = if (visible) 0f else 1f,
        animationSpec = tween(300),
        label = "settingsSlide",
    )

    if (offsetX < 1f) {
        // Dim overlay
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black.copy(alpha = 0.5f * (1f - offsetX)))
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                ) { onClose() },
        )

        // Sidebar — anchored to right edge
        Row(modifier = Modifier.fillMaxSize()) {
            Spacer(modifier = Modifier.weight(1f))
            Box(
                modifier = Modifier
                    .fillMaxHeight()
                    .width(400.dp)
                    .graphicsLayer { translationX = offsetX * 400.dp.toPx() }
                    .background(SettingsBg)
                    .padding(24.dp),
            ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState()),
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Settings, "Settings", tint = TextWhite, modifier = Modifier.size(28.dp))
                        Spacer(Modifier.width(12.dp))
                        Text("SETTINGS", color = TextWhite, fontSize = 24.sp, fontWeight = FontWeight.Bold)
                    }
                    IconButton(onClick = onClose) {
                        Icon(Icons.Filled.Close, "Close", tint = TextWhite, modifier = Modifier.size(28.dp))
                    }
                }

                Spacer(Modifier.height(24.dp))
                HorizontalDivider(color = Color(0xFF333333))
                Spacer(Modifier.height(20.dp))

                // --- Team 1 settings ---
                SectionHeader("Team 1", team1Accent)
                Spacer(Modifier.height(12.dp))
                SettingsLabel("Name")
                NameField(vm.team1Name) { vm.updateTeam1Name(it) }
                Spacer(Modifier.height(12.dp))
                SettingsLabel("Color")
                ColorPicker(vm.team1ColorIndex) { vm.updateTeam1Color(it) }

                Spacer(Modifier.height(24.dp))
                HorizontalDivider(color = Color(0xFF333333))
                Spacer(Modifier.height(20.dp))

                // --- Team 2 settings ---
                SectionHeader("Team 2", team2Accent)
                Spacer(Modifier.height(12.dp))
                SettingsLabel("Name")
                NameField(vm.team2Name) { vm.updateTeam2Name(it) }
                Spacer(Modifier.height(12.dp))
                SettingsLabel("Color")
                ColorPicker(vm.team2ColorIndex) { vm.updateTeam2Color(it) }

                Spacer(Modifier.height(24.dp))
                HorizontalDivider(color = Color(0xFF333333))
                Spacer(Modifier.height(20.dp))

                // --- Match rules ---
                SectionHeader("Match Rules", GoldColor)
                Spacer(Modifier.height(16.dp))

                // Golden point toggle
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(SettingsSurface, RoundedCornerShape(12.dp))
                        .clickable { vm.toggleGoldenPoint() }
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.AutoAwesome, "Scoring",
                            tint = if (vm.goldenPoint) GoldColor else DimColor, modifier = Modifier.size(24.dp))
                        Spacer(Modifier.width(12.dp))
                        Text("Scoring Mode", color = TextWhite, fontSize = 16.sp)
                    }
                    Text(
                        text = if (vm.goldenPoint) "GOLDEN PT" else "ADVANTAGE",
                        color = if (vm.goldenPoint) GoldColor else DimColor,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                    )
                }

                Spacer(Modifier.height(8.dp))

                // Sets to win
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(SettingsSurface, RoundedCornerShape(12.dp))
                        .clickable { vm.cycleSetsToWin() }
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Repeat, "Sets",
                            tint = DimColor, modifier = Modifier.size(24.dp))
                        Spacer(Modifier.width(12.dp))
                        Text("Sets to Win", color = TextWhite, fontSize = 16.sp)
                    }
                    Text(
                        text = if (vm.setsToWin == 0) "\u221E" else "${vm.setsToWin}",
                        color = TextWhite, fontSize = 18.sp, fontWeight = FontWeight.Bold,
                    )
                }

                Spacer(Modifier.height(8.dp))

                // First serve
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(SettingsSurface, RoundedCornerShape(12.dp))
                        .clickable { vm.updateServingTeam(if (vm.servingTeam == 1) 2 else 1) }
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.SportsTennis, "Serve",
                            tint = DimColor, modifier = Modifier.size(24.dp))
                        Spacer(Modifier.width(12.dp))
                        Text("Serving", color = TextWhite, fontSize = 16.sp)
                    }
                    val serveName = if (vm.servingTeam == 1) vm.team1Name else vm.team2Name
                    val serveColor = if (vm.servingTeam == 1) team1Accent else team2Accent
                    Text(serveName, color = serveColor, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                }

                Spacer(Modifier.height(24.dp))
                HorizontalDivider(color = Color(0xFF333333))
                Spacer(Modifier.height(20.dp))

                // Match history button
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(SettingsSurface, RoundedCornerShape(12.dp))
                        .clickable {
                            onClose()
                            onShowHistory()
                        }
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Filled.History, "History",
                        tint = GoldColor, modifier = Modifier.size(24.dp))
                    Spacer(Modifier.width(12.dp))
                    Text("Match History", color = TextWhite, fontSize = 16.sp)
                }
            }
            }
        }
    }
}

// -- Setting helpers --
@Composable
private fun SectionHeader(title: String, color: Color) {
    Text(
        text = title.uppercase(),
        color = color,
        fontSize = 18.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = 2.sp,
    )
}

@Composable
private fun SettingsLabel(label: String) {
    Text(label, color = DimColor, fontSize = 13.sp, fontWeight = FontWeight.Medium)
    Spacer(Modifier.height(6.dp))
}

@Composable
private fun NameField(value: String, onValueChange: (String) -> Unit) {
    BasicTextField(
        value = value,
        onValueChange = { if (it.length <= 16) onValueChange(it) },
        singleLine = true,
        textStyle = TextStyle(
            color = TextWhite,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
        ),
        cursorBrush = SolidColor(TextWhite),
        modifier = Modifier
            .fillMaxWidth()
            .background(SettingsSurface, RoundedCornerShape(12.dp))
            .padding(16.dp),
    )
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ColorPicker(selectedIndex: Int, onSelect: (Int) -> Unit) {
    FlowRow(
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        teamColorPresets.forEachIndexed { index, preset ->
            val isSelected = index == selectedIndex
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(Color(preset.accent))
                    .then(
                        if (isSelected) Modifier.border(3.dp, TextWhite, CircleShape)
                        else Modifier
                    )
                    .clickable { onSelect(index) },
            )
        }
    }
}

@Composable
fun TeamPanel(
    teamLabel: String,
    pointDisplay: String,
    backgroundColor: Color,
    accentColor: Color,
    isServing: Boolean,
    setsWon: Int,
    gamesList: List<Int>,
    opponentGamesList: List<Int>,
    currentSet: Int,
    isMatchOver: Boolean,
    isTiebreak: Boolean,
    gamesBoxAtStart: Boolean = false,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    val scale = remember { Animatable(1f) }
    var scoreVersion by remember { mutableIntStateOf(0) }
    LaunchedEffect(pointDisplay) {
        scoreVersion++
        if (scoreVersion > 1) {
            scale.snapTo(1.08f)
            scale.animateTo(1f, spring(Spring.DampingRatioMediumBouncy, Spring.StiffnessMedium))
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
        // Current set games — top corner near center
        val currentGames = gamesList.getOrElse(currentSet) { 0 }
        Box(
            modifier = Modifier
                .align(if (gamesBoxAtStart) Alignment.TopStart else Alignment.TopEnd)
                .padding(top = 16.dp, start = 16.dp, end = 16.dp)
                .background(Color.Black.copy(alpha = 0.3f), RoundedCornerShape(20.dp))
                .padding(horizontal = 32.dp, vertical = 8.dp),
            contentAlignment = Alignment.Center,
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Text(
                    "GAMES",
                    color = accentColor,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 3.sp,
                )
                AnimatedContent(
                    targetState = currentGames,
                    transitionSpec = {
                        (slideInVertically { -it } + fadeIn()) togetherWith
                                (slideOutVertically { it } + fadeOut())
                    },
                    label = "currentGames",
                ) { games ->
                    Text(
                        text = games.toString(),
                        color = TextWhite,
                        fontSize = 150.sp,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center,
                    )
                }
            }
        }

        // Big score number — centered
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
                    color = TextWhite,
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

        // Team name — top corner opposite to GAMES box
        Row(
            modifier = Modifier
                .align(if (gamesBoxAtStart) Alignment.TopEnd else Alignment.TopStart)
                .padding(top = 125.dp, start = 86.dp, end = 86.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            if (isServing) {
                Icon(Icons.Filled.SportsTennis, "Serving",
                    tint = GoldColor, modifier = Modifier.size(28.dp))
            }
            Text(
                text = teamLabel,
                color = accentColor,
                fontSize = 56.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 3.sp,
            )
        }

    }
}
