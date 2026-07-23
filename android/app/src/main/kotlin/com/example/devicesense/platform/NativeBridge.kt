package com.example.devicesense.platform

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Routes each platform-channel call to the [MethodHandler] that owns it.
 *
 * Open/Closed: adding a new hardware category (Battery, Bluetooth, Wi-Fi, NFC, Sensors) means
 * adding one entry to [handlers] — this class's routing logic never changes. Dependency Inversion:
 * depends on the [MethodHandler] abstraction, never on a specific handler's concrete type.
 */
class NativeBridge(
        private val handlers: List<MethodHandler>,
// private val handlers: List<MethodHandler> =
//         listOf(
//                 DeviceInfoHandler(),
//                 BatteryHandler(context),
//         ),
) {

    fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val handler = handlers.firstOrNull { it.method == call.method }

        if (handler == null) {
            result.notImplemented()
            return
        }

        try {
            handler.handle(call, result)
        } catch (error: Exception) {
            result.error(
                    "NATIVE_ERROR",
                    "Failed to handle '${call.method}': ${error.message}",
                    null,
            )
        }
    }
}
