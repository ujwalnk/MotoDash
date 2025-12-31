package com.example.moto_dash

import android.content.Context
import android.content.Intent
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "assistant.launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
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
                    try {
                        toggleActiveMediaSession()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun toggleActiveMediaSession() {
        val mediaSessionManager =
            getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager

        val sessions = mediaSessionManager.getActiveSessions(null)

        for (controller in sessions) {
            val state = controller.playbackState ?: continue

            when (state.state) {
                PlaybackState.STATE_PLAYING -> {
                    controller.transportControls.pause()
                    return
                }
                PlaybackState.STATE_PAUSED -> {
                    controller.transportControls.play()
                    return
                }
            }
        }
    }
}
