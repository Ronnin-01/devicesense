package com.example.devicesense.platform

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.net.Inet4Address
import java.net.NetworkInterface

/**
 * Reads the currently connected Wi-Fi network's details.
 *
 * Permission required: ACCESS_FINE_LOCATION (for SSID/BSSID — Android redacts them to "<unknown
 * ssid>" / "02:00:00:00:00:00" without it).
 *
 * API fragmentation handled transparently:
 * - API <= 30: [WifiManager.getConnectionInfo] (deprecated but functional)
 * - API >= 31: [ConnectivityManager] + [NetworkCapabilities.getTransportInfo]
 *
 * Both paths produce the same output map so Dart never needs to know which code path ran.
 *
 * Privacy note: SSID and BSSID are returned as-is when the permission is granted. Without the
 * permission the OS redacts them — this handler passes the redacted values through unchanged rather
 * than pretending the fields don't exist, so the UI can show "Permission required" for those
 * specific fields while still showing RSSI/speed/frequency which the OS does NOT redact.
 */
class WifiInfoHandler(
        private val context: Context,
) : MethodHandler {

    override val method: String = "getWifiInfo"

    override fun handle(call: MethodCall, result: MethodChannel.Result) {
        val wifiManager =
                context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

        if (!wifiManager.isWifiEnabled) {
            result.success(
                    mapOf(
                            "connected" to false,
                            "wifiEnabled" to false,
                            "reason" to "WIFI_DISABLED",
                    )
            )
            return
        }

        val wifiInfo: WifiInfo? =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    // API 31+: getConnectionInfo() is deprecated. Use
                    // ConnectivityManager → NetworkCapabilities → WifiInfo.
                    getWifiInfoModern()
                } else {
                    // API <= 30: legacy path, still fully functional.
                    @Suppress("DEPRECATION") wifiManager.connectionInfo
                }

        if (wifiInfo == null || wifiInfo.networkId == -1) {
            // networkId == -1 means not connected to any network.
            result.success(
                    mapOf(
                            "connected" to false,
                            "wifiEnabled" to true,
                            "reason" to "NOT_CONNECTED",
                    )
            )
            return
        }

        val hasLocationPermission =
                ContextCompat.checkSelfPermission(
                        context,
                        Manifest.permission.ACCESS_FINE_LOCATION,
                ) == PackageManager.PERMISSION_GRANTED

        result.success(buildWifiInfoMap(wifiInfo, hasLocationPermission))
    }

    private fun getWifiInfoModern(): WifiInfo? {
        val connectivityManager =
                context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        val activeNetwork = connectivityManager.activeNetwork ?: return null

        val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork) ?: return null

        if (!capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) return null

        return capabilities.transportInfo as? WifiInfo
    }

    private fun buildWifiInfoMap(
            info: WifiInfo,
            hasLocationPermission: Boolean,
    ): Map<String, Any> {
        return buildMap {
            put("connected", true)
            put("wifiEnabled", true)
            put("hasLocationPermission", hasLocationPermission)

            // SSID — redacted to "<unknown ssid>" by OS without location.
            val rawSsid = info.ssid?.removePrefix("\"")?.removeSuffix("\"") ?: ""
            put("ssid", if (hasLocationPermission) rawSsid else "Permission required")

            // BSSID — redacted to "02:00:00:00:00:00" by OS without location.
            put(
                    "bssid",
                    if (hasLocationPermission) (info.bssid ?: "Unknown") else "Permission required",
            )

            // RSSI and signal strength — NOT redacted, always available.
            put("rssi", info.rssi)
            put("signalStrength", rssiLabel(info.rssi))
            put(
                    "signalLevel",
                    WifiManager.calculateSignalLevel(info.rssi, 5), // 0–4 bar scale
            )

            // Link speed in Mbps.
            put("linkSpeedMbps", info.linkSpeed)

            // Frequency in MHz — tells you which band you're on.
            put("frequencyMHz", info.frequency)
            put("band", frequencyBandLabel(info.frequency))

            // IP address — readable dotted-decimal from NetworkInterface,
            // which is more reliable than WifiInfo.ipAddress on modern OS.
            put("ipAddress", getLocalIpAddress() ?: "Unknown")

            // Network ID — internal OS identifier, useful for debugging.
            put("networkId", info.networkId)

            // Hidden network indicator (SSID not broadcast).
            put("hiddenSsid", info.hiddenSSID)

            // MAC address — redacted to "02:00:00:00:00:00" on API 23+
            // for privacy. Still returned for transparency.
            put("macAddress", info.macAddress ?: "Unavailable")
        }
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
     * Reads the device's local IPv4 address from [NetworkInterface]. More reliable than
     * [WifiInfo.ipAddress] which packs the address as a little-endian int and can return 0 on some
     * OEM skins.
     */
    private fun getLocalIpAddress(): String? {
        return try {
            NetworkInterface.getNetworkInterfaces()
                    ?.asSequence()
                    ?.flatMap { iface -> iface.inetAddresses.asSequence() }
                    ?.firstOrNull { address ->
                        !address.isLoopbackAddress && address is Inet4Address
                    }
                    ?.hostAddress
        } catch (e: Exception) {
            null
        }
    }
}
