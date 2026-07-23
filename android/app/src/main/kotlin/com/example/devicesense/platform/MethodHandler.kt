package com.example.devicesense.platform

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Contract for a feature-specific native handler (device info, battery, bluetooth, ...). Each
 * implementation owns exactly one platform-channel method and nothing else — Single Responsibility.
 *
 * Adding a new hardware category later means writing one new class that implements this interface
 * and registering it in [NativeBridge] — nothing here, and nothing in [NativeBridge], needs to
 * change.
 */
interface MethodHandler {
    /** The exact platform-channel method name this handler responds to. */
    val method: String

    fun handle(call: MethodCall, result: MethodChannel.Result)
}
