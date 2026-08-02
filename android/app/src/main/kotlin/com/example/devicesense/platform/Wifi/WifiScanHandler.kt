package com.example.devicesense.platform

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.wifi.ScanResult
import android.net.wifi.WifiManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Streams Wi-Fi nearby-network scan results to Dart via [EventChannel].
 *
 * Mirrors [BluetoothDiscoveryHandler]'s architecture:
 * - [EventChannel.StreamHandler] for event streaming
 * - [handleControlCall] for start/stop/status via a separate MethodChannel
 *
 * Permission required: ACCESS_FINE_LOCATION (hard requirement on API 29+). Without it
 * getScanResults() returns an empty list silently. Additionally, Location Services must be ON in
 * system Settings — this is separate from the runtime permission and also silently returns empty
 * results if off. Both conditions are checked and reported.
 *
 * startScan() deprecation note: deprecated at API 28 but still functional. The OS may throttle or
 * ignore scan requests if the app exceeds 4 scans per 2 minutes. Throttled requests still trigger
 * SCAN_RESULTS_AVAILABLE_ACTION with EXTRA_RESULTS_UPDATED=false — we return cached results in that
 * case rather than reporting an error, which is the recommended pattern from Android documentation.
 *
 * Events emitted:
 * - "wifiState" — adapter state on connect and on change
 * - "scanStarted" — scan successfully initiated
 * - "scanResults" — list of nearby networks with full details
 * - "scanThrottled" — OS returned cached results (scan was throttled)
 * - "scanError" — permission denied, location off, or adapter off
 * - "scanStopped" — user or stream cancelled the scan
 */
