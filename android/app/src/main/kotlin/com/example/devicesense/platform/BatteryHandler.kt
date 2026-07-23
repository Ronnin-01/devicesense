package com.example.devicesense.platform

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Provides battery information using Android's BatteryManager and the ACTION_BATTERY_CHANGED sticky
 * broadcast.
 *
 * No runtime permission is required.
 *
 * Responsibilities:
 * - Battery percentage
 * - Charging state
 * - Charging source
 * - Battery health
 * - Voltage
 * - Temperature
 * - Technology
 */
class BatteryHandler(
        private val context: Context,
) : MethodHandler {

    override val method = "getBatteryInfo"

    override fun handle(
            call: MethodCall,
            result: MethodChannel.Result,
    ) {

        result.success(collectBatteryInfo())
    }

    private fun collectBatteryInfo(): Map<String, Any> {

        val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager

        val batteryStatus =
                context.registerReceiver(
                        null,
                        IntentFilter(Intent.ACTION_BATTERY_CHANGED),
                )

        val batteryLevel =
                batteryManager.getIntProperty(
                        BatteryManager.BATTERY_PROPERTY_CAPACITY,
                )

        val status =
                batteryStatus?.getIntExtra(
                        BatteryManager.EXTRA_STATUS,
                        -1,
                )
                        ?: -1

        val health =
                batteryStatus?.getIntExtra(
                        BatteryManager.EXTRA_HEALTH,
                        -1,
                )
                        ?: -1

        val plugged =
                batteryStatus?.getIntExtra(
                        BatteryManager.EXTRA_PLUGGED,
                        -1,
                )
                        ?: -1

        val voltage =
                batteryStatus?.getIntExtra(
                        BatteryManager.EXTRA_VOLTAGE,
                        -1,
                )
                        ?: -1

        val temperature =
                batteryStatus?.getIntExtra(
                        BatteryManager.EXTRA_TEMPERATURE,
                        -1,
                )
                        ?: -1

        val technology =
                batteryStatus?.getStringExtra(
                        BatteryManager.EXTRA_TECHNOLOGY,
                )
                        ?: "Unknown"

        return mapOf(
                "level" to batteryLevel,
                "isCharging" to
                        (status == BatteryManager.BATTERY_STATUS_CHARGING ||
                                status == BatteryManager.BATTERY_STATUS_FULL),
                "chargingSource" to chargingSource(plugged),
                "health" to batteryHealth(health),
                "voltage" to voltage,

                // Android reports tenths of a degree.
                "temperature" to temperature / 10.0,
                "technology" to technology,
        )
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
