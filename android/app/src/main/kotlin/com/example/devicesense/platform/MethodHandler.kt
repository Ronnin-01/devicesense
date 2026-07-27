package com.example.devicesense.platform

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

interface MethodHandler {
    /** The exact platform-channel method name this handler responds to. */
    val method: String

    fun handle(call: MethodCall, result: MethodChannel.Result)
}
