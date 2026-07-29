package com.example.devicesense.platform

import android.Manifest
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ConnectedDevicesHandler(
        private val context: Context,
) : MethodHandler {

        override val method = "getConnectedDevices"

        override fun handle(
                call: MethodCall,
                result: MethodChannel.Result,
        ) {

                val packageManager = context.packageManager

                if (!packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH)) {

                        result.success(
                                mapOf(
                                        "supported" to false,
                                        "bluetoothEnabled" to false,
                                        "permissionRequired" to false,
                                        "devices" to emptyList<Map<String, Any>>(),
                                )
                        )

                        return
                }

                val manager = context.getSystemService(BluetoothManager::class.java)

                val adapter = manager.adapter

                if (adapter == null) {

                        result.success(
                                mapOf(
                                        "supported" to false,
                                        "bluetoothEnabled" to false,
                                        "permissionRequired" to false,
                                        "devices" to emptyList<Map<String, Any>>(),
                                )
                        )

                        return
                }

                if (!adapter.isEnabled) {

                        result.success(
                                mapOf(
                                        "supported" to true,
                                        "bluetoothEnabled" to false,
                                        "permissionRequired" to false,
                                        "devices" to emptyList<Map<String, Any>>(),
                                )
                        )

                        return
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {

                        val granted =
                                ContextCompat.checkSelfPermission(
                                        context,
                                        Manifest.permission.BLUETOOTH_CONNECT,
                                ) == PackageManager.PERMISSION_GRANTED

                        if (!granted) {

                                result.success(
                                        mapOf(
                                                "supported" to true,
                                                "bluetoothEnabled" to true,
                                                "permissionRequired" to true,
                                                "devices" to emptyList<Map<String, Any>>(),
                                        )
                                )

                                return
                        }
                }

                ConnectedCollector(
                                context,
                                adapter,
                                result,
                        )
                        .start()
        }

        private class ConnectedCollector(
                private val context: Context,
                private val adapter: android.bluetooth.BluetoothAdapter,
                private val result: MethodChannel.Result,
        ) {

                private val profiles =
                        listOf(
                                BluetoothProfile.A2DP to "A2DP",
                                BluetoothProfile.HEADSET to "Headset",
                                BluetoothProfile.GATT to "GATT",
                        )

                private val devices = mutableListOf<Map<String, Any>>()

                private var completed = 0

                fun start() {

                        profiles.forEach { (profileId, profileName) ->
                                adapter.getProfileProxy(
                                        context,
                                        object : BluetoothProfile.ServiceListener {

                                                override fun onServiceConnected(
                                                        profile: Int,
                                                        proxy: BluetoothProfile,
                                                ) {

                                                        proxy.connectedDevices.forEach {
                                                                devices.add(
                                                                        mapDevice(
                                                                                it,
                                                                                profileName,
                                                                        )
                                                                )
                                                        }

                                                        adapter.closeProfileProxy(
                                                                profile,
                                                                proxy,
                                                        )

                                                        finish()
                                                }

                                                override fun onServiceDisconnected(profile: Int) {
                                                        finish()
                                                }
                                        },
                                        profileId,
                                )
                        }
                }

                @Synchronized
                private fun finish() {

                        completed++

                        if (completed != profiles.size) return

                        val unique = devices.distinctBy { it["address"] }

                        result.success(
                                mapOf(
                                        "supported" to true,
                                        "bluetoothEnabled" to true,
                                        "permissionRequired" to false,
                                        "devices" to unique,
                                )
                        )
                }

                private fun mapDevice(
                        device: BluetoothDevice,
                        profile: String,
                ): Map<String, Any> {

                        val btClass = device.bluetoothClass

                        return mapOf(
                                "name" to (device.name ?: "Unknown Device"),
                                "address" to device.address,
                                "profile" to profile,
                                "bondState" to bondState(device.bondState),
                                "type" to deviceType(device.type),
                                "deviceClass" to deviceClassLabel(btClass),
                                "category" to category(btClass),
                        )
                }

                private fun bondState(state: Int): String =
                        when (state) {
                                BluetoothDevice.BOND_BONDED -> "Bonded"
                                BluetoothDevice.BOND_BONDING -> "Bonding"
                                else -> "Not Bonded"
                        }

                private fun deviceType(type: Int): String =
                        when (type) {
                                BluetoothDevice.DEVICE_TYPE_CLASSIC -> "Classic"
                                BluetoothDevice.DEVICE_TYPE_LE -> "BLE"
                                BluetoothDevice.DEVICE_TYPE_DUAL -> "Dual"
                                else -> "Unknown"
                        }

                private fun category(btClass: BluetoothClass?): String {

                        if (btClass == null) return "Other"

                        return when (btClass.majorDeviceClass) {
                                BluetoothClass.Device.Major.AUDIO_VIDEO -> "Audio"
                                BluetoothClass.Device.Major.COMPUTER -> "Computer"
                                BluetoothClass.Device.Major.PHONE -> "Phone"
                                BluetoothClass.Device.Major.WEARABLE -> "Wearable"
                                BluetoothClass.Device.Major.PERIPHERAL -> "Peripheral"
                                BluetoothClass.Device.Major.HEALTH -> "Health"
                                BluetoothClass.Device.Major.IMAGING -> "Imaging"
                                BluetoothClass.Device.Major.NETWORKING -> "Networking"
                                BluetoothClass.Device.Major.TOY -> "Toy"
                                else -> "Other"
                        }
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
                                BluetoothClass.Device.PERIPHERAL_KEYBOARD_POINTING ->
                                        "Keyboard + Mouse"
                                BluetoothClass.Device.HEALTH_BLOOD_PRESSURE ->
                                        "Blood Pressure Monitor"
                                BluetoothClass.Device.HEALTH_PULSE_RATE -> "Heart Rate Monitor"
                                BluetoothClass.Device.HEALTH_DATA_DISPLAY -> "Health Display"
                                else -> majorClassLabel(btClass)
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
}
