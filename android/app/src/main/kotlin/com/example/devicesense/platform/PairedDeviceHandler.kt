package com.example.devicesense.platform

import android.Manifest
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Reads the set of devices bonded (paired) to this adapter via
 * [android.bluetooth.BluetoothAdapter.getBondedDevices].
 *
 * No scanning is performed — this only reads the already-paired list that the OS maintains. Does
 * not open any connections.
 *
 * Requires:
 * - API <= 30: android.permission.BLUETOOTH (install-time, no dialog)
 * - API >= 31: android.permission.BLUETOOTH_CONNECT (runtime dialog)
 *
 * Returns an empty list (not an error) if the permission hasn't been granted yet — the Dart side
 * decides whether to show a permission prompt based on the `permissionRequired` flag in the
 * response.
 */
class PairedDevicesHandler(
        private val context: Context,
) : MethodHandler {

    override val method: String = "getPairedDevices"

    override fun handle(call: MethodCall, result: MethodChannel.Result) {
        result.success(collectPairedDevices())
    }

    private fun collectPairedDevices(): Map<String, Any> {
        val packageManager = context.packageManager

        // Device doesn't support Bluetooth at all.
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH)) {
            return mapOf(
                    "supported" to false,
                    "permissionRequired" to false,
                    "devices" to emptyList<Any>(),
            )
        }

        // On API 31+ BLUETOOTH_CONNECT is a runtime permission.
        // On API <= 30 the install-time BLUETOOTH permission is enough
        // and PermissionMapper already reflects this — no dialog needed.
        val needsRuntimePermission = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
        val hasPermission =
                if (needsRuntimePermission) {
                    ContextCompat.checkSelfPermission(
                            context,
                            Manifest.permission.BLUETOOTH_CONNECT,
                    ) == PackageManager.PERMISSION_GRANTED
                } else {
                    true
                }

        if (!hasPermission) {
            return mapOf(
                    "supported" to true,
                    "permissionRequired" to true,
                    "devices" to emptyList<Any>(),
            )
        }

        val bluetoothManager = context.getSystemService(BluetoothManager::class.java)
        val adapter = bluetoothManager.adapter

        if (!adapter.isEnabled) {
            return mapOf(
                    "supported" to true,
                    "permissionRequired" to false,
                    "bluetoothEnabled" to false,
                    "devices" to emptyList<Any>(),
            )
        }

        val devices =
                adapter.bondedDevices.orEmpty().map { device ->
                    val bluetoothClass = device.bluetoothClass
                    mapOf(
                            "name" to (device.name ?: "Unknown Device"),
                            // On API 29+ the real MAC is redacted to
                            // XX:XX:XX:XX:XX:XX for privacy — still useful as a
                            // stable unique key within this session, just not a
                            // real hardware address.
                            "address" to device.address,
                            "bondState" to bondStateLabel(device.bondState),
                            "type" to deviceTypeLabel(device.type),
                            "deviceClass" to deviceClassLabel(bluetoothClass),
                            "category" to deviceCategory(bluetoothClass),
                            "supportsAudio" to
                                    (bluetoothClass?.hasService(BluetoothClass.Service.AUDIO) ==
                                            true),
                            "supportsNetwork" to
                                    (bluetoothClass?.hasService(
                                            BluetoothClass.Service.NETWORKING
                                    ) == true),
                            "supportsObex" to
                                    (bluetoothClass?.hasService(
                                            BluetoothClass.Service.OBJECT_TRANSFER
                                    ) == true),
                    )
                }

        return mapOf(
                "supported" to true,
                "permissionRequired" to false,
                "bluetoothEnabled" to true,
                "devices" to devices,
        )
    }

    // ---- Labels ---------------------------------------------------------

    private fun bondStateLabel(state: Int): String =
            when (state) {
                android.bluetooth.BluetoothDevice.BOND_BONDED -> "Bonded"
                android.bluetooth.BluetoothDevice.BOND_BONDING -> "Bonding"
                android.bluetooth.BluetoothDevice.BOND_NONE -> "Not Bonded"
                else -> "Unknown"
            }

    private fun deviceTypeLabel(type: Int): String =
            when (type) {
                android.bluetooth.BluetoothDevice.DEVICE_TYPE_CLASSIC -> "Classic"
                android.bluetooth.BluetoothDevice.DEVICE_TYPE_LE -> "BLE"
                android.bluetooth.BluetoothDevice.DEVICE_TYPE_DUAL -> "Dual (Classic + BLE)"
                android.bluetooth.BluetoothDevice.DEVICE_TYPE_UNKNOWN -> "Unknown"
                else -> "Unknown"
            }

    /**
     * Human-readable label for the full (major + minor) device class. Covers the classes you'll
     * realistically see in a paired list; everything else falls through to the major-class label.
     */
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
            BluetoothClass.Device.HEALTH_BLOOD_PRESSURE -> "Blood Pressure Monitor"
            BluetoothClass.Device.HEALTH_PULSE_RATE -> "Heart Rate Monitor"
            BluetoothClass.Device.HEALTH_DATA_DISPLAY -> "Health Display"
            else -> majorClassLabel(btClass)
        }
    }

    /** Broader category used for grouping + icon selection in the UI. */
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
}
