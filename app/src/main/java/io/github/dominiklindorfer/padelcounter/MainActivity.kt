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
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
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
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.LocalMinimumInteractiveComponentSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
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
import androidx.compose.ui.platform.LocalConfiguration
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

@OptIn(ExperimentalMaterial3Api::class)
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
    val cfg = LocalConfiguration.current
    val screenScale = minOf(cfg.screenHeightDp / 800f, cfg.screenWidthDp / 1333f).coerceIn(0.4f, 1f)

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

    val scaledButtonPadding = PaddingValues(horizontal = (24 * screenScale).dp, vertical = (8 * screenScale).dp)

    CompositionLocalProvider(LocalMinimumInteractiveComponentSize provides 0.dp) {
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
                .padding((16 * screenScale).dp),
            horizontalArrangement = Arrangement.spacedBy((8 * screenScale).dp),
        ) {
            Button(
                onClick = { vm.undo() },
                enabled = vm.canUndo,
                contentPadding = scaledButtonPadding,
                colors = ButtonDefaults.buttonColors(
                    containerColor = ButtonBg,
                    contentColor = TextWhite,
                    disabledContainerColor = ButtonBgDisabled,
                    disabledContentColor = Color(0xFF444444),
                ),
            ) {
                Icon(Icons.AutoMirrored.Filled.Undo, "Undo", Modifier.size((20 * screenScale).dp))
                Spacer(Modifier.width((6 * screenScale).dp))
                Text("UNDO", fontSize = (14 * screenScale).sp, fontWeight = FontWeight.Bold)
            }

            Button(
                onClick = { vm.swapSides() },
                contentPadding = scaledButtonPadding,
                colors = ButtonDefaults.buttonColors(
                    containerColor = ButtonBg,
                    contentColor = TextWhite,
                ),
            ) {
                Icon(Icons.Filled.SwapHoriz, "Swap", Modifier.size((20 * screenScale).dp))
                Spacer(Modifier.width((6 * screenScale).dp))
                Text("SWAP", fontSize = (14 * screenScale).sp, fontWeight = FontWeight.Bold)
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
                contentPadding = scaledButtonPadding,
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (showCamera) Color(0xFF8B0000) else ButtonBg,
                    contentColor = TextWhite,
                ),
            ) {
                Icon(Icons.Filled.Videocam, "Camera", Modifier.size((20 * screenScale).dp))
            }
        }

        // Top-right buttons
        Row(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding((16 * screenScale).dp),
            horizontalArrangement = Arrangement.spacedBy((8 * screenScale).dp),
        ) {
            // Match timer
            MatchTimer(vm, screenScale)

            Button(
                onClick = { vm.resetMatch() },
                contentPadding = scaledButtonPadding,
                colors = ButtonDefaults.buttonColors(
                    containerColor = ButtonBg,
                    contentColor = TextWhite,
                ),
            ) {
                Icon(Icons.Filled.Refresh, "New Match", Modifier.size((20 * screenScale).dp))
                Spacer(Modifier.width((6 * screenScale).dp))
                Text("NEW MATCH", fontSize = (14 * screenScale).sp, fontWeight = FontWeight.Bold)
            }

            Button(
                onClick = { showSettings = true },
                contentPadding = scaledButtonPadding,
                colors = ButtonDefaults.buttonColors(
                    containerColor = ButtonBg,
                    contentColor = TextWhite,
                ),
            ) {
                Icon(Icons.Filled.Settings, "Settings", Modifier.size((20 * screenScale).dp))
            }
        }

        // Completed set scores — bottom center
        if (leftGamesList.size > 1 || (leftGamesList.size == 1 && !state.isMatchOver && state.currentSet > 0)) {
            Row(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = (16 * screenScale).dp),
                horizontalArrangement = Arrangement.spacedBy((16 * screenScale).dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                leftGamesList.forEachIndexed { index, _ ->
                    if (index < state.currentSet || (state.isMatchOver && index <= state.currentSet)) {
                        val lg = leftGamesList[index]
                        val rg = rightGamesList[index]
                        Box(
                            modifier = Modifier
                                .background(ButtonBg, RoundedCornerShape((10 * screenScale).dp))
                                .padding(horizontal = (16 * screenScale).dp, vertical = (6 * screenScale).dp),
                            contentAlignment = Alignment.Center,
                        ) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(
                                    "SET ${index + 1}",
                                    color = DimColor,
                                    fontSize = (16 * screenScale).sp,
                                    fontWeight = FontWeight.Medium,
                                    letterSpacing = (1 * screenScale).sp,
                                )
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy((4 * screenScale).dp),
                                ) {
                                    Text(
                                        lg.toString(),
                                        color = leftBg,
                                        fontSize = (40 * screenScale).sp,
                                        fontWeight = FontWeight.Bold,
                                    )
                                    Text(
                                        ":",
                                        color = DimColor,
                                        fontSize = (40 * screenScale).sp,
                                        fontWeight = FontWeight.Bold,
                                    )
                                    Text(
                                        rg.toString(),
                                        color = rightBg,
                                        fontSize = (40 * screenScale).sp,
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
                        fontSize = (18 * screenScale).sp,
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
                    .padding(bottom = (110 * screenScale).dp),
            ) { isRight ->
                Box(
                    modifier = Modifier
                        .background(ButtonBg, RoundedCornerShape((16 * screenScale).dp))
                        .padding(horizontal = (24 * screenScale).dp, vertical = (12 * screenScale).dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy((12 * screenScale).dp),
                    ) {
                        if (!isRight) {
                            Icon(Icons.AutoMirrored.Filled.ArrowLeft, "Left",
                                tint = GoldColor, modifier = Modifier.size((48 * screenScale).dp))
                        }
                        Icon(Icons.Filled.SportsTennis, "Serve",
                            tint = GoldColor, modifier = Modifier.size((44 * screenScale).dp))
                        Text(
                            text = if (isRight) "RIGHT" else "LEFT",
                            color = GoldColor, fontSize = (36 * screenScale).sp, fontWeight = FontWeight.Bold,
                        )
                        if (isRight) {
                            Icon(Icons.AutoMirrored.Filled.ArrowRight, "Right",
                                tint = GoldColor, modifier = Modifier.size((48 * screenScale).dp))
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
                        modifier = Modifier.size((80 * screenScale).dp).scale(trophyScale.value))
                    Spacer(Modifier.height((16 * screenScale).dp))
                    Text("MATCH OVER", color = TextWhite, fontSize = (52 * screenScale).sp, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.height((12 * screenScale).dp))
                    Text("$winnerName wins!", color = winnerColor, fontSize = (36 * screenScale).sp, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.height((24 * screenScale).dp))
                    Row(
                        horizontalArrangement = Arrangement.spacedBy((16 * screenScale).dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        leftGamesList.forEachIndexed { index, _ ->
                            if (index <= state.currentSet) {
                                val lg = leftGamesList[index]
                                val rg = rightGamesList[index]
                                Box(
                                    modifier = Modifier
                                        .background(ButtonBg, RoundedCornerShape((12 * screenScale).dp))
                                        .padding(horizontal = (16 * screenScale).dp, vertical = (8 * screenScale).dp),
                                    contentAlignment = Alignment.Center,
                                ) {
                                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                        Text(
                                            "SET ${index + 1}",
                                            color = DimColor,
                                            fontSize = (14 * screenScale).sp,
                                            fontWeight = FontWeight.Medium,
                                            letterSpacing = (1 * screenScale).sp,
                                        )
                                        Row(
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.spacedBy((4 * screenScale).dp),
                                        ) {
                                            Text(lg.toString(), color = leftBg, fontSize = (36 * screenScale).sp, fontWeight = FontWeight.Bold)
                                            Text(":", color = DimColor, fontSize = (36 * screenScale).sp, fontWeight = FontWeight.Bold)
                                            Text(rg.toString(), color = rightBg, fontSize = (36 * screenScale).sp, fontWeight = FontWeight.Bold)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Spacer(Modifier.height((32 * screenScale).dp))
                    Button(
                        onClick = { vm.resetMatch() },
                        contentPadding = scaledButtonPadding,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = winnerColor, contentColor = Color.White),
                    ) {
                        Icon(Icons.Filled.Refresh, "New Match", Modifier.size((24 * screenScale).dp))
                        Spacer(Modifier.width((8 * screenScale).dp))
                        Text("NEW MATCH", fontSize = (20 * screenScale).sp, fontWeight = FontWeight.Bold)
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
                .padding(start = (16 * screenScale).dp, bottom = (80 * screenScale).dp),
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
            screenScale = screenScale,
            onClose = { showSettings = false },
            onShowHistory = onShowHistory,
        )
    }
    } // CompositionLocalProvider
}

@Composable
fun MatchTimer(vm: MatchViewModel, screenScale: Float = 1f) {
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
        // Keep original sizes (10+20+10 = 40dp tall) to match Button's 40dp minHeight
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
    screenScale: Float = 1f,
    onClose: () -> Unit,
    onShowHistory: () -> Unit = {},
) {
    val s = screenScale.coerceAtLeast(0.6f) // gentler minimum for readable settings
    val sidebarWidth = (400 * s).dp

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
                    .width(sidebarWidth)
                    .graphicsLayer { translationX = offsetX * sidebarWidth.toPx() }
                    .background(SettingsBg)
                    .padding((24 * s).dp),
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
                        Icon(Icons.Filled.Settings, "Settings", tint = TextWhite, modifier = Modifier.size((28 * s).dp))
                        Spacer(Modifier.width((12 * s).dp))
                        Text("SETTINGS", color = TextWhite, fontSize = (24 * s).sp, fontWeight = FontWeight.Bold)
                    }
                    IconButton(onClick = onClose) {
                        Icon(Icons.Filled.Close, "Close", tint = TextWhite, modifier = Modifier.size((28 * s).dp))
                    }
                }

                Spacer(Modifier.height((24 * s).dp))
                HorizontalDivider(color = Color(0xFF333333))
                Spacer(Modifier.height((20 * s).dp))

                // --- Team 1 settings ---
                SectionHeader("Team 1", team1Accent, s)
                Spacer(Modifier.height((12 * s).dp))
                SettingsLabel("Name", s)
                NameField(vm.team1Name, s) { vm.updateTeam1Name(it) }
                Spacer(Modifier.height((12 * s).dp))
                SettingsLabel("Color", s)
                ColorPicker(vm.team1ColorIndex, s) { vm.updateTeam1Color(it) }

                Spacer(Modifier.height((24 * s).dp))
                HorizontalDivider(color = Color(0xFF333333))
                Spacer(Modifier.height((20 * s).dp))

                // --- Team 2 settings ---
                SectionHeader("Team 2", team2Accent, s)
                Spacer(Modifier.height((12 * s).dp))
                SettingsLabel("Name", s)
                NameField(vm.team2Name, s) { vm.updateTeam2Name(it) }
                Spacer(Modifier.height((12 * s).dp))
                SettingsLabel("Color", s)
                ColorPicker(vm.team2ColorIndex, s) { vm.updateTeam2Color(it) }

                Spacer(Modifier.height((24 * s).dp))
                HorizontalDivider(color = Color(0xFF333333))
                Spacer(Modifier.height((20 * s).dp))

                // --- Match rules ---
                SectionHeader("Match Rules", GoldColor, s)
                Spacer(Modifier.height((16 * s).dp))

                // Golden point toggle
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(SettingsSurface, RoundedCornerShape((12 * s).dp))
                        .clickable { vm.toggleGoldenPoint() }
                        .padding((16 * s).dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.AutoAwesome, "Scoring",
                            tint = if (vm.goldenPoint) GoldColor else DimColor, modifier = Modifier.size((24 * s).dp))
                        Spacer(Modifier.width((12 * s).dp))
                        Text("Scoring Mode", color = TextWhite, fontSize = (16 * s).sp)
                    }
                    Text(
                        text = if (vm.goldenPoint) "GOLDEN PT" else "ADVANTAGE",
                        color = if (vm.goldenPoint) GoldColor else DimColor,
                        fontSize = (14 * s).sp,
                        fontWeight = FontWeight.Bold,
                    )
                }

                Spacer(Modifier.height((8 * s).dp))

                // Sets to win
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(SettingsSurface, RoundedCornerShape((12 * s).dp))
                        .clickable { vm.cycleSetsToWin() }
                        .padding((16 * s).dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Repeat, "Sets",
                            tint = DimColor, modifier = Modifier.size((24 * s).dp))
                        Spacer(Modifier.width((12 * s).dp))
                        Text("Sets to Win", color = TextWhite, fontSize = (16 * s).sp)
                    }
                    Text(
                        text = if (vm.setsToWin == 0) "\u221E" else "${vm.setsToWin}",
                        color = TextWhite, fontSize = (18 * s).sp, fontWeight = FontWeight.Bold,
                    )
                }

                Spacer(Modifier.height((8 * s).dp))

                // First serve
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(SettingsSurface, RoundedCornerShape((12 * s).dp))
                        .clickable { vm.updateServingTeam(if (vm.servingTeam == 1) 2 else 1) }
                        .padding((16 * s).dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.SportsTennis, "Serve",
                            tint = DimColor, modifier = Modifier.size((24 * s).dp))
                        Spacer(Modifier.width((12 * s).dp))
                        Text("Serving", color = TextWhite, fontSize = (16 * s).sp)
                    }
                    val serveName = if (vm.servingTeam == 1) vm.team1Name else vm.team2Name
                    val serveColor = if (vm.servingTeam == 1) team1Accent else team2Accent
                    Text(serveName, color = serveColor, fontSize = (14 * s).sp, fontWeight = FontWeight.Bold)
                }

                Spacer(Modifier.height((24 * s).dp))
                HorizontalDivider(color = Color(0xFF333333))
                Spacer(Modifier.height((20 * s).dp))

                // Match history button
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(SettingsSurface, RoundedCornerShape((12 * s).dp))
                        .clickable {
                            onClose()
                            onShowHistory()
                        }
                        .padding((16 * s).dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Filled.History, "History",
                        tint = GoldColor, modifier = Modifier.size((24 * s).dp))
                    Spacer(Modifier.width((12 * s).dp))
                    Text("Match History", color = TextWhite, fontSize = (16 * s).sp)
                }
            }
            }
        }
    }
}

