package com.example.devicesense.platform

import android.Manifest
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothStatusCodes
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Reads Bluetooth adapter capabilities only.
 *
 * No scanning. No pairing. No bonded devices. No state changes.
 */
class BluetoothHandler(
        private val context: Context,
) : MethodHandler {

    override val method: String = "getBluetoothCapabilities"

    override fun handle(
            call: MethodCall,
            result: MethodChannel.Result,
    ) {

        result.success(collectBluetoothInfo())
    }

    private fun collectBluetoothInfo(): Map<String, Any> {

        val packageManager = context.packageManager

        val supported = packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH)

        val bleSupported = packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)

        if (!supported) {

            return mapOf(
                    "supported" to false,
                    "enabled" to false,
                    "bleSupported" to false,
                    "multipleAdvertisement" to false,
                    "offloadedFiltering" to false,
                    "offloadedBatching" to false,
                    "le2MPhy" to false,
                    "leCodedPhy" to false,
                    "extendedAdvertising" to false,
                    "leAudio" to false,
                    "adapterName" to "Unavailable",
                    "adapterAddress" to "Unavailable",
            )
        }

        val bluetoothManager = context.getSystemService(BluetoothManager::class.java)

        val adapter = bluetoothManager.adapter

        val hasConnectPermission =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    ContextCompat.checkSelfPermission(
                            context,
                            Manifest.permission.BLUETOOTH_CONNECT,
                    ) == PackageManager.PERMISSION_GRANTED
                } else {
                    true
                }

        val adapterName =
                if (hasConnectPermission) {
                    adapter.name ?: "Unknown"
                } else {
                    "Permission Required"
                }

        val adapterAddress =
                if (hasConnectPermission) {
                    adapter.address ?: "Unavailable"
                } else {
                    "Permission Required"
                }

        return mapOf(
                "supported" to supported,
                "enabled" to adapter.isEnabled,
                "bleSupported" to bleSupported,
                "multipleAdvertisement" to adapter.isMultipleAdvertisementSupported,
                "offloadedFiltering" to adapter.isOffloadedFilteringSupported,
                "offloadedBatching" to adapter.isOffloadedScanBatchingSupported,
                "le2MPhy" to
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                                adapter.isLe2MPhySupported
                        else false,
                "leCodedPhy" to
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                                adapter.isLeCodedPhySupported
                        else false,
                "extendedAdvertising" to
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                                adapter.isLeExtendedAdvertisingSupported
                        else false,
                "leAudio" to
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
                                adapter.isLeAudioSupported == BluetoothStatusCodes.FEATURE_SUPPORTED
                        else false,
                "adapterName" to adapterName,

                // On Android 6+ this usually returns 02:00:00:00:00:00
                // by design for privacy.
                "adapterAddress" to adapterAddress,
        )
    }
}
