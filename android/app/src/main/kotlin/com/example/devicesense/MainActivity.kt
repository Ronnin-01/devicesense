package com.example.devicesense

import com.example.devicesense.platform.BatteryHandler
import com.example.devicesense.platform.DeviceInfoHandler
import com.example.devicesense.platform.NativeBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val nativeBridge =
                NativeBridge(
                        handlers =
                                listOf(
                                        DeviceInfoHandler(),
                                        BatteryHandler(applicationContext),
                                ),
                )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            nativeBridge.onMethodCall(call, result)
        }
    }

    private companion object {
        const val CHANNEL = "device_sense/native"
    }
}
