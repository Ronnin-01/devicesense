package com.example.devicesense

import com.example.devicesense.platform.NativeBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private lateinit var nativeBridge: NativeBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        nativeBridge =
                NativeBridge(
                        activity = this,
                        context = applicationContext,
                )

        MethodChannel(
                        flutterEngine.dartExecutor.binaryMessenger,
                        CHANNEL,
                )
                .setMethodCallHandler { call, result -> nativeBridge.onMethodCall(call, result) }
    }

    override fun onRequestPermissionsResult(
            requestCode: Int,
            permissions: Array<String>,
            grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(
                requestCode,
                permissions,
                grantResults,
        )

        nativeBridge.onRequestPermissionsResult(
                requestCode,
                permissions,
                grantResults,
        )
    }

    companion object {
        private const val CHANNEL = "device_sense/native"
    }
}
