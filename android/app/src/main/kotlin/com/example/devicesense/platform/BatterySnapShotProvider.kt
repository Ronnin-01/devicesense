package com.example.devicesense.platform

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager

/**
 * Reads a single battery snapshot from BatteryManager, the ACTION_BATTERY_CHANGED broadcast, and
 * PowerManager.
 *
 * Extracted out of `BatteryHandler` so the *exact same* reading logic can be reused by
 * [BatterySamplingWorker] in the background — Single Responsibility (this class only reads state,
 * it knows nothing about MethodChannel or WorkManager) and DRY (one implementation, two callers —
 * the interactive query and the background worker never drift apart).
 */
class BatterySnapshotProvider(private val context: Context) {

    fun snapshot(): Map<String, Any> {
        val batteryStatus =
                context.registerReceiver(
                        null,
                        IntentFilter(Intent.ACTION_BATTERY_CHANGED),
                )

        return buildMap {
            putAll(readBatteryManagerProperties())
            putAll(readBroadcastExtras(batteryStatus))
            putAll(readPowerManagerState())
            // Lets Dart (and the history store) order samples and show
            // "last updated" without guessing based on arrival time.
            put("timestamp", System.currentTimeMillis())
        }
    }

    // ---- BatteryManager: instantaneous electrical readings --------------

    private fun readBatteryManagerProperties(): Map<String, Any> {
        val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager

        val level = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        val currentNow =
                safeIntProperty(batteryManager, BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
        val chargeCounter =
                safeIntProperty(batteryManager, BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER)

        return buildMap {
            put("level", level)
            put("currentNowMicroAmps", currentNow)
            put("chargeCounterMicroAmpHours", chargeCounter)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                put("isChargingFlag", batteryManager.isCharging)
            }
        }
    }

    private fun safeIntProperty(batteryManager: BatteryManager, property: Int): Int {
        val value = batteryManager.getIntProperty(property)
        return if (value == Int.MIN_VALUE) -1 else value
    }

    // ---- ACTION_BATTERY_CHANGED: charge state, health, environment ------

    private fun readBroadcastExtras(batteryStatus: Intent?): Map<String, Any> {
        val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val health = batteryStatus?.getIntExtra(BatteryManager.EXTRA_HEALTH, -1) ?: -1
        val plugged = batteryStatus?.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1) ?: -1
        val voltage = batteryStatus?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1) ?: -1
        val temperature = batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
        val technology = batteryStatus?.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY) ?: "Unknown"
        val present = batteryStatus?.getBooleanExtra(BatteryManager.EXTRA_PRESENT, true) ?: true

        val rawLevel = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val rawScale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val levelFromBroadcast =
                if (rawLevel >= 0 && rawScale > 0) (rawLevel * 100) / rawScale else -1

        return mapOf(
                "isCharging" to
                        (status == BatteryManager.BATTERY_STATUS_CHARGING ||
                                status == BatteryManager.BATTERY_STATUS_FULL),
                "chargingSource" to chargingSource(plugged),
                "health" to batteryHealth(health),
                "voltage" to voltage,
                "temperature" to temperature / 10.0,
                "technology" to technology,
                "isBatteryPresent" to present,
                "levelFromBroadcast" to levelFromBroadcast,
        )
    }

    // ---- PowerManager: OS-level power state ------------------------------

    private fun readPowerManagerState(): Map<String, Any> {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager

        return buildMap {
            put("isPowerSaveMode", powerManager.isPowerSaveMode)
            put("isScreenInteractive", powerManager.isInteractive)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                put("isDeviceIdleMode", powerManager.isDeviceIdleMode)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put("thermalStatus", thermalStatusLabel(powerManager.currentThermalStatus))
            }
        }
    }

    private fun thermalStatusLabel(status: Int): String {
        return when (status) {
            PowerManager.THERMAL_STATUS_NONE -> "None"
            PowerManager.THERMAL_STATUS_LIGHT -> "Light"
            PowerManager.THERMAL_STATUS_MODERATE -> "Moderate"
            PowerManager.THERMAL_STATUS_SEVERE -> "Severe"
            PowerManager.THERMAL_STATUS_CRITICAL -> "Critical"
            PowerManager.THERMAL_STATUS_EMERGENCY -> "Emergency"
            PowerManager.THERMAL_STATUS_SHUTDOWN -> "Shutdown"
            else -> "Unknown"
        }
    }

    private fun chargingSource(source: Int): String {
        return when (source) {
            BatteryManager.BATTERY_PLUGGED_USB -> "USB"
            BatteryManager.BATTERY_PLUGGED_AC -> "AC Charger"
            BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Wireless"
            BatteryManager.BATTERY_PLUGGED_DOCK -> "Dock"
            else -> "Not Charging"
        }
    }

    private fun batteryHealth(health: Int): String {
        return when (health) {
            BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
            BatteryManager.BATTERY_HEALTH_COLD -> "Cold"
            BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Over Voltage"
            BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheated"
            BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "Failure"
            else -> "Unknown"
        }
    }
}
