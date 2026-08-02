package com.example.devicesense.platform

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Reads static Wi-Fi adapter capabilities from [WifiManager].
 *
 * No runtime permission required — all fields here are available
 * without any manifest or runtime permission declaration.
 *
 * Single Responsibility: this handler only reads adapter hardware
 * capabilities. It never reads connected-network details (that's
 * [WifiInfoHandler]) and never scans (that's [WifiScanHandler]).
 */
class WifiCapabilitiesHandler(
    private val context: Context,
) : MethodHandler {

    override val method: String = "getWifiCapabilities"

    override fun handle(call: MethodCall, result: MethodChannel.Result) {
        result.success(collectCapabilities())
    }

    private fun collectCapabilities(): Map<String, Any> {
        val wifiManager =
            context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

        return buildMap {
            put("wifiSupported", true) // If WifiManager is non-null, WiFi is supported.
            put("wifiEnabled", wifiManager.isWifiEnabled)

            // Scan throttling: since API 28, apps are limited to 4 scans
            // per 2 minutes in the foreground. This flag tells you whether
            // scanning is allowed even when WiFi is disabled (the OS can
            // keep scanning for location even without active WiFi).
            @Suppress("DEPRECATION")
            val scanAlwaysAvailable = wifiManager.isScanAlwaysAvailable
            put("scanAlwaysAvailable", scanAlwaysAvailable)

            // 5 GHz band — supported on most modern phones.
            put("is5GHzSupported", wifiManager.is5GHzBandSupported)

            // 6 GHz (Wi-Fi 6E) band — API 30+. Flagship devices only.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                put("is6GHzSupported", wifiManager.is6GHzBandSupported)
            } else {
                put("is6GHzSupported", false)
            }

            // Wi-Fi Direct / P2P — device can connect directly to
            // another device without an access point.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                put("isWifiDirectSupported", wifiManager.isP2pSupported)
            } else {
                put("isWifiDirectSupported", false)
            }

            // WPA3 — API 29+. Increasingly common on Android 10+ devices.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put("isWpa3SaeSupported", wifiManager.isWpa3SaeSupported)
                put("isWpa3SuiteBSupported", wifiManager.isWpa3SuiteBSupported)
                put("isEnhancedOpenSupported", wifiManager.isEnhancedOpenSupported)
            } else {
                put("isWpa3SaeSupported", false)
                put("isWpa3SuiteBSupported", false)
                put("isEnhancedOpenSupported", false)
            }

            // Current adapter state as a readable label.
            put("wifiState", wifiStateLabel(wifiManager.wifiState))
        }
    }

    private fun wifiStateLabel(state: Int): String = when (state) {
        WifiManager.WIFI_STATE_ENABLED -> "ENABLED"
        WifiManager.WIFI_STATE_ENABLING -> "ENABLING"
        WifiManager.WIFI_STATE_DISABLED -> "DISABLED"
        WifiManager.WIFI_STATE_DISABLING -> "DISABLING"
        WifiManager.WIFI_STATE_UNKNOWN -> "UNKNOWN"
        else -> "UNKNOWN"
    }
}