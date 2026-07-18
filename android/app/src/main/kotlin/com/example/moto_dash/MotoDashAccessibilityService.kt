package com.example.moto_dash

import android.accessibilityservice.AccessibilityService
import android.util.Log
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent
import io.flutter.plugin.common.EventChannel

class MotoDashAccessibilityService : AccessibilityService() {

//    InputEventBus.eventSink?.success(payload)

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("MotoDash", "Accessibility service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        // Not used
    }

    override fun onInterrupt() {
        // Not used
    }

    override fun onKeyEvent(event: KeyEvent): Boolean {

        Log.d("MotoDash", "Key: ${event.keyCode}")

        val payload = hashMapOf<String, Any?>(
            "keyCode" to event.keyCode,
            "scanCode" to event.scanCode,
            "action" to event.action,
            "repeatCount" to event.repeatCount,
            "deviceId" to event.deviceId,
            "deviceName" to event.device?.name,
            "eventTime" to event.eventTime
        )

        InputEventBus.eventSink?.success(payload)
        return false
    }
}