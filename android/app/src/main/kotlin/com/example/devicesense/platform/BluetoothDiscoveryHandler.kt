package com.example.devicesense.platform

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel

class BluetoothDiscoveryHandler(
        private val context: Context,
) : EventChannel.StreamHandler {

    private val bluetoothManager = context.getSystemService(BluetoothManager::class.java)

    private val adapter = bluetoothManager.adapter

    private var events: EventChannel.EventSink? = null

    private var receiverRegistered = false

    private val receiver =
            object : BroadcastReceiver() {

                override fun onReceive(
                        context: Context,
                        intent: Intent,
                ) {

                    when (intent.action) {
                        BluetoothAdapter.ACTION_DISCOVERY_STARTED -> {

                            Log.d(TAG, "Discovery Started")

                            events?.success(
                                    mapOf(
                                            "event" to "scanStarted",
                                    )
                            )
                        }
                        BluetoothDevice.ACTION_FOUND -> {

                            val device =
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {

                                        intent.getParcelableExtra(
                                                BluetoothDevice.EXTRA_DEVICE,
                                                BluetoothDevice::class.java,
                                        )
                                    } else {

                                        @Suppress("DEPRECATION")
                                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                                    }

                            val rssi =
                                    intent.getShortExtra(
                                                    BluetoothDevice.EXTRA_RSSI,
                                                    Short.MIN_VALUE
                                            )
                                            .toInt()

                            if (device != null) {

                                Log.d(
                                        TAG,
                                        """
                                    Device Found
                                    Name=${device.name}
                                    Address=${device.address}
                                    RSSI=$rssi
                                    Type=${deviceType(device.type)}
                                    Bond=${bondState(device.bondState)}
                                    """.trimIndent()
                                )

                                events?.success(
                                        mapOf(
                                                "event" to "deviceUpdate",
                                                "device" to
                                                        mapOf(
                                                                "name" to
                                                                        (device.name
                                                                                ?: "Unknown Device"),
                                                                "address" to device.address,
                                                                "rssi" to rssi,
                                                                "type" to deviceType(device.type),
                                                                "bondState" to
                                                                        bondState(device.bondState),
                                                                "class" to
                                                                        deviceClass(
                                                                                device.bluetoothClass
                                                                        ),
                                                                "timestamp" to
                                                                        System.currentTimeMillis(),
                                                        )
                                        )
                                )
                            }
                        }
                        BluetoothAdapter.ACTION_STATE_CHANGED -> {

                            val state =
                                    intent.getIntExtra(
                                            BluetoothAdapter.EXTRA_STATE,
                                            BluetoothAdapter.ERROR,
                                    )

                            val stateName =
                                    when (state) {
                                        BluetoothAdapter.STATE_OFF -> "OFF"
                                        BluetoothAdapter.STATE_TURNING_OFF -> "TURNING_OFF"
                                        BluetoothAdapter.STATE_ON -> "ON"
                                        BluetoothAdapter.STATE_TURNING_ON -> "TURNING_ON"
                                        else -> "UNKNOWN"
                                    }

                            Log.d(TAG, "Bluetooth State : $stateName")

                            events?.success(
                                    mapOf(
                                            "event" to "adapterState",
                                            "state" to stateName,
                                            "timestamp" to System.currentTimeMillis(),
                                    )
                            )
                        }
                        BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {

                            events?.success(
                                    mapOf(
                                            "event" to "scanFinished",
                                    )
                            )
                        }
                    }
                }
            }

    override fun onListen(
            arguments: Any?,
            eventSink: EventChannel.EventSink,
    ) {
        Log.d(TAG, "onListen() called")

        events = eventSink

        registerReceiver()

        startDiscovery()
    }

    override fun onCancel(arguments: Any?) {

        stopDiscovery()

        unregisterReceiver()

        events = null
    }

    fun dispose() {

        stopDiscovery()

        unregisterReceiver()
    }

    private fun hasScanPermission(): Boolean {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {

            return ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) ==
                    PackageManager.PERMISSION_GRANTED
        }

        return true
    }

    private fun deviceType(type: Int): String {

        return when (type) {
            BluetoothDevice.DEVICE_TYPE_CLASSIC -> "Classic"
            BluetoothDevice.DEVICE_TYPE_LE -> "BLE"
            BluetoothDevice.DEVICE_TYPE_DUAL -> "Dual"
            else -> "Unknown"
        }
    }

    private fun bondState(state: Int): String {

        return when (state) {
            BluetoothDevice.BOND_BONDED -> "Bonded"
            BluetoothDevice.BOND_BONDING -> "Bonding"
            BluetoothDevice.BOND_NONE -> "Not Bonded"
            else -> "Unknown"
        }
    }

    private fun deviceClass(bluetoothClass: BluetoothClass?): String {

        return when (bluetoothClass?.majorDeviceClass) {
            BluetoothClass.Device.Major.AUDIO_VIDEO -> "Audio"
            BluetoothClass.Device.Major.COMPUTER -> "Computer"
            BluetoothClass.Device.Major.PHONE -> "Phone"
            BluetoothClass.Device.Major.WEARABLE -> "Wearable"
            BluetoothClass.Device.Major.PERIPHERAL -> "Peripheral"
            BluetoothClass.Device.Major.HEALTH -> "Health"
            else -> "Unknown"
        }
    }

    // ----------------------------------------------------------------

    private fun startDiscovery() {

        if (!hasScanPermission()) {
            Log.e(TAG, "Bluetooth scan permission missing")
            return
        }

        if (adapter == null) return

        if (!adapter.isEnabled) return

        if (adapter.isDiscovering) {
            adapter.cancelDiscovery()
        }

        adapter.startDiscovery()
    }

    private fun stopDiscovery() {

        if (adapter == null) return

        if (adapter.isDiscovering) {
            adapter.cancelDiscovery()
        }
    }

    // ----------------------------------------------------------------

    private fun registerReceiver() {

        if (receiverRegistered) return

        val filter =
                IntentFilter().apply {

                    // Discovery
                    addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED)
                    addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)

                    // Devices
                    addAction(BluetoothDevice.ACTION_FOUND)

                    // Adapter State
                    addAction(BluetoothAdapter.ACTION_STATE_CHANGED)
                }

        context.registerReceiver(
                receiver,
                filter,
        )

        receiverRegistered = true
    }

    private fun unregisterReceiver() {

        if (!receiverRegistered) return

        context.unregisterReceiver(receiver)

        receiverRegistered = false
    }

    companion object {
        private const val TAG = "BluetoothDiscovery"
    }
}
