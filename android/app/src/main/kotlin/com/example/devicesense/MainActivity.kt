package com.example.devicesense

import com.example.devicesense.platform.BluetoothDiscoveryHandler
import com.example.devicesense.platform.NativeBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

        private lateinit var nativeBridge: NativeBridge
        private lateinit var bluetoothDiscoveryHandler: BluetoothDiscoveryHandler

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
                        .setMethodCallHandler { call, result ->
                                nativeBridge.onMethodCall(call, result)
                        }

                bluetoothDiscoveryHandler = BluetoothDiscoveryHandler(applicationContext)

                MethodChannel(
                                flutterEngine.dartExecutor.binaryMessenger,
                                DISCOVERY_CONTROL_CHANNEL,
                        )
                        .setMethodCallHandler { call, result ->
                                bluetoothDiscoveryHandler.handleControlCall(
                                        call,
                                        result,
                                )
                        }

                EventChannel(
                                flutterEngine.dartExecutor.binaryMessenger,
                                DISCOVERY_CHANNEL,
                        )
                        .setStreamHandler(bluetoothDiscoveryHandler)
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

        override fun onDestroy() {
                bluetoothDiscoveryHandler.dispose()
                super.onDestroy()
        }

        companion object {
                private const val CHANNEL = "device_sense/native"
                private const val DISCOVERY_CHANNEL = "device_sense/bluetooth_discovery"
                private const val DISCOVERY_CONTROL_CHANNEL =
                        "device_sense/bluetooth_discovery_control"
        }
}
