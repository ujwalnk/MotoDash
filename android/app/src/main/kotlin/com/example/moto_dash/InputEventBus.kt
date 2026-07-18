package com.example.moto_dash

import io.flutter.plugin.common.EventChannel

object InputEventBus {
    var eventSink: EventChannel.EventSink? = null
}