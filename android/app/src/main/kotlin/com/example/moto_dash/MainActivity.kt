package com.example.moto_dash

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioManager
import android.net.Uri
import android.provider.ContactsContract
import android.provider.Settings
import android.telecom.TelecomManager
import android.view.KeyEvent
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val ASSISTANT_CHANNEL = "in.madilu.motodash/assistant"
    private val CALL_CHANNEL = "in.madilu.motodash/telephony"
    private val PERMISSIONS_CHANNEL = "in.madilu.motodash/permissions"
    private val INPUT_CHANNEL = "in.madilu.motodash/input_events"

    private lateinit var audio: AudioManager
    private var isSplitScreen: Boolean = false
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        // --- Assistant & Media Channel ---
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, ASSISTANT_CHANNEL
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
            flutterEngine.dartExecutor.binaryMessenger, CALL_CHANNEL
        ).setMethodCallHandler { call, result ->
            audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager

            when (call.method) {
                "getContactName" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")

                    if (phoneNumber == null) {
                        result.error("INVALID_ARGUMENT", "phoneNumber is required", null)
                        return@setMethodCallHandler
                    }

                    result.success(getContactName(phoneNumber))
                }

                "answerCall" -> {
                    val telecom = getSystemService(Context.TELECOM_SERVICE) as TelecomManager

                    if (ActivityCompat.checkSelfPermission(
                            this, Manifest.permission.ANSWER_PHONE_CALLS
                        ) == PackageManager.PERMISSION_GRANTED
                    ) {
                        telecom.acceptRingingCall()
                        result.success(true)
                    } else {
                        result.error(
                            "PERMISSION_DENIED", "ANSWER_PHONE_CALLS permission not granted", null
                        )
                    }
                }

                "endCall" -> {
                    val telecom = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
                    if (ActivityCompat.checkSelfPermission(
                            this, Manifest.permission.ANSWER_PHONE_CALLS
                        ) == PackageManager.PERMISSION_GRANTED
                    ) {
                        telecom.endCall()
                        result.success(true)
                    } else {
                        result.error("PERMISSION_DENIED", "ANSWER_PHONE_CALLS permission not granted", null)
                    }
                }

                "silenceRinger" -> {
                    val telecom = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
                    telecom.silenceRinger()
                    result.success(true)
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
                    val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                    startActivity(intent)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }

        // --- Permissions Channel ---
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isCallLogGranted" -> result.success(
                    ActivityCompat.checkSelfPermission(
                        this, Manifest.permission.READ_CALL_LOG
                    ) == PackageManager.PERMISSION_GRANTED
                )

                "requestCallLogPermission" -> {
                    pendingPermissionResult = result
                    ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.READ_CALL_LOG), 1001)
                    // result is completed later in onRequestPermissionsResult
                }

                "isNotificationListenerEnabled" -> {
                    val enabled = Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: ""
                    result.success(enabled.contains("$packageName/"))
                }

                "openNotificationListenerSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }

                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                }

                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }

                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger, INPUT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                InputEventBus.eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                InputEventBus.eventSink = null
            }
        })
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

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 1001) {
            pendingPermissionResult?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
            pendingPermissionResult = null
        }
    }

    private fun getContactName(phoneNumber: String): String? {
        val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(phoneNumber))

        val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)

        contentResolver.query(
            uri, projection, null, null, null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME)

                if (nameIndex >= 0) {
                    return cursor.getString(nameIndex)
                }
            }
        }

        return null
    }

    private fun isAccessibilityServiceEnabled(): Boolean {

        val expected = "$packageName/${MotoDashAccessibilityService::class.java.name}"

        val enabled = Settings.Secure.getString(
            contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        return enabled.split(':').any { it.equals(expected, ignoreCase = true) }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {

        val device = event.device

        val payload = hashMapOf<String, Any?>(
            "keyCode" to event.keyCode,
            "scanCode" to event.scanCode,
            "action" to event.action,
            "repeatCount" to event.repeatCount,
            "deviceId" to event.deviceId,
            "deviceName" to device?.name,
            "eventTime" to event.eventTime
        )

//        eventSink?.success(payload)
        InputEventBus.eventSink?.success(payload)
//        return super.dispatchKeyEvent(event)

        return true
    }
}