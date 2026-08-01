package com.example.devicesense.platform

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Streams Bluetooth discovery events to Dart via [EventChannel].
 *
 * Runs two scanners in parallel:
 * - Classic discovery via [BroadcastReceiver] — finds Classic + Dual devices
 * - BLE scan via [ScanCallback] — finds BLE-only devices invisible to classic discovery (most
 * modern earbuds, fitness trackers, smartwatches)
 *
 * Events emitted (all as Map<String, Any>):
 * - "scanStarted" — classic discovery began
 * - "deviceUpdate" — classic device found, source = "classic"
 * - "bleDeviceUpdate" — BLE device found, source = "ble"
 * - "adapterState" — Bluetooth turned on/off mid-scan
 * - "scanProgress" — elapsed/total seconds during the 12s classic window
 * - "scanFinished" — classic discovery ended, includes total device count
 * - "scanError" — permission denied or adapter unavailable
 *
 * Dart-side impact summary (see inline DART_IMPACT comments):
 * - Handle "bleDeviceUpdate" alongside "deviceUpdate"
 * - Handle "scanError" with code + message fields
 * - "deviceUpdate" and "bleDeviceUpdate" now include "source", "signalStrength", and "shortAddress"
 * fields
 * - "scanFinished" now includes "deviceCount"
 * - "scanProgress" is new — optional to handle, safe to ignore
 */
