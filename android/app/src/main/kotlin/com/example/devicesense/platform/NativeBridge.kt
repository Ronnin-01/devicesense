package com.example.devicesense.platform

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NativeBridge(
        private val handlers: List<MethodHandler>,
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