// -- Setting helpers --
@Composable
private fun SectionHeader(title: String, color: Color, s: Float = 1f) {
    Text(
        text = title.uppercase(),
        color = color,
        fontSize = (18 * s).sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = (2 * s).sp,
    )
}

@Composable
private fun SettingsLabel(label: String, s: Float = 1f) {
    Text(label, color = DimColor, fontSize = (13 * s).sp, fontWeight = FontWeight.Medium)
    Spacer(Modifier.height((6 * s).dp))
}

@Composable
private fun NameField(value: String, s: Float = 1f, onValueChange: (String) -> Unit) {
    BasicTextField(
        value = value,
        onValueChange = { if (it.length <= 16) onValueChange(it) },
        singleLine = true,
        textStyle = TextStyle(
            color = TextWhite,
            fontSize = (18 * s).sp,
            fontWeight = FontWeight.Bold,
        ),
        cursorBrush = SolidColor(TextWhite),
        modifier = Modifier
            .fillMaxWidth()
            .background(SettingsSurface, RoundedCornerShape((12 * s).dp))
            .padding((16 * s).dp),
    )
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ColorPicker(selectedIndex: Int, s: Float = 1f, onSelect: (Int) -> Unit) {
    FlowRow(
        horizontalArrangement = Arrangement.spacedBy((10 * s).dp),
        verticalArrangement = Arrangement.spacedBy((10 * s).dp),
    ) {
        teamColorPresets.forEachIndexed { index, preset ->
            val isSelected = index == selectedIndex
            Box(
                modifier = Modifier
                    .size((40 * s).dp)
                    .clip(CircleShape)
                    .background(Color(preset.bg))
                    .then(
                        if (isSelected) Modifier.border((3 * s).dp, TextWhite, CircleShape)
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

    BoxWithConstraints(
        modifier = modifier
            .fillMaxHeight()
            .background(backgroundColor)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
            ) { onClick() },
    ) {
        // Responsive sizing — reference design: 666dp × 800dp (tablet landscape half-panel)
        val scoreFontSize = (maxHeight.value * 0.65f).sp
        val scoreTopPad = (maxHeight.value * 0.05f).dp
        val gamesBoxW = (maxWidth.value * 0.24f).dp
        val gamesBoxH = (maxHeight.value * 0.25f).dp
        val gamesCounterSize = (gamesBoxH.value * 1.0f).sp
        val gamesLabelSize = (maxHeight.value * 0.025f).sp
        val teamNameSize = (maxHeight.value * 0.07f).sp
        val teamNameTopPad = (maxHeight.value * 0.156f).dp
        val teamNameSidePad = (maxWidth.value * 0.13f).dp
        val servingIconSize = (maxHeight.value * 0.035f).dp
        val gamesBoxPad = (maxWidth.value * 0.024f).dp
        val gamesBoxCorner = (maxHeight.value * 0.025f).dp
        val gamesLabelPad = (maxHeight.value * 0.015f).dp
        val gamesLabelSpacing = (maxHeight.value * 0.00375f).sp
        val teamNameSpacing = (maxHeight.value * 0.01f).dp
        val teamNameLetterSpacing = (maxHeight.value * 0.00375f).sp

        // Current set games — top corner near center
        val currentGames = gamesList.getOrElse(currentSet) { 0 }
        Box(
            modifier = Modifier
                .align(if (gamesBoxAtStart) Alignment.TopStart else Alignment.TopEnd)
                .padding(top = gamesBoxPad, start = gamesBoxPad, end = gamesBoxPad)
                .width(gamesBoxW)
                .height(gamesBoxH)
                .background(Color.Black.copy(alpha = 0.3f), RoundedCornerShape(gamesBoxCorner)),
            contentAlignment = Alignment.TopCenter,
        ) {
            Text(
                "GAMES",
                color = backgroundColor,
                fontSize = gamesLabelSize,
                fontWeight = FontWeight.Bold,
                letterSpacing = gamesLabelSpacing,
                modifier = Modifier.padding(top = gamesLabelPad),
            )
            AnimatedContent(
                targetState = currentGames,
                transitionSpec = {
                    (slideInVertically { -it } + fadeIn()) togetherWith
                            (slideOutVertically { it } + fadeOut())
                },
                label = "currentGames",
                modifier = Modifier.align(Alignment.Center),
            ) { games ->
                Text(
                    text = games.toString(),
                    color = TextWhite,
                    fontSize = gamesCounterSize,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center,
                )
            }
        }

        // Big score number — centered, nudged down
        Box(
            modifier = Modifier.fillMaxSize().padding(top = scoreTopPad),
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
                    fontSize = scoreFontSize,
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
                .padding(top = teamNameTopPad, start = teamNameSidePad, end = teamNameSidePad),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(teamNameSpacing),
        ) {
            if (isServing) {
                Icon(Icons.Filled.SportsTennis, "Serving",
                    tint = GoldColor, modifier = Modifier.size(servingIconSize))
            }
            Text(
                text = teamLabel,
                color = accentColor,
                fontSize = teamNameSize,
                fontWeight = FontWeight.Bold,
                letterSpacing = teamNameLetterSpacing,
            )
        }

    }
}