class BluetoothDiscoveryHandler(
        context: Context,
) : EventChannel.StreamHandler {

        // Always use applicationContext — prevents Activity context leaks
        // if the Activity is destroyed while a scan is running.
        // DART_IMPACT: none — this is purely internal.
        private val context: Context = context.applicationContext

        private val bluetoothManager = this.context.getSystemService(BluetoothManager::class.java)
        private val adapter: BluetoothAdapter? = bluetoothManager?.adapter

        private var events: EventChannel.EventSink? = null
        private var receiverRegistered = false

        private var scanningRequested = false
        private var classicScanning = false
        private var bleScanning = false

        // ---- Deduplication --------------------------------------------------
        // Classic discovery fires ACTION_FOUND multiple times per device per
        // scan cycle. We deduplicate by address and only forward the first
        // sighting (lowest RSSI reading later in the cycle is less reliable
        // anyway). BLE ScanCallback delivers continuous updates — we forward
        // every RSSI update since BLE devices advertise continuously.
        // DART_IMPACT: no more duplicate "deviceUpdate" events per scan cycle.
        private val seenClassicAddresses = mutableSetOf<String>()

        // ---- Scan progress tracking -----------------------------------------
        private val mainHandler = Handler(Looper.getMainLooper())
        private var scanStartTimeMs = 0L
        private val classicDiscoveryDurationSeconds = 12
        private val progressRunnable =
                object : Runnable {
                        override fun run() {
                                if (scanStartTimeMs == 0L) return
                                val elapsed =
                                        ((System.currentTimeMillis() - scanStartTimeMs) / 1000)
                                                .toInt()
                                val capped = elapsed.coerceAtMost(classicDiscoveryDurationSeconds)
                                // DART_IMPACT: new "scanProgress" event — safe to ignore on Dart
                                // side.
                                events?.success(
                                        mapOf(
                                                "event" to "scanProgress",
                                                "elapsedSeconds" to capped,
                                                "totalSeconds" to classicDiscoveryDurationSeconds,
                                        )
                                )
                                if (capped < classicDiscoveryDurationSeconds) {
                                        mainHandler.postDelayed(this, 1_000)
                                }
                        }
                }

        // ---- Classic BroadcastReceiver --------------------------------------

        private val classicReceiver =
                object : BroadcastReceiver() {
                        override fun onReceive(context: Context, intent: Intent) {
                                when (intent.action) {
                                        BluetoothAdapter.ACTION_DISCOVERY_STARTED -> {
                                                classicScanning = true

                                                Log.d(TAG, "Classic discovery started")

                                                seenClassicAddresses.clear()
                                                scanStartTimeMs = System.currentTimeMillis()

                                                mainHandler.removeCallbacks(progressRunnable)
                                                mainHandler.post(progressRunnable)

                                                events?.success(
                                                        mapOf(
                                                                "event" to "scanStarted",
                                                                "source" to "classic",
                                                        )
                                                )
                                        }
                                        BluetoothDevice.ACTION_FOUND -> {
                                                if (!scanningRequested || events == null) return
                                                val device: BluetoothDevice? =
                                                        if (Build.VERSION.SDK_INT >=
                                                                        Build.VERSION_CODES.TIRAMISU
                                                        ) {
                                                                intent.getParcelableExtra(
                                                                        BluetoothDevice
                                                                                .EXTRA_DEVICE,
                                                                        BluetoothDevice::class.java,
                                                                )
                                                        } else {
                                                                @Suppress("DEPRECATION")
                                                                intent.getParcelableExtra(
                                                                        BluetoothDevice.EXTRA_DEVICE
                                                                )
                                                        }

                                                val rssi =
                                                        intent.getShortExtra(
                                                                        BluetoothDevice.EXTRA_RSSI,
                                                                        Short.MIN_VALUE,
                                                                )
                                                                .toInt()

                                                if (device == null) return

                                                // Deduplicate — skip if already seen this address
                                                // this scan cycle.
                                                if (!seenClassicAddresses.add(device.address))
                                                        return

                                                Log.d(
                                                        TAG,
                                                        "Classic device: ${device.name} (${device.address}) RSSI=$rssi"
                                                )

                                                // DART_IMPACT: "deviceUpdate" now includes
                                                // "source",
                                                // "signalStrength", and "shortAddress" fields.
                                                events?.success(
                                                        mapOf(
                                                                "event" to "deviceUpdate",
                                                                "device" to
                                                                        buildDeviceMap(
                                                                                name = device.name,
                                                                                address =
                                                                                        device.address,
                                                                                rssi = rssi,
                                                                                type =
                                                                                        deviceTypeLabel(
                                                                                                device.type
                                                                                        ),
                                                                                bondState =
                                                                                        bondStateLabel(
                                                                                                device.bondState
                                                                                        ),
                                                                                deviceClass =
                                                                                        deviceClassLabel(
                                                                                                device.bluetoothClass
                                                                                        ),
                                                                                category =
                                                                                        deviceCategory(
                                                                                                device.bluetoothClass
                                                                                        ),
                                                                                source = "classic",
                                                                        ),
                                                        )
                                                )
                                        }
                                        BluetoothDevice.ACTION_BOND_STATE_CHANGED -> {
                                                val state =
                                                        intent.getIntExtra(
                                                                BluetoothDevice.EXTRA_BOND_STATE,
                                                                BluetoothDevice.BOND_NONE,
                                                        )
                                                val device: BluetoothDevice? =
                                                        if (Build.VERSION.SDK_INT >=
                                                                        Build.VERSION_CODES.TIRAMISU
                                                        ) {
                                                                intent.getParcelableExtra(
                                                                        BluetoothDevice
                                                                                .EXTRA_DEVICE,
                                                                        BluetoothDevice::class.java,
                                                                )
                                                        } else {
                                                                @Suppress("DEPRECATION")
                                                                intent.getParcelableExtra(
                                                                        BluetoothDevice.EXTRA_DEVICE
                                                                )
                                                        }

                                                // DART_IMPACT: new "bondStateChanged" event — safe
                                                // to
                                                // ignore, but useful if you add a "pair this
                                                // device"
                                                // button later.
                                                events?.success(
                                                        mapOf(
                                                                "event" to "bondStateChanged",
                                                                "address" to
                                                                        (device?.address ?: ""),
                                                                "bondState" to
                                                                        bondStateLabel(state),
                                                                "timestamp" to
                                                                        System.currentTimeMillis(),
                                                        )
                                                )
                                        }
                                        BluetoothAdapter.ACTION_STATE_CHANGED -> {
                                                val state =
                                                        intent.getIntExtra(
                                                                BluetoothAdapter.EXTRA_STATE,
                                                                BluetoothAdapter.ERROR,
                                                        )

                                                val label = adapterStateLabel(state)

                                                Log.d(TAG, "Adapter state: $label")

                                                if (state == BluetoothAdapter.STATE_OFF ||
                                                                state ==
                                                                        BluetoothAdapter
                                                                                .STATE_TURNING_OFF
                                                ) {
                                                        stopScanning(
                                                                emitEvent = false,
                                                                reason = "bluetooth_off",
                                                        )
                                                }

                                                events?.success(
                                                        mapOf(
                                                                "event" to "adapterState",
                                                                "state" to label,
                                                                "timestamp" to
                                                                        System.currentTimeMillis(),
                                                                "initial" to false,
                                                        )
                                                )
                                                // Restart scanning if Bluetooth was turned back on
                                                // and the user requested a scan.
                                                if (state == BluetoothAdapter.STATE_ON &&
                                                                scanningRequested
                                                ) {
                                                        startNativeScanners()
                                                }
                                        }
                                        BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                                                classicScanning = false

                                                Log.d(TAG, "Classic discovery finished")

                                                mainHandler.removeCallbacks(progressRunnable)
                                                scanStartTimeMs = 0L

                                                // Ignore ACTION_DISCOVERY_FINISHED caused by a
                                                // manual stop.
                                                // stopScanning() already emits scanStopped.
                                                if (!scanningRequested) {
                                                        return
                                                }

                                                // Classic discovery defines the end of this scan
                                                // session.
                                                stopBleScanner()
                                                scanningRequested = false

                                                events?.success(
                                                        mapOf(
                                                                "event" to "scanFinished",
                                                                "source" to "combined",
                                                                "deviceCount" to
                                                                        seenClassicAddresses.size,
                                                                "timestamp" to
                                                                        System.currentTimeMillis(),
                                                        )
                                                )
                                        }
                                }
                        }
                }

        // ---- BLE ScanCallback -----------------------------------------------

        private val bleScanCallback =
                object : ScanCallback() {

                        override fun onScanResult(callbackType: Int, result: ScanResult) {
                                val device = result.device
                                val rssi = result.rssi

                                if (!scanningRequested || events == null) return

                                Log.d(
                                        TAG,
                                        "BLE device: ${device.name} (${device.address}) RSSI=$rssi"
                                )

                                // DART_IMPACT: new "bleDeviceUpdate" event — handle alongside
                                // "deviceUpdate". Same "device" map structure so the same Dart
                                // device model covers both.
                                events?.success(
                                        mapOf(
                                                "event" to "bleDeviceUpdate",
                                                "device" to
                                                        buildDeviceMap(
                                                                name = device.name,
                                                                address = device.address,
                                                                rssi = rssi,
                                                                type = "BLE",
                                                                bondState =
                                                                        bondStateLabel(
                                                                                device.bondState
                                                                        ),
                                                                deviceClass = "BLE Device",
                                                                category = "ble",
                                                                source = "ble",
                                                        ),
                                        )
                                )
                        }

                        override fun onScanFailed(errorCode: Int) {
                                bleScanning = false
                                val reason =
                                        when (errorCode) {
                                                SCAN_FAILED_ALREADY_STARTED -> "Already started"
                                                SCAN_FAILED_APPLICATION_REGISTRATION_FAILED ->
                                                        "App registration failed"
                                                SCAN_FAILED_FEATURE_UNSUPPORTED ->
                                                        "BLE not supported"
                                                SCAN_FAILED_INTERNAL_ERROR -> "Internal error"
                                                else -> "Unknown error ($errorCode)"
                                        }
                                Log.e(TAG, "BLE scan failed: $reason")

                                // DART_IMPACT: uses same "scanError" event as permission errors.
                                events?.success(
                                        mapOf(
                                                "event" to "scanError",
                                                "code" to "BLE_SCAN_FAILED",
                                                "message" to reason,
                                        )
                                )
                        }
                }

        // ---- EventChannel.StreamHandler -------------------------------------

        fun handleControlCall(
                call: MethodCall,
                result: MethodChannel.Result,
        ) {
                when (call.method) {
                        "startBluetoothDiscovery" -> {
                                startScanning(result)
                        }
                        "stopBluetoothDiscovery" -> {
                                stopScanning(
                                        emitEvent = true,
                                        reason = "user",
                                )
                                result.success(true)
                        }
                        "getBluetoothDiscoveryStatus" -> {
                                result.success(
                                        mapOf(
                                                "adapterState" to currentAdapterStateLabel(),
                                                "isScanning" to
                                                        (scanningRequested ||
                                                                classicScanning ||
                                                                bleScanning),
                                                "classicScanning" to classicScanning,
                                                "bleScanning" to bleScanning,
                                        )
                                )
                        }
                        else -> result.notImplemented()
                }
        }

        override fun onListen(
                arguments: Any?,
                eventSink: EventChannel.EventSink,
        ) {
                Log.d(TAG, "onListen() called")

                events = eventSink
                registerReceiver()

                // Immediately tell Dart the current state. Do not wait for the user
                // to toggle Bluetooth before providing ON/OFF information.
                emitCurrentAdapterState()

                if (!hasScanPermission()) {
                        events?.success(
                                mapOf(
                                        "event" to "scanError",
                                        "code" to "PERMISSION_DENIED",
                                        "message" to
                                                "BLUETOOTH_SCAN permission has not been granted.",
                                )
                        )
                        return
                }

                if (!hasConnectPermission()) {
                        events?.success(
                                mapOf(
                                        "event" to "scanError",
                                        "code" to "CONNECT_PERMISSION_DENIED",
                                        "message" to
                                                "BLUETOOTH_CONNECT permission has not been granted.",
                                )
                        )
                        return
                }

                if (adapter == null) {
                        events?.success(
                                mapOf(
                                        "event" to "scanError",
                                        "code" to "BLUETOOTH_UNSUPPORTED",
                                        "message" to "Bluetooth is not supported on this device.",
                                )
                        )
                        return
                }

                if (!adapter.isEnabled) {
                        events?.success(
                                mapOf(
                                        "event" to "scanError",
                                        "code" to "BLUETOOTH_DISABLED",
                                        "message" to "Bluetooth is not enabled.",
                                )
                        )
                        return
                }

                // Keep your existing auto-start behavior.
                startScanning(result = null)
        }

        override fun onCancel(arguments: Any?) {
                Log.d(TAG, "onCancel() called")

                stopScanning(
                        emitEvent = false,
                        reason = "stream_cancelled",
                )

                unregisterReceiver()
                events = null
        }

        fun dispose() {
                stopScanning(
                        emitEvent = false,
                        reason = "disposed",
                )

                unregisterReceiver()
                events = null
        }

        // ---- Classic discovery ----------------------------------------------

        private fun startScanning(
                result: MethodChannel.Result?,
        ) {
                if (!hasScanPermission()) {
                        val message = "BLUETOOTH_SCAN permission has not been granted."

                        events?.success(
                                mapOf(
                                        "event" to "scanError",
                                        "code" to "PERMISSION_DENIED",
                                        "message" to message,
                                )
                        )

                        result?.error(
                                "PERMISSION_DENIED",
                                message,
                                null,
                        )
                        return
                }

                if (!hasConnectPermission()) {
                        val message = "BLUETOOTH_CONNECT permission has not been granted."

                        events?.success(
                                mapOf(
                                        "event" to "scanError",
                                        "code" to "CONNECT_PERMISSION_DENIED",
                                        "message" to message,
                                )
                        )

                        result?.error(
                                "CONNECT_PERMISSION_DENIED",
                                message,
                                null,
                        )
                        return
                }

                if (adapter == null) {
                        result?.error(
                                "BLUETOOTH_UNSUPPORTED",
                                "Bluetooth is not supported on this device.",
                                null,
                        )
                        return
                }

                if (!adapter.isEnabled) {
                        result?.error(
                                "BLUETOOTH_DISABLED",
                                "Bluetooth is currently disabled.",
                                null,
                        )
                        return
                }

                if (scanningRequested || classicScanning || bleScanning) {
                        result?.success(false)
                        return
                }

                scanningRequested = true

                val started = startNativeScanners()

                if (!started) {
                        scanningRequested = false

                        events?.success(
                                mapOf(
                                        "event" to "scanError",
                                        "code" to "SCAN_START_FAILED",
                                        "message" to
                                                "Neither Classic nor BLE scanning could be started.",
                                )
                        )
                }

                result?.success(started)
        }

        private fun startNativeScanners(): Boolean {
                if (!scanningRequested) return false
                if (adapter?.isEnabled != true) return false

                startClassicDiscovery()
                startBleScanner()

                return classicScanning || bleScanning
        }

        private fun stopScanning(
                emitEvent: Boolean,
                reason: String,
        ) {
                val wasScanning = scanningRequested || classicScanning || bleScanning

                scanningRequested = false

                mainHandler.removeCallbacks(progressRunnable)
                scanStartTimeMs = 0L

                stopClassicDiscovery()
                stopBleScanner()

                seenClassicAddresses.clear()

                if (emitEvent && wasScanning) {
                        events?.success(
                                mapOf(
                                        "event" to "scanStopped",
                                        "reason" to reason,
                                        "timestamp" to System.currentTimeMillis(),
                                )
                        )
                }
        }

        private fun startClassicDiscovery() {
                if (!scanningRequested) return
                if (adapter?.isEnabled != true) return

                if (adapter.isDiscovering) {
                        adapter.cancelDiscovery()
                }

                val started = adapter.startDiscovery()
                classicScanning = started

                Log.d(TAG, "Classic discovery requested: $started")
        }

        private fun stopClassicDiscovery() {
                if (!hasScanPermission()) {
                        classicScanning = false
                        return
                }

                try {
                        if (adapter?.isDiscovering == true) {
                                adapter.cancelDiscovery()
                        }
                } catch (error: SecurityException) {
                        Log.w(TAG, "Unable to cancel classic discovery", error)
                } finally {
                        classicScanning = false
                }
        }

        // ---- BLE scanning ---------------------------------------------------

        private fun startBleScanner() {
                if (!scanningRequested) return
                if (adapter?.isEnabled != true) return
                if (bleScanning) return

                val scanner =
                        adapter.bluetoothLeScanner
                                ?: run {
                                        Log.w(TAG, "BluetoothLeScanner unavailable")
                                        return
                                }

                val settings =
                        ScanSettings.Builder()
                                .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                                .build()

                try {
                        scanner.startScan(
                                null,
                                settings,
                                bleScanCallback,
                        )

                        bleScanning = true
                        Log.d(TAG, "BLE scan started")
                } catch (error: SecurityException) {
                        bleScanning = false

                        events?.success(
                                mapOf(
                                        "event" to "scanError",
                                        "code" to "PERMISSION_DENIED",
                                        "message" to (error.message ?: "Unable to start BLE scan."),
                                )
                        )
                } catch (error: IllegalStateException) {
                        bleScanning = false

                        events?.success(
                                mapOf(
                                        "event" to "scanError",
                                        "code" to "BLE_UNAVAILABLE",
                                        "message" to
                                                (error.message ?: "BLE scanner is unavailable."),
                                )
                        )
                }
        }

        private fun stopBleScanner() {
                if (!bleScanning) return

                try {
                        if (adapter?.isEnabled == true && hasScanPermission()) {
                                adapter.bluetoothLeScanner?.stopScan(bleScanCallback)
                        }
                } catch (error: SecurityException) {
                        Log.w(TAG, "Unable to stop BLE scan", error)
                } catch (error: IllegalStateException) {
                        Log.w(TAG, "BLE scanner was already unavailable", error)
                } finally {
                        bleScanning = false
                        Log.d(TAG, "BLE scan stopped")
                }
        }

        // ---- BroadcastReceiver registration ---------------------------------

        private fun registerReceiver() {
                if (receiverRegistered) return

                val filter =
                        IntentFilter().apply {
                                addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED)
                                addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
                                addAction(BluetoothDevice.ACTION_FOUND)
                                addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
                                addAction(BluetoothAdapter.ACTION_STATE_CHANGED)
                        }

                context.registerReceiver(classicReceiver, filter)
                receiverRegistered = true
        }

        private fun unregisterReceiver() {
                if (!receiverRegistered) return
                context.unregisterReceiver(classicReceiver)
                receiverRegistered = false
        }

        // ---- Helpers --------------------------------------------------------

        private fun hasConnectPermission(): Boolean {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        return ContextCompat.checkSelfPermission(
                                context,
                                Manifest.permission.BLUETOOTH_CONNECT,
                        ) == PackageManager.PERMISSION_GRANTED
                }

                return true
        }

        private fun currentAdapterStateLabel(): String {
                if (adapter == null) return "UNSUPPORTED"

                if (!hasConnectPermission()) {
                        return "PERMISSION_REQUIRED"
                }

                return adapterStateLabel(adapter.state)
        }

        private fun adapterStateLabel(state: Int): String =
                when (state) {
                        BluetoothAdapter.STATE_OFF -> "OFF"
                        BluetoothAdapter.STATE_TURNING_OFF -> "TURNING_OFF"
                        BluetoothAdapter.STATE_ON -> "ON"
                        BluetoothAdapter.STATE_TURNING_ON -> "TURNING_ON"
                        else -> "UNKNOWN"
                }

        private fun emitCurrentAdapterState() {
                events?.success(
                        mapOf(
                                "event" to "adapterState",
                                "state" to currentAdapterStateLabel(),
                                "timestamp" to System.currentTimeMillis(),
                                "initial" to true,
                        )
                )
        }

        private fun hasScanPermission(): Boolean {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        return ContextCompat.checkSelfPermission(
                                context,
                                Manifest.permission.BLUETOOTH_SCAN,
                        ) == PackageManager.PERMISSION_GRANTED
                }
                // API <= 30: BLUETOOTH_ADMIN is required for startDiscovery().
                // It's an install-time permission — no runtime dialog — but it
                // must be declared in AndroidManifest.xml.
                // Add: <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"
                //           android:maxSdkVersion="30" />
                return true
        }

        /**
         * Builds the device map sent to Dart. Central to keep all events consistent — adding a
         * field here automatically appears in both "deviceUpdate" and "bleDeviceUpdate".
         *
         * DART_IMPACT: compared to your original code, these fields are new in every device map:
         * "source", "signalStrength", "shortAddress". Existing fields are unchanged.
         */
        private fun buildDeviceMap(
                name: String?,
                address: String,
                rssi: Int,
                type: String,
                bondState: String,
                deviceClass: String,
                category: String,
                source: String,
        ): Map<String, Any> {
                val shortAddress = address.takeLast(5)
                val displayName =
                        when {
                                !name.isNullOrBlank() -> name
                                else -> shortAddress
                        }

                return mapOf(
                        "name" to displayName,
                        "address" to address,
                        "shortAddress" to shortAddress,
                        "rssi" to rssi,
                        "signalStrength" to rssiLabel(rssi),
                        "type" to type,
                        "bondState" to bondState,
                        "class" to deviceClass,
                        "category" to category,
                        "source" to source,
                        "timestamp" to System.currentTimeMillis(),
                )
        }

        private fun rssiLabel(rssi: Int): String =
                when {
                        rssi == Short.MIN_VALUE.toInt() -> "Unknown"
                        rssi >= -60 -> "Excellent"
                        rssi >= -70 -> "Good"
                        rssi >= -80 -> "Fair"
                        else -> "Weak"
                }

        private fun bondStateLabel(state: Int): String =
                when (state) {
                        BluetoothDevice.BOND_BONDED -> "Bonded"
                        BluetoothDevice.BOND_BONDING -> "Bonding"
                        BluetoothDevice.BOND_NONE -> "Not Bonded"
                        else -> "Unknown"
                }

        private fun deviceTypeLabel(type: Int): String =
                when (type) {
                        BluetoothDevice.DEVICE_TYPE_CLASSIC -> "Classic"
                        BluetoothDevice.DEVICE_TYPE_LE -> "BLE"
                        BluetoothDevice.DEVICE_TYPE_DUAL -> "Dual"
                        else -> "Unknown"
                }

        private fun deviceClassLabel(btClass: BluetoothClass?): String {
                if (btClass == null) return "Unknown"
                return when (btClass.deviceClass) {
                        BluetoothClass.Device.AUDIO_VIDEO_HEADPHONES -> "Headphones"
                        BluetoothClass.Device.AUDIO_VIDEO_HANDSFREE -> "Handsfree"
                        BluetoothClass.Device.AUDIO_VIDEO_LOUDSPEAKER -> "Speaker"
                        BluetoothClass.Device.AUDIO_VIDEO_PORTABLE_AUDIO -> "Portable Audio"
                        BluetoothClass.Device.AUDIO_VIDEO_HIFI_AUDIO -> "HiFi Audio"
                        BluetoothClass.Device.AUDIO_VIDEO_MICROPHONE -> "Microphone"
                        BluetoothClass.Device.AUDIO_VIDEO_CAR_AUDIO -> "Car Audio"
                        BluetoothClass.Device.COMPUTER_LAPTOP -> "Laptop"
                        BluetoothClass.Device.COMPUTER_DESKTOP -> "Desktop"
                        BluetoothClass.Device.PHONE_SMART -> "Smartphone"
                        BluetoothClass.Device.PHONE_CELLULAR -> "Phone"
                        BluetoothClass.Device.WEARABLE_WRIST_WATCH -> "Smartwatch"
                        BluetoothClass.Device.WEARABLE_GLASSES -> "Smart Glasses"
                        BluetoothClass.Device.PERIPHERAL_KEYBOARD -> "Keyboard"
                        BluetoothClass.Device.PERIPHERAL_POINTING -> "Mouse / Pointer"
                        BluetoothClass.Device.PERIPHERAL_KEYBOARD_POINTING -> "Keyboard + Mouse"
                        else -> majorClassLabel(btClass)
                }
        }

        private fun deviceCategory(btClass: BluetoothClass?): String {
                if (btClass == null) return "other"
                return when (btClass.majorDeviceClass) {
                        BluetoothClass.Device.Major.AUDIO_VIDEO -> "audio"
                        BluetoothClass.Device.Major.COMPUTER -> "computer"
                        BluetoothClass.Device.Major.PHONE -> "phone"
                        BluetoothClass.Device.Major.WEARABLE -> "wearable"
                        BluetoothClass.Device.Major.PERIPHERAL -> "peripheral"
                        BluetoothClass.Device.Major.HEALTH -> "health"
                        BluetoothClass.Device.Major.IMAGING -> "imaging"
                        BluetoothClass.Device.Major.NETWORKING -> "networking"
                        BluetoothClass.Device.Major.TOY -> "toy"
                        else -> "other"
                }
        }

        private fun majorClassLabel(btClass: BluetoothClass): String =
                when (btClass.majorDeviceClass) {
                        BluetoothClass.Device.Major.AUDIO_VIDEO -> "Audio / Video"
                        BluetoothClass.Device.Major.COMPUTER -> "Computer"
                        BluetoothClass.Device.Major.PHONE -> "Phone"
                        BluetoothClass.Device.Major.WEARABLE -> "Wearable"
                        BluetoothClass.Device.Major.PERIPHERAL -> "Peripheral"
                        BluetoothClass.Device.Major.HEALTH -> "Health Device"
                        BluetoothClass.Device.Major.IMAGING -> "Imaging"
                        BluetoothClass.Device.Major.NETWORKING -> "Networking"
                        BluetoothClass.Device.Major.TOY -> "Toy"
                        else -> "Uncategorized"
                }

        companion object {
                private const val TAG = "BluetoothDiscovery"
        }
}
