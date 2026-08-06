package com.example.devicesense.platform

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.net.Inet4Address

class WifiInfoHandler(
        context: Context,
) : MethodHandler {

    private val context: Context = context.applicationContext

    private val wifiManager: WifiManager? =
            this.context.getSystemService(Context.WIFI_SERVICE) as? WifiManager

    private val connectivityManager: ConnectivityManager? =
            this.context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager

    override val method: String = "getWifiInfo"

    override fun handle(
            call: MethodCall,
            result: MethodChannel.Result,
    ) {
        try {
            val manager = wifiManager

            if (manager == null) {
                result.error(
                        "WIFI_UNSUPPORTED",
                        "Wi-Fi service is unavailable on this device.",
                        null,
                )
                return
            }

            if (!manager.isWifiEnabled) {
                result.success(
                        disconnectedMap(
                                wifiEnabled = false,
                                reason = "WIFI_DISABLED",
                        )
                )
                return
            }

            val connection = getCurrentWifiConnection()

            if (connection == null) {
                result.success(
                        disconnectedMap(
                                wifiEnabled = true,
                                reason = "NOT_CONNECTED",
                        )
                )
                return
            }

            val hasFineLocationPermission = hasPermission(Manifest.permission.ACCESS_FINE_LOCATION)

            val hasNearbyWifiPermission =
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        hasPermission(Manifest.permission.NEARBY_WIFI_DEVICES)
                    } else {
                        true
                    }

            result.success(
                    buildWifiInfoMap(
                            info = connection.wifiInfo,
                            network = connection.network,
                            linkProperties = connection.linkProperties,
                            hasFineLocationPermission = hasFineLocationPermission,
                            hasNearbyWifiPermission = hasNearbyWifiPermission,
                    )
            )
        } catch (error: SecurityException) {
            result.error(
                    "PERMISSION_DENIED",
                    error.message ?: "Required Wi-Fi permission was denied.",
                    null,
            )
        } catch (error: Exception) {
            result.error(
                    "WIFI_INFO_ERROR",
                    error.message ?: "Unable to read Wi-Fi information.",
                    null,
            )
        }
    }

    /**
     * Returns the currently active Wi-Fi connection.
     *
     * Do not use WifiInfo.networkId to decide whether the device is connected. Android can redact
     * networkId to -1 when location-sensitive information is unavailable.
     */
    private fun getCurrentWifiConnection(): WifiConnection? {
        val manager = connectivityManager ?: return null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return getModernWifiConnection(manager)
        }

        return getLegacyWifiConnection(manager)
    }

    /** Android 12/API 31 and newer. */
    private fun getModernWifiConnection(
            manager: ConnectivityManager,
    ): WifiConnection? {
        val activeNetwork = manager.activeNetwork ?: return null

        val capabilities = manager.getNetworkCapabilities(activeNetwork) ?: return null

        if (!capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
            return null
        }

        val wifiInfo = capabilities.transportInfo as? WifiInfo ?: return null

        return WifiConnection(
                network = activeNetwork,
                wifiInfo = wifiInfo,
                linkProperties = manager.getLinkProperties(activeNetwork),
        )
    }

    /** Android 11/API 30 and older. */
    @Suppress("DEPRECATION")
    private fun getLegacyWifiConnection(
            manager: ConnectivityManager,
    ): WifiConnection? {
        val activeNetwork = manager.activeNetwork ?: return null

        val capabilities = manager.getNetworkCapabilities(activeNetwork) ?: return null

        if (!capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
            return null
        }

        val info = wifiManager?.connectionInfo ?: return null

        return WifiConnection(
                network = activeNetwork,
                wifiInfo = info,
                linkProperties = manager.getLinkProperties(activeNetwork),
        )
    }

    private fun buildWifiInfoMap(
            info: WifiInfo,
            network: Network,
            linkProperties: LinkProperties?,
            hasFineLocationPermission: Boolean,
            hasNearbyWifiPermission: Boolean,
    ): Map<String, Any> {
        val rawSsid = normalizeSsid(info.ssid)
        val rawBssid = info.bssid.orEmpty()
        Log.d("WifiInfoHandler", "SSID: $rawSsid, BSSID: $rawBssid")

        val ssidAccessible =
                hasFineLocationPermission &&
                        rawSsid.isNotBlank() &&
                        rawSsid != WifiManager.UNKNOWN_SSID

        val bssidAccessible =
                hasFineLocationPermission &&
                        rawBssid.isNotBlank() &&
                        rawBssid != REDACTED_MAC_ADDRESS

        return mapOf(
                "connected" to true,
                "wifiEnabled" to true,
                "hasLocationPermission" to hasFineLocationPermission,
                "hasNearbyWifiPermission" to hasNearbyWifiPermission,
                "ssid" to
                        if (ssidAccessible) {
                            rawSsid
                        } else {
                            "Permission required"
                        },
                "bssid" to
                        if (bssidAccessible) {
                            rawBssid
                        } else {
                            "Permission required"
                        },
                "rssi" to info.rssi,
                "signalStrength" to rssiLabel(info.rssi),
                "signalLevel" to calculateSignalLevel(info.rssi),
                "linkSpeedMbps" to info.linkSpeed,
                "frequencyMHz" to info.frequency,
                "band" to frequencyBandLabel(info.frequency),

                // LinkProperties belongs to the actual active Wi-Fi network.
                // This avoids accidentally returning an address from cellular,
                // VPN, or another interface.
                "ipAddress" to (getIpv4Address(linkProperties) ?: "Unknown"),

                // This can legitimately be -1 when Android redacts it.
                // It must not be used as the connection test.
                "networkId" to info.networkId,
                "hiddenSsid" to info.hiddenSSID,
                "macAddress" to (info.macAddress ?: REDACTED_MAC_ADDRESS),
                "networkHandle" to network.networkHandle.toString(),
        )
    }

    private fun disconnectedMap(
            wifiEnabled: Boolean,
            reason: String,
    ): Map<String, Any> {
        return mapOf(
                "connected" to false,
                "wifiEnabled" to wifiEnabled,
                "hasLocationPermission" to hasPermission(Manifest.permission.ACCESS_FINE_LOCATION),
                "hasNearbyWifiPermission" to
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            hasPermission(Manifest.permission.NEARBY_WIFI_DEVICES)
                        } else {
                            true
                        },
                "reason" to reason,
        )
    }

    private fun normalizeSsid(ssid: String?): String {
        if (ssid.isNullOrBlank()) return ""

        return ssid.removePrefix("\"").removeSuffix("\"").trim()
    }

    private fun getIpv4Address(
            linkProperties: LinkProperties?,
    ): String? {
        return linkProperties?.linkAddresses
                ?.firstOrNull { linkAddress ->
                    val address = linkAddress.address

                    address is Inet4Address &&
                            !address.isLoopbackAddress &&
                            !address.isLinkLocalAddress
                }
                ?.address
                ?.hostAddress
    }

    private fun calculateSignalLevel(rssi: Int): Int {
        return WifiManager.calculateSignalLevel(rssi, 5).coerceIn(0, 4)
    }

    private fun rssiLabel(rssi: Int): String =
            when {
                rssi >= -55 -> "Excellent"
                rssi >= -65 -> "Good"
                rssi >= -75 -> "Fair"
                rssi >= -85 -> "Weak"
                else -> "Very Weak"
            }

    private fun frequencyBandLabel(
            frequencyMHz: Int,
    ): String =
            when (frequencyMHz) {
                in 2400..2500 -> "2.4 GHz"
                in 4900..5900 -> "5 GHz"
                in 5925..7125 -> "6 GHz"
                else -> "Unknown"
            }

    private fun hasPermission(
            permission: String,
    ): Boolean {
        return ContextCompat.checkSelfPermission(
                context,
                permission,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private data class WifiConnection(
            val network: Network,
            val wifiInfo: WifiInfo,
            val linkProperties: LinkProperties?,
    )

    private companion object {
        const val REDACTED_MAC_ADDRESS = "02:00:00:00:00:00"
    }
}