class WifiScanHandler(
        context: Context,
) : EventChannel.StreamHandler {

    private val context: Context = context.applicationContext

    private val wifiManager: WifiManager =
            this.context.getSystemService(Context.WIFI_SERVICE) as WifiManager

    private var events: EventChannel.EventSink? = null
    private var receiverRegistered = false
    private var scanningRequested = false

    // ---- BroadcastReceiver -------------------------------------------

    private val wifiReceiver =
            object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    when (intent.action) {
                        WifiManager.WIFI_STATE_CHANGED_ACTION -> {
                            val state =
                                    intent.getIntExtra(
                                            WifiManager.EXTRA_WIFI_STATE,
                                            WifiManager.WIFI_STATE_UNKNOWN,
                                    )
                            val label = wifiStateLabel(state)
                            Log.d(TAG, "WiFi state changed: $label")

                            events?.success(
                                    mapOf(
                                            "event" to "wifiState",
                                            "state" to label,
                                            "timestamp" to System.currentTimeMillis(),
                                            "initial" to false,
                                    )
                            )

                            // If WiFi just turned off mid-scan, report the error.
                            if (state == WifiManager.WIFI_STATE_DISABLED ||
                                            state == WifiManager.WIFI_STATE_DISABLING
                            ) {
                                if (scanningRequested) {
                                    scanningRequested = false
                                    events?.success(
                                            mapOf(
                                                    "event" to "scanError",
                                                    "code" to "WIFI_DISABLED",
                                                    "message" to
                                                            "Wi-Fi was turned off during scan.",
                                            )
                                    )
                                }
                            }
                        }
                        WifiManager.SCAN_RESULTS_AVAILABLE_ACTION -> {
                            if (!scanningRequested) return

                            val resultsUpdated =
                                    intent.getBooleanExtra(
                                            WifiManager.EXTRA_RESULTS_UPDATED,
                                            false,
                                    )

                            if (!resultsUpdated) {
                                // OS returned cached results — scan was throttled.
                                // Still return the cached list; it's better than
                                // nothing, and the "scanThrottled" event lets Dart
                                // show a "cached results" badge to the user.
                                Log.w(TAG, "Scan throttled — returning cached results")
                                events?.success(
                                        mapOf(
                                                "event" to "scanThrottled",
                                                "message" to
                                                        "Scan throttled by OS. Showing cached results.",
                                                "timestamp" to System.currentTimeMillis(),
                                        )
                                )
                            }

                            val results = collectScanResults()
                            scanningRequested = false

                            Log.d(TAG, "Scan results: ${results.size} networks")

                            events?.success(
                                    mapOf(
                                            "event" to "scanResults",
                                            "networks" to results,
                                            "count" to results.size,
                                            "fromCache" to !resultsUpdated,
                                            "timestamp" to System.currentTimeMillis(),
                                    )
                            )
                        }
                    }
                }
            }

    // ---- EventChannel.StreamHandler ---------------------------------

    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink) {
        Log.d(TAG, "onListen() called")
        events = eventSink
        registerReceiver()

        // Immediately emit current WiFi adapter state so Dart knows the
        // initial state without waiting for a toggle event.
        emitCurrentWifiState()

        // Validate prerequisites before starting.
        if (!hasLocationPermission()) {
            events?.success(
                    mapOf(
                            "event" to "scanError",
                            "code" to "PERMISSION_DENIED",
                            "message" to
                                    "ACCESS_FINE_LOCATION permission has not been granted. " +
                                            "Wi-Fi scanning requires this permission on Android 10+.",
                    )
            )
            return
        }

        if (!isLocationServiceEnabled()) {
            // This is a separate condition from the permission — Location
            // Services can be off even when the permission is granted.
            events?.success(
                    mapOf(
                            "event" to "scanError",
                            "code" to "LOCATION_SERVICES_DISABLED",
                            "message" to
                                    "Location Services are disabled in system Settings. " +
                                            "Enable Location in Settings → Location to scan for Wi-Fi networks.",
                    )
            )
            return
        }

        if (!wifiManager.isWifiEnabled) {
            events?.success(
                    mapOf(
                            "event" to "scanError",
                            "code" to "WIFI_DISABLED",
                            "message" to "Wi-Fi is not enabled.",
                    )
            )
            return
        }

        startScan(result = null)
    }

    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "onCancel() called")
        scanningRequested = false
        unregisterReceiver()
        events?.success(
                mapOf(
                        "event" to "scanStopped",
                        "reason" to "stream_cancelled",
                        "timestamp" to System.currentTimeMillis(),
                )
        )
        events = null
    }

    fun dispose() {
        scanningRequested = false
        unregisterReceiver()
        events = null
    }

    // ---- Control MethodChannel -------------------------------------

    fun handleControlCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startWifiScan" -> startScan(result)
            "stopWifiScan" -> {
                scanningRequested = false
                events?.success(
                        mapOf(
                                "event" to "scanStopped",
                                "reason" to "user",
                                "timestamp" to System.currentTimeMillis(),
                        )
                )
                result.success(true)
            }
            "getWifiScanStatus" -> {
                result.success(
                        mapOf(
                                "isScanning" to scanningRequested,
                                "wifiEnabled" to wifiManager.isWifiEnabled,
                                "hasPermission" to hasLocationPermission(),
                                "locationServicesEnabled" to isLocationServiceEnabled(),
                                "wifiState" to wifiStateLabel(wifiManager.wifiState),
                        )
                )
            }
            else -> result.notImplemented()
        }
    }

    // ---- Scan logic -------------------------------------------------

    private fun startScan(result: MethodChannel.Result?) {
        if (!hasLocationPermission()) {
            val message = "ACCESS_FINE_LOCATION permission has not been granted."
            events?.success(
                    mapOf(
                            "event" to "scanError",
                            "code" to "PERMISSION_DENIED",
                            "message" to message,
                    )
            )
            result?.error("PERMISSION_DENIED", message, null)
            return
        }

        if (!isLocationServiceEnabled()) {
            val message = "Location Services are disabled in system Settings."
            events?.success(
                    mapOf(
                            "event" to "scanError",
                            "code" to "LOCATION_SERVICES_DISABLED",
                            "message" to message,
                    )
            )
            result?.error("LOCATION_SERVICES_DISABLED", message, null)
            return
        }

        if (!wifiManager.isWifiEnabled) {
            val message = "Wi-Fi is not enabled."
            events?.success(
                    mapOf(
                            "event" to "scanError",
                            "code" to "WIFI_DISABLED",
                            "message" to message,
                    )
            )
            result?.error("WIFI_DISABLED", message, null)
            return
        }

        if (scanningRequested) {
            result?.success(false)
            return
        }

        scanningRequested = true

        val initiated = wifiManager.startScan()

        if (!initiated) {
            // startScan() returned false — OS rejected the request.
            // This usually means throttling. The receiver will still fire
            // SCAN_RESULTS_AVAILABLE_ACTION with EXTRA_RESULTS_UPDATED=false
            // so we get cached results — do not treat this as a hard error.
            Log.w(TAG, "startScan() returned false — OS may return cached results")
        }

        events?.success(
                mapOf(
                        "event" to "scanStarted",
                        "timestamp" to System.currentTimeMillis(),
                )
        )

        result?.success(true)
    }

    // ---- Scan result collection ------------------------------------

    private fun collectScanResults(): List<Map<String, Any>> {
        val scanResults: List<ScanResult> = wifiManager.scanResults ?: return emptyList()

        return scanResults.map { scan ->
            buildMap {
                // SSID — the human-readable network name.
                put("ssid", scan.SSID ?: "")

                // BSSID — the access point's MAC address.
                put("bssid", scan.BSSID ?: "")

                // RSSI — signal strength in dBm.
                put("rssi", scan.level)
                put("signalStrength", rssiLabel(scan.level))
                put(
                        "signalLevel",
                        WifiManager.calculateSignalLevel(scan.level, 5),
                )

                // Frequency and band.
                put("frequencyMHz", scan.frequency)
                put("band", frequencyBandLabel(scan.frequency))

                // Channel number derived from frequency.
                put("channel", frequencyToChannel(scan.frequency))

                // Security capabilities string — e.g. "[WPA2-PSK][ESS]".
                // Parse for common security types.
                put("capabilities", scan.capabilities ?: "")
                put("securityType", parseSecurityType(scan.capabilities))

                // Whether the SSID is hidden (network does not broadcast name).
                put("isHidden", scan.SSID.isNullOrEmpty())

                // Channel width — API 23+.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    put("channelWidthMHz", channelWidthLabel(scan.channelWidth))
                }

                // Operator-friendly name — API 30+. Used by carriers to
                // give a readable name to hotspots.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    put("operatorFriendlyName", scan.operatorFriendlyName?.toString() ?: "")
                }

                // Passpoint — enterprise Wi-Fi hotspot standard.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    put("isPasspoint", scan.isPasspointNetwork)
                }

                put("timestamp", System.currentTimeMillis())
            }
        }
    }

    // ---- Receiver registration -------------------------------------

    private fun registerReceiver() {
        if (receiverRegistered) return
        val filter =
                IntentFilter().apply {
                    addAction(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION)
                    addAction(WifiManager.WIFI_STATE_CHANGED_ACTION)
                }
        context.registerReceiver(wifiReceiver, filter)
        receiverRegistered = true
    }

    private fun unregisterReceiver() {
        if (!receiverRegistered) return
        context.unregisterReceiver(wifiReceiver)
        receiverRegistered = false
    }

    // ---- Permission + service checks --------------------------------

    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Location Services (the system toggle in Settings → Location) must be enabled for
     * getScanResults() to return anything on API 28+. This is separate from the runtime permission
     * — both are required.
     */
    private fun isLocationServiceEnabled(): Boolean {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            locationManager.isLocationEnabled
        } else {
            @Suppress("DEPRECATION")
            locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                    locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        }
    }

    // ---- Helpers ----------------------------------------------------

    private fun emitCurrentWifiState() {
        events?.success(
                mapOf(
                        "event" to "wifiState",
                        "state" to wifiStateLabel(wifiManager.wifiState),
                        "timestamp" to System.currentTimeMillis(),
                        "initial" to true,
                )
        )
    }

    private fun wifiStateLabel(state: Int): String =
            when (state) {
                WifiManager.WIFI_STATE_ENABLED -> "ENABLED"
                WifiManager.WIFI_STATE_ENABLING -> "ENABLING"
                WifiManager.WIFI_STATE_DISABLED -> "DISABLED"
                WifiManager.WIFI_STATE_DISABLING -> "DISABLING"
                WifiManager.WIFI_STATE_UNKNOWN -> "UNKNOWN"
                else -> "UNKNOWN"
            }

    private fun rssiLabel(rssi: Int): String =
            when {
                rssi >= -55 -> "Excellent"
                rssi >= -65 -> "Good"
                rssi >= -75 -> "Fair"
                rssi >= -85 -> "Weak"
                else -> "Very Weak"
            }

    private fun frequencyBandLabel(frequencyMHz: Int): String =
            when {
                frequencyMHz in 2400..2500 -> "2.4 GHz"
                frequencyMHz in 5100..5900 -> "5 GHz"
                frequencyMHz in 5925..7125 -> "6 GHz"
                else -> "Unknown"
            }

    /**
     * Converts a center frequency in MHz to a standard Wi-Fi channel number. Channel math: 2.4 GHz
     * channels are 5 MHz apart starting at 2412 MHz (channel 1). 5 GHz channels start at 5180 MHz
     * (channel 36) and are also 5 MHz apart. 6 GHz channels start at 5955 MHz (channel 1).
     */
    private fun frequencyToChannel(frequencyMHz: Int): Int {
        return when {
            frequencyMHz in 2412..2484 -> {
                if (frequencyMHz == 2484) 14 else (frequencyMHz - 2412) / 5 + 1
            }
            frequencyMHz in 5180..5825 -> (frequencyMHz - 5180) / 5 + 36
            frequencyMHz in 5955..7115 -> (frequencyMHz - 5955) / 5 + 1
            else -> -1
        }
    }

    private fun parseSecurityType(capabilities: String?): String {
        if (capabilities.isNullOrEmpty()) return "Unknown"
        return when {
            capabilities.contains("WPA3") || capabilities.contains("SAE") -> "WPA3"
            capabilities.contains("WPA2") || capabilities.contains("RSN") -> "WPA2"
            capabilities.contains("WPA") -> "WPA"
            capabilities.contains("WEP") -> "WEP"
            capabilities.contains("OWE") -> "Enhanced Open (OWE)"
            capabilities.contains("ESS") -> "Open"
            else -> "Unknown"
        }
    }

    private fun channelWidthLabel(width: Int): String =
            when (width) {
                ScanResult.CHANNEL_WIDTH_20MHZ -> "20 MHz"
                ScanResult.CHANNEL_WIDTH_40MHZ -> "40 MHz"
                ScanResult.CHANNEL_WIDTH_80MHZ -> "80 MHz"
                ScanResult.CHANNEL_WIDTH_160MHZ -> "160 MHz"
                ScanResult.CHANNEL_WIDTH_80MHZ_PLUS_MHZ -> "80+80 MHz"
                else -> "Unknown"
            }

    companion object {
        private const val TAG = "WifiScanHandler"
    }
}
