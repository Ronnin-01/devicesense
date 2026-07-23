package com.example.devicesense.platform

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NativeBridge {

    private val deviceInfoHandler = DeviceInfoHandler()

    fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

        when (call.method) {
            "getPlatformMessage" -> {

                result.success("Hello from Android Native Kotlin 🚀")
            }
            "getDeviceInfo" -> {

                result.success(deviceInfoHandler.getDeviceInfo())
            }
            else -> {

                result.notImplemented()
            }
        }
    }
}
