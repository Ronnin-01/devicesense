package com.example.devicesense

import com.example.devicesense.platform.BluetoothDiscoveryHandler
import com.example.devicesense.platform.NativeBridge
import com.example.devicesense.platform.NfcReaderHandler
import com.example.devicesense.platform.SensorStreamHandler
import com.example.devicesense.platform.SensorsCapabilitiesHandler
import com.example.devicesense.platform.WifiScanHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

        private lateinit var nativeBridge: NativeBridge
        private lateinit var bluetoothDiscoveryHandler: BluetoothDiscoveryHandler
        private lateinit var wifiScanHandler: WifiScanHandler
        private lateinit var nfcReaderHandler: NfcReaderHandler
        private lateinit var sensorStreamHandler: SensorStreamHandler
        private lateinit var sensorsCapabilitiesHandler: SensorsCapabilitiesHandler

        override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
                super.configureFlutterEngine(flutterEngine)

                setupNativeBridge(flutterEngine)
                setupBluetoothDiscoveryChannels(flutterEngine)
                setupNfcChannels(flutterEngine)
                setupWifiScanChannels(flutterEngine)
                setupSensorChannels(flutterEngine)
        }

        private fun setupNativeBridge(flutterEngine: FlutterEngine) {
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
        }

        private fun setupBluetoothDiscoveryChannels(flutterEngine: FlutterEngine) {
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
        }

        private fun setupNfcChannels(flutterEngine: FlutterEngine) {
                nfcReaderHandler = NfcReaderHandler(this)

                MethodChannel(
                                flutterEngine.dartExecutor.binaryMessenger,
                                NFC_READER_CONTROL_CHANNEL,
                        )
                        .setMethodCallHandler { call, result ->
                                nfcReaderHandler.handleControlCall(call, result)
                        }

                EventChannel(
                                flutterEngine.dartExecutor.binaryMessenger,
                                NFC_READER_CHANNEL,
                        )
                        .setStreamHandler(nfcReaderHandler)
        }

        private fun setupWifiScanChannels(flutterEngine: FlutterEngine) {
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

        private fun setupSensorChannels(flutterEngine: FlutterEngine) {
                sensorsCapabilitiesHandler = SensorsCapabilitiesHandler(applicationContext)

                // SensorStreamHandler in your shared code takes only Activity.
                sensorStreamHandler = SensorStreamHandler(this, applicationContext)

                MethodChannel(
                                flutterEngine.dartExecutor.binaryMessenger,
                                SENSORS_CHANNEL,
                        )
                        .setMethodCallHandler { call, result ->
                                when (call.method) {
                                        "getSensorsCapabilities" ->
                                                sensorsCapabilitiesHandler.handle(call, result)
                                        "startSensor",
                                        "stopSensor",
                                        "startAllSensors",
                                        "stopAllSensors",
                                        "getActiveSensors", ->
                                                sensorStreamHandler.handleControlCall(call, result)
                                        else -> result.notImplemented()
                                }
                        }

                EventChannel(
                                flutterEngine.dartExecutor.binaryMessenger,
                                SENSORS_STREAM_CHANNEL,
                        )
                        .setStreamHandler(sensorStreamHandler)
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

                if (::nativeBridge.isInitialized) {
                        nativeBridge.onRequestPermissionsResult(
                                requestCode,
                                permissions,
                                grantResults,
                        )
                }
        }

        override fun onDestroy() {
                if (::bluetoothDiscoveryHandler.isInitialized) {
                        bluetoothDiscoveryHandler.dispose()
                }

                if (::wifiScanHandler.isInitialized) {
                        wifiScanHandler.dispose()
                }

                if (::sensorStreamHandler.isInitialized) {
                        sensorStreamHandler.dispose()
                }

                // Add this only if your NfcReaderHandler actually has a dispose() method.
                // if (::nfcReaderHandler.isInitialized) {
                //     nfcReaderHandler.dispose()
                // }

                super.onDestroy()
        }

        companion object {
                private const val CHANNEL = "device_sense/native"

                private const val DISCOVERY_CHANNEL = "device_sense/bluetooth_discovery"
                private const val DISCOVERY_CONTROL_CHANNEL =
                        "device_sense/bluetooth_discovery_control"

                private const val WIFI_SCAN_CHANNEL = "device_sense/wifi_scan"
                private const val WIFI_SCAN_CONTROL_CHANNEL = "device_sense/wifi_scan_control"

                private const val NFC_READER_CHANNEL = "device_sense/nfc_reader"
                private const val NFC_READER_CONTROL_CHANNEL = "device_sense/nfc_reader_control"

                private const val SENSORS_STREAM_CHANNEL = "device_sense/sensor_stream"
                private const val SENSORS_CHANNEL = "device_sense/sensor"
        }
}
