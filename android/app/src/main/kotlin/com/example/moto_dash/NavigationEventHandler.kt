package com.example.moto_dash

import io.flutter.plugin.common.EventChannel

object NavigationEventHandler : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun send(data: Any?) {
        eventSink?.success(data)
    }
}