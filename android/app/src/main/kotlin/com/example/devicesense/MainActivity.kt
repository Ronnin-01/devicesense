package com.example.devicesense

import com.example.devicesense.platform.BluetoothDiscoveryHandler
import com.example.devicesense.platform.NativeBridge
import com.example.devicesense.platform.WifiScanHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

        private lateinit var nativeBridge: NativeBridge
        private lateinit var bluetoothDiscoveryHandler: BluetoothDiscoveryHandler
        private lateinit var wifiScanHandler: WifiScanHandler

        override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
                super.configureFlutterEngine(flutterEngine)

                // ---- Method channel (all MethodHandlers via NativeBridge) --------
                // WifiCapabilitiesHandler and WifiInfoHandler are registered inside
                // NativeBridge because they are simple request/response handlers.
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

                // ---- Bluetooth discovery (EventChannel + control MethodChannel) --

                bluetoothDiscoveryHandler = BluetoothDiscoveryHandler(applicationContext)

                MethodChannel(
                                flutterEngine.dartExecutor.binaryMessenger,
                                DISCOVERY_CONTROL_CHANNEL,
                        )
                        .setMethodCallHandler { call, result ->
                                bluetoothDiscoveryHandler.handleControlCall(call, result)
                        }

                EventChannel(
                                flutterEngine.dartExecutor.binaryMessenger,
                                DISCOVERY_CHANNEL,
                        )
                        .setStreamHandler(bluetoothDiscoveryHandler)

                // ---- Wi-Fi scan (EventChannel + control MethodChannel) -----------
                // Mirrors the Bluetooth discovery pattern exactly so the Dart side
                // can follow the same repository/bloc pattern.

                wifiScanHandler = WifiScanHandler(applicationContext)

                MethodChannel(
                                flutterEngine.dartExecutor.binaryMessenger,
                                WIFI_SCAN_CONTROL_CHANNEL,
                        )
                        .setMethodCallHandler { call, result ->
                                wifiScanHandler.handleControlCall(call, result)
                        }

                EventChannel(
                                flutterEngine.dartExecutor.binaryMessenger,
                                WIFI_SCAN_CHANNEL,
                        )
                        .setStreamHandler(wifiScanHandler)
        }

        override fun onRequestPermissionsResult(
                requestCode: Int,
                permissions: Array<String>,
                grantResults: IntArray,
        ) {
                super.onRequestPermissionsResult(requestCode, permissions, grantResults)
                nativeBridge.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }

        override fun onDestroy() {
                bluetoothDiscoveryHandler.dispose()
                wifiScanHandler.dispose()
                super.onDestroy()
        }

        companion object {
                // Existing channels — unchanged.
                private const val CHANNEL = "device_sense/native"
                private const val DISCOVERY_CHANNEL = "device_sense/bluetooth_discovery"
                private const val DISCOVERY_CONTROL_CHANNEL =
                        "device_sense/bluetooth_discovery_control"

                // New Wi-Fi channels — same naming convention.
                private const val WIFI_SCAN_CHANNEL = "device_sense/wifi_scan"
                private const val WIFI_SCAN_CONTROL_CHANNEL = "device_sense/wifi_scan_control"
        }
}
