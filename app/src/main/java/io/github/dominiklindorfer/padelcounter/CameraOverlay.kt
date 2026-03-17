package io.github.dominiklindorfer.padelcounter

import android.annotation.SuppressLint
import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.provider.MediaStore
import android.widget.Toast
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.MediaStoreOutputOptions
import androidx.camera.video.Quality
import androidx.camera.video.QualitySelector
import androidx.camera.video.Recorder
import androidx.camera.video.Recording
import androidx.camera.video.VideoCapture
import androidx.camera.video.VideoRecordEvent
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cameraswitch
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import kotlinx.coroutines.delay
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

private val RecordRed = Color(0xFFFF3B30)

private suspend fun Context.getCameraProvider(): ProcessCameraProvider {
    return suspendCancellableCoroutine { cont ->
        val future = ProcessCameraProvider.getInstance(this)
        future.addListener(
            { cont.resume(future.get()) },
            ContextCompat.getMainExecutor(this),
        )
    }
}

@SuppressLint("MissingPermission")
@Composable
fun CameraPreviewOverlay(onClose: () -> Unit) {
    val context = LocalContext.current
    @Suppress("DEPRECATION")
    val lifecycleOwner = androidx.compose.ui.platform.LocalLifecycleOwner.current

    val preview = remember { Preview.Builder().build() }
    val recorder = remember {
        Recorder.Builder()
            .setQualitySelector(QualitySelector.from(Quality.HD))
            .build()
    }
    val videoCapture = remember { VideoCapture.withOutput(recorder) }

    var cameraProvider by remember { mutableStateOf<ProcessCameraProvider?>(null) }
    var activeRecording by remember { mutableStateOf<Recording?>(null) }
    var isRecording by remember { mutableStateOf(false) }
    var recordingStartTime by remember { mutableLongStateOf(0L) }
    var recordingDurationMs by remember { mutableLongStateOf(0L) }
    var blinkVisible by remember { mutableStateOf(true) }
    var useFrontCamera by remember { mutableStateOf(false) }

    // Bind camera (re-runs when camera is switched)
    LaunchedEffect(useFrontCamera) {
        try {
            val provider = context.getCameraProvider()
            cameraProvider = provider
            provider.unbindAll()
            val selector = if (useFrontCamera) {
                CameraSelector.DEFAULT_FRONT_CAMERA
            } else {
                CameraSelector.DEFAULT_BACK_CAMERA
            }
            provider.bindToLifecycle(
                lifecycleOwner,
                selector,
                preview,
                videoCapture,
            )
        } catch (e: Exception) {
            Toast.makeText(context, "Camera not available", Toast.LENGTH_SHORT).show()
        }
    }

    // Cleanup
    DisposableEffect(Unit) {
        onDispose {
            activeRecording?.stop()
            cameraProvider?.unbindAll()
        }
    }

    // Recording timer
    LaunchedEffect(isRecording) {
        if (isRecording) {
            recordingStartTime = System.currentTimeMillis()
            while (isRecording) {
                recordingDurationMs = System.currentTimeMillis() - recordingStartTime
                delay(1000)
            }
        } else {
            recordingDurationMs = 0L
        }
    }

    // Blink effect for recording indicator
    LaunchedEffect(isRecording) {
        while (isRecording) {
            blinkVisible = !blinkVisible
            delay(500)
        }
        blinkVisible = true
    }

    Box(
        modifier = Modifier
            .width(192.dp)
            .height(108.dp)
            .clip(RoundedCornerShape(16.dp))
            .border(
                2.dp,
                if (isRecording) RecordRed else Color(0xFF333333),
                RoundedCornerShape(16.dp),
            ),
    ) {
        // Camera preview
        AndroidView(
            factory = { ctx ->
                PreviewView(ctx).apply {
                    implementationMode = PreviewView.ImplementationMode.COMPATIBLE
                    preview.surfaceProvider = surfaceProvider
                }
            },
            modifier = Modifier.fillMaxSize(),
        )

        // Recording indicator — top left
        if (isRecording) {
            Row(
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .padding(6.dp)
                    .background(Color.Black.copy(alpha = 0.6f), RoundedCornerShape(6.dp))
                    .padding(horizontal = 6.dp, vertical = 2.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Box(
                    modifier = Modifier
                        .size(8.dp)
                        .background(
                            if (blinkVisible) RecordRed else Color.Transparent,
                            CircleShape,
                        ),
                )
                val totalSec = recordingDurationMs / 1000
                Text(
                    text = "%d:%02d".format(totalSec / 60, totalSec % 60),
                    color = Color.White,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                )
            }
        }

        // Bottom controls
        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .background(Color.Black.copy(alpha = 0.5f))
                .padding(horizontal = 8.dp, vertical = 4.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // Switch camera
            IconButton(
                onClick = { useFrontCamera = !useFrontCamera },
                enabled = !isRecording,
                modifier = Modifier.size(32.dp),
            ) {
                Icon(
                    Icons.Filled.Cameraswitch,
                    "Switch camera",
                    tint = if (isRecording) Color.Gray else Color.White,
                    modifier = Modifier.size(16.dp),
                )
            }

            // Record / Stop
            IconButton(
                onClick = {
                    if (isRecording) {
                        activeRecording?.stop()
                        activeRecording = null
                        isRecording = false
                    } else {
                        val contentValues = ContentValues().apply {
                            put(
                                MediaStore.MediaColumns.DISPLAY_NAME,
                                "Padel_${System.currentTimeMillis()}",
                            )
                            put(MediaStore.MediaColumns.MIME_TYPE, "video/mp4")
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                put(
                                    MediaStore.Video.Media.RELATIVE_PATH,
                                    "Movies/PadelCounter",
                                )
                            }
                        }
                        val output = MediaStoreOutputOptions.Builder(
                            context.contentResolver,
                            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                        ).setContentValues(contentValues).build()

                        activeRecording = videoCapture.output
                            .prepareRecording(context, output)
                            .withAudioEnabled()
                            .start(ContextCompat.getMainExecutor(context)) { event ->
                                if (event is VideoRecordEvent.Finalize) {
                                    if (event.hasError()) {
                                        Toast.makeText(
                                            context,
                                            "Recording failed",
                                            Toast.LENGTH_SHORT,
                                        ).show()
                                    } else {
                                        Toast.makeText(
                                            context,
                                            "Video saved to gallery",
                                            Toast.LENGTH_SHORT,
                                        ).show()
                                    }
                                }
                            }
                        isRecording = true
                    }
                },
                modifier = Modifier.size(32.dp),
            ) {
                if (isRecording) {
                    Box(
                        modifier = Modifier
                            .size(16.dp)
                            .background(Color.White, RoundedCornerShape(3.dp)),
                    )
                } else {
                    Box(
                        modifier = Modifier
                            .size(16.dp)
                            .background(RecordRed, CircleShape),
                    )
                }
            }

            // Close
            IconButton(
                onClick = {
                    if (isRecording) {
                        activeRecording?.stop()
                        activeRecording = null
                        isRecording = false
                    }
                    onClose()
                },
                modifier = Modifier.size(32.dp),
            ) {
                Icon(
                    Icons.Filled.Close,
                    "Close",
                    tint = Color.White,
                    modifier = Modifier.size(16.dp),
                )
            }
        }
    }
}
