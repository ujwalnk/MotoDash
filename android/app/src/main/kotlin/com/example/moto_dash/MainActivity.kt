package com.example.moto_dash

import android.content.Context
import android.content.Intent
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
// import android.os.build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.AudioManager
import android.view.KeyEvent


class MainActivity : FlutterActivity() {

    private val CHANNEL = "assistant.launcher"
    private var isSplitScreen: Boolean = false;

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
    sendMediaKey(KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
    result.success(true)
}

"nextTrack" -> {
    sendMediaKey(KeyEvent.KEYCODE_MEDIA_NEXT)
    result.success(true)
}

"previousTrack" -> {
    sendMediaKey(KeyEvent.KEYCODE_MEDIA_PREVIOUS)
    result.success(true)
}


                "getSplitScreenState" -> {
                    result.success(isSplitScreen)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onMultiWindowModeChanged(isInMultiWindowMode: Boolean) {
        super.onMultiWindowModeChanged(isInMultiWindowMode)
        isSplitScreen = isInMultiWindowMode
    }

    private fun sendMediaKey(keyCode: Int) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        val down = KeyEvent(KeyEvent.ACTION_DOWN, keyCode)
        val up = KeyEvent(KeyEvent.ACTION_UP, keyCode)

        audioManager.dispatchMediaKeyEvent(down)
        audioManager.dispatchMediaKeyEvent(up)
    }

}
