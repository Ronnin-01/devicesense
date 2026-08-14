package com.example.devicesense.platform

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorManager
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SensorsCapabilitiesHandler(
        private val context: Context,
) : MethodHandler {

    override val method: String = "getSensorsCapabilities"

    override fun handle(
            call: MethodCall,
            result: MethodChannel.Result,
    ) {
        val sensorManager =
                context.applicationContext.getSystemService(Context.SENSOR_SERVICE) as?
                        SensorManager

        if (sensorManager == null) {
            result.error(
                    "SENSOR_UNSUPPORTED",
                    "Sensor service is unavailable on this device.",
                    null,
            )
            return
        }

        try {
            val sensors =
                    sensorManager
                            .getSensorList(Sensor.TYPE_ALL)
                            .sortedWith(
                                    compareBy<Sensor> { it.type }.thenBy { it.name }.thenBy {
                                        it.vendor
                                    },
                            )

            val sensorCatalog = sensors.map { sensor -> buildSensorMap(sensor) }

            result.success(
                    mapOf(
                            "supported" to true,
                            "sdkInt" to Build.VERSION.SDK_INT,
                            "sensorCount" to sensorCatalog.size,
                            "sensors" to sensorCatalog,
                    ),
            )
        } catch (error: Exception) {
            result.error(
                    "SENSOR_CAPABILITIES_ERROR",
                    error.message ?: "Failed to read sensor capabilities.",
                    null,
            )
        }
    }

    private fun buildSensorMap(sensor: Sensor): Map<String, Any> {
        val requiredPermission = requiredPermissionFor(sensor.type)

        return buildMap {
            put("id", sensorId(sensor))
            put("type", sensor.type)
            put("typeLabel", sensorTypeLabel(sensor.type))
            put("category", sensorCategoryLabel(sensor.type))

            put("name", sensor.name)
            put("vendor", sensor.vendor)
            put("version", sensor.version)
            put("stringType", sensorStringType(sensor))

            put("maximumRange", sensor.maximumRange)
            put("resolution", sensor.resolution)
            put("power", sensor.power)
            put("minDelay", sensor.minDelay)
            put("maxDelay", safeMaxDelay(sensor))

            put("reportingMode", reportingModeLabel(sensor.reportingMode))
            put("wakeUpSensor", safeWakeUpSensor(sensor))
            put("fifoReservedEventCount", sensor.fifoReservedEventCount)
            put("fifoMaxEventCount", sensor.fifoMaxEventCount)

            put("requiredPermission", requiredPermission ?: "")
            put("permissionRequired", requiredPermission != null)
            put("permissionReason", permissionReasonFor(sensor.type) ?: "")
        }
    }

    private fun sensorId(sensor: Sensor): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            sensor.id
        } else {
            -1
        }
    }

    private fun sensorStringType(sensor: Sensor): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            sensor.stringType ?: "Unknown"
        } else {
            "Unknown"
        }
    }

    private fun safeWakeUpSensor(sensor: Sensor): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            sensor.isWakeUpSensor
        } else {
            false
        }
    }

    private fun safeMaxDelay(sensor: Sensor): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            sensor.maxDelay
        } else {
            -1
        }
    }

    private fun requiredPermissionFor(sensorType: Int): String? {
        return when (sensorType) {
            TYPE_HEART_RATE, TYPE_HEART_BEAT -> "android.permission.BODY_SENSORS"
            TYPE_STEP_COUNTER, TYPE_STEP_DETECTOR -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    "android.permission.ACTIVITY_RECOGNITION"
                } else {
                    null
                }
            }
            else -> null
        }
    }

    private fun permissionReasonFor(sensorType: Int): String? {
        return when (sensorType) {
            TYPE_HEART_RATE, TYPE_HEART_BEAT ->
                    "Body Sensors permission is required to read heart-rate-type sensors."
            TYPE_STEP_COUNTER, TYPE_STEP_DETECTOR -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    "Activity Recognition permission is required to read step sensors on Android 10+."
                } else {
                    null
                }
            }
            else -> null
        }
    }

    private fun reportingModeLabel(mode: Int): String {
        return when (mode) {
            Sensor.REPORTING_MODE_CONTINUOUS -> "CONTINUOUS"
            Sensor.REPORTING_MODE_ON_CHANGE -> "ON_CHANGE"
            Sensor.REPORTING_MODE_ONE_SHOT -> "ONE_SHOT"
            Sensor.REPORTING_MODE_SPECIAL_TRIGGER -> "SPECIAL_TRIGGER"
            else -> "UNKNOWN"
        }
    }

    private fun sensorTypeLabel(type: Int): String {
        return when (type) {
            TYPE_ACCELEROMETER -> "Accelerometer"
            TYPE_AMBIENT_TEMPERATURE -> "Ambient Temperature"
            TYPE_GRAVITY -> "Gravity"
            TYPE_GYROSCOPE -> "Gyroscope"
            TYPE_GYROSCOPE_UNCALIBRATED -> "Gyroscope Uncalibrated"
            TYPE_HEART_BEAT -> "Heart Beat"
            TYPE_HEART_RATE -> "Heart Rate"
            TYPE_LIGHT -> "Light"
            TYPE_LINEAR_ACCELERATION -> "Linear Acceleration"
            TYPE_MAGNETIC_FIELD -> "Magnetic Field"
            TYPE_MAGNETIC_FIELD_UNCALIBRATED -> "Magnetic Field Uncalibrated"
            TYPE_ORIENTATION -> "Orientation"
            TYPE_PRESSURE -> "Pressure"
            TYPE_PROXIMITY -> "Proximity"
            TYPE_RELATIVE_HUMIDITY -> "Relative Humidity"
            TYPE_ROTATION_VECTOR -> "Rotation Vector"
            TYPE_GAME_ROTATION_VECTOR -> "Game Rotation Vector"
            TYPE_GEOMAGNETIC_ROTATION_VECTOR -> "Geomagnetic Rotation Vector"
            TYPE_SIGNIFICANT_MOTION -> "Significant Motion"
            TYPE_STEP_COUNTER -> "Step Counter"
            TYPE_STEP_DETECTOR -> "Step Detector"
            TYPE_TILT_DETECTOR -> "Tilt Detector"
            TYPE_WAKE_GESTURE -> "Wake Gesture"
            TYPE_GLANCE_GESTURE -> "Glance Gesture"
            TYPE_PICK_UP_GESTURE -> "Pick Up Gesture"
            TYPE_WRIST_TILT_GESTURE -> "Wrist Tilt Gesture"
            TYPE_DEVICE_ORIENTATION -> "Device Orientation"
            TYPE_POSE_6DOF -> "6DOF Pose"
            TYPE_STATIONARY_DETECT -> "Stationary Detect"
            TYPE_MOTION_DETECT -> "Motion Detect"
            TYPE_LOW_LATENCY_OFFBODY_DETECT -> "Low Latency Offbody Detect"
            TYPE_DYNAMIC_SENSOR_META -> "Dynamic Sensor Meta"
            TYPE_ADDITIONAL_INFO -> "Additional Info"
            else -> "Sensor Type $type"
        }
    }

    private fun sensorCategoryLabel(type: Int): String {
        return when (type) {
            TYPE_ACCELEROMETER,
            TYPE_GRAVITY,
            TYPE_LINEAR_ACCELERATION,
            TYPE_GYROSCOPE,
            TYPE_GYROSCOPE_UNCALIBRATED,
            TYPE_ROTATION_VECTOR,
            TYPE_GAME_ROTATION_VECTOR,
            TYPE_GEOMAGNETIC_ROTATION_VECTOR,
            TYPE_DEVICE_ORIENTATION,
            TYPE_POSE_6DOF -> "motion"
            TYPE_MAGNETIC_FIELD, TYPE_MAGNETIC_FIELD_UNCALIBRATED, TYPE_ORIENTATION -> "orientation"
            TYPE_LIGHT,
            TYPE_PRESSURE,
            TYPE_RELATIVE_HUMIDITY,
            TYPE_AMBIENT_TEMPERATURE,
            TYPE_PROXIMITY -> "environment"
            TYPE_STEP_COUNTER,
            TYPE_STEP_DETECTOR,
            TYPE_SIGNIFICANT_MOTION,
            TYPE_STATIONARY_DETECT,
            TYPE_MOTION_DETECT,
            TYPE_TILT_DETECTOR,
            TYPE_WAKE_GESTURE,
            TYPE_GLANCE_GESTURE,
            TYPE_PICK_UP_GESTURE,
            TYPE_WRIST_TILT_GESTURE -> "context"
            TYPE_HEART_RATE, TYPE_HEART_BEAT, TYPE_LOW_LATENCY_OFFBODY_DETECT -> "health"
            TYPE_DYNAMIC_SENSOR_META, TYPE_ADDITIONAL_INFO -> "system"
            else -> "other"
        }
    }

    private companion object {
        const val TYPE_ACCELEROMETER = 1
        const val TYPE_MAGNETIC_FIELD = 2
        const val TYPE_ORIENTATION = 3
        const val TYPE_GYROSCOPE = 4
        const val TYPE_LIGHT = 5
        const val TYPE_PRESSURE = 6
        const val TYPE_TEMPERATURE = 7
        const val TYPE_PROXIMITY = 8
        const val TYPE_GRAVITY = 9
        const val TYPE_LINEAR_ACCELERATION = 10
        const val TYPE_ROTATION_VECTOR = 11
        const val TYPE_RELATIVE_HUMIDITY = 12
        const val TYPE_AMBIENT_TEMPERATURE = 13
        const val TYPE_MAGNETIC_FIELD_UNCALIBRATED = 14
        const val TYPE_GAME_ROTATION_VECTOR = 15
        const val TYPE_GYROSCOPE_UNCALIBRATED = 16
        const val TYPE_SIGNIFICANT_MOTION = 17
        const val TYPE_STEP_DETECTOR = 18
        const val TYPE_STEP_COUNTER = 19
        const val TYPE_GEOMAGNETIC_ROTATION_VECTOR = 20
        const val TYPE_HEART_RATE = 21
        const val TYPE_TILT_DETECTOR = 22
        const val TYPE_WAKE_GESTURE = 23
        const val TYPE_GLANCE_GESTURE = 24
        const val TYPE_PICK_UP_GESTURE = 25
        const val TYPE_WRIST_TILT_GESTURE = 26
        const val TYPE_DEVICE_ORIENTATION = 27
        const val TYPE_POSE_6DOF = 28
        const val TYPE_STATIONARY_DETECT = 29
        const val TYPE_MOTION_DETECT = 30
        const val TYPE_HEART_BEAT = 31
        const val TYPE_DYNAMIC_SENSOR_META = 32
        const val TYPE_ADDITIONAL_INFO = 33
        const val TYPE_LOW_LATENCY_OFFBODY_DETECT = 34
    }
}
