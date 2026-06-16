package com.example.moto_dash

import android.Manifest
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.telecom.TelecomManager
import android.view.KeyEvent
import androidx.core.app.ActivityCompat
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val ASSISTANT_CHANNEL = "assistant.launcher"
    private val CALL_CHANNEL = "phone.call"

    private lateinit var audio: AudioManager

    private var isSplitScreen: Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        // --- Assistant & Media Channel ---
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ASSISTANT_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchAssistant" -> {
                    try {
                        val intent = Intent(Intent.ACTION_VOICE_COMMAND)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERR", e.message, null)
                    }
                }

                "togglePlayPause" -> {
                    sendMediaKey(KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE); result.success(true)
                }

                "nextTrack" -> {
                    sendMediaKey(KeyEvent.KEYCODE_MEDIA_NEXT); result.success(true)
                }

                "previousTrack" -> {
                    sendMediaKey(KeyEvent.KEYCODE_MEDIA_PREVIOUS); result.success(true)
                }

                "pauseMedia" -> {
                    sendMediaKey(KeyEvent.KEYCODE_MEDIA_PAUSE); result.success(true)
                }

                "resumeMedia" -> {
                    sendMediaKey(KeyEvent.KEYCODE_MEDIA_PLAY); result.success(true)
                }

                "getSplitScreenState" -> result.success(isSplitScreen)

                "isBluetoothConnected" -> {
                    val isA2dp = audio.isBluetoothA2dpOn
                    val isSco = audio.isBluetoothScoOn
                    result.success(isA2dp || isSco)
                }

                else -> result.notImplemented()
            }
        }

        // --- Phone Call Channel ---
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALL_CHANNEL
        ).setMethodCallHandler { call, result ->
            val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager

            when (call.method) {
                "endCall" -> {
                    val telecom = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
                    if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ANSWER_PHONE_CALLS)
                        == PackageManager.PERMISSION_GRANTED
                    ) {
                        telecom.endCall()
                        result.success(true)
                    } else {
                        result.error("PERMISSION_DENIED", "ANSWER_PHONE_CALLS permission not granted", null)
                    }
                }

                "setMute" -> {
                    val muted = call.argument<Boolean>("muted") ?: false
                    audio.isMicrophoneMute = muted
                    // Also set the in-call stream mute
                    audio.adjustStreamVolume(
                        AudioManager.STREAM_VOICE_CALL,
                        if (muted) AudioManager.ADJUST_MUTE else AudioManager.ADJUST_UNMUTE,
                        0
                    )
                    result.success(true)
                }

                "isMuted" -> {
                    result.success(audio.isMicrophoneMute)
                }

                "startCallService" -> {
                    val intent = Intent(this, CallManagerService::class.java)
                    startForegroundService(intent)
                    result.success(true)
                }

                "stopCallService" -> {
                    stopService(Intent(this, CallManagerService::class.java))
                    result.success(true)
                }

                "bringToFront" -> {
                    val intent = Intent(this, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    }
                    startActivity(intent)
                    result.success(true)
                }

                "checkOverlayPermission" -> {
                    result.success(Settings.canDrawOverlays(this))
                }

                "requestOverlayPermission" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onMultiWindowModeChanged(isInMultiWindowMode: Boolean) {
        super.onMultiWindowModeChanged(isInMultiWindowMode)
        isSplitScreen = isInMultiWindowMode
    }

    override fun onStart() {
        super.onStart()
        isSplitScreen = isInMultiWindowMode
    }

    private fun sendMediaKey(keyCode: Int) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        audioManager.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, keyCode))
    }
}