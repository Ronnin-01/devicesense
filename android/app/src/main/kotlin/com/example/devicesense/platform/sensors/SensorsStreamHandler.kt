package com.example.devicesense.platform

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SensorStreamHandler(
        private val activity: Activity,
        private val context: Context,
) : EventChannel.StreamHandler, SensorEventListener {

    private val appContext = activity.applicationContext
    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager

    private val mainHandler = Handler(Looper.getMainLooper())

    private var eventSink: EventChannel.EventSink? = null
    private var disposed = false

    private data class RegisteredSensor(
            val sensor: Sensor,
            val samplingPeriodUs: Int,
    )

    // Keyed by a stable sensor key so multiple sensors can be tracked safely.
    private val activeSensors = mutableMapOf<String, RegisteredSensor>()

    fun handleControlCall(
            call: MethodCall,
            result: MethodChannel.Result,
    ) {
        if (sensorManager == null) {
            result.error(
                    "SENSOR_UNSUPPORTED",
                    "Sensor service is unavailable on this device.",
                    null,
            )
            return
        }

        if (disposed) {
            result.error(
                    "SENSOR_DISPOSED",
                    "Sensor handler has already been disposed.",
                    null,
            )
            return
        }

        when (call.method) {
            "startSensor" -> startSingleSensor(call, result)
            "stopSensor" -> stopSingleSensor(call, result)
            "startAllSensors" -> startAllSensors(call, result)
            "stopAllSensors" -> stopAllSensors(result)
            "getActiveSensors" -> result.success(activeSensorsSnapshot())
            else -> result.notImplemented()
        }
    }

    override fun onListen(
            arguments: Any?,
            events: EventChannel.EventSink?,
    ) {
        eventSink = events
        Log.d(TAG, "Sensor stream attached")
    }

    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "Sensor stream cancelled")
        stopAllSensorsInternal()
        eventSink = null
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || disposed) return

        val sensor = event.sensor ?: return

        val payload =
                buildMap<String, Any> {
                    put("event", "sensorData")
                    put("sensorKey", sensorKey(sensor))
                    put("type", sensor.type)
                    put("typeLabel", sensorTypeLabel(sensor.type))
                    put("category", sensorCategoryLabel(sensor.type))
                    put("name", sensor.name)
                    put("vendor", sensor.vendor)
                    put("version", sensor.version)
                    put("stringType", sensorStringType(sensor))

                    put("values", event.values.toList())
                    put("accuracy", event.accuracy)
                    put("accuracyLabel", accuracyLabel(event.accuracy))

                    // Android timestamps are nanoseconds since boot.
                    put("sensorTimestampNs", event.timestamp)
                    put("receivedAtMs", System.currentTimeMillis())

                    put("reportingMode", reportingModeLabel(sensor.reportingMode))
                    put("wakeUpSensor", safeWakeUpSensor(sensor))
                    put("power", sensor.power)
                    put("resolution", sensor.resolution)
                    put("maximumRange", sensor.maximumRange)
                    put("minDelay", sensor.minDelay)
                    put("maxDelay", safeMaxDelay(sensor))
                    put("fifoReservedEventCount", sensor.fifoReservedEventCount)
                    put("fifoMaxEventCount", sensor.fifoMaxEventCount)
                }

        emit(payload)
    }

    override fun onAccuracyChanged(
            sensor: Sensor?,
            accuracy: Int,
    ) {
        if (sensor == null || disposed) return

        val payload =
                buildMap<String, Any> {
                    put("event", "sensorAccuracyChanged")
                    put("sensorKey", sensorKey(sensor))
                    put("type", sensor.type)
                    put("typeLabel", sensorTypeLabel(sensor.type))
                    put("name", sensor.name)
                    put("vendor", sensor.vendor)
                    put("accuracy", accuracy)
                    put("accuracyLabel", accuracyLabel(accuracy))
                    put("receivedAtMs", System.currentTimeMillis())
                }

        emit(payload)
    }

    fun dispose() {
        if (disposed) return

        disposed = true
        stopAllSensorsInternal()
        eventSink = null
    }

    // ---------------------------------------------------------------------
    // Start / Stop
    // ---------------------------------------------------------------------

    private fun startSingleSensor(
            call: MethodCall,
            result: MethodChannel.Result,
    ) {
        val type =
                call.argument<Int>("type")
                        ?: return result.error(
                                "INVALID_ARGS",
                                "Sensor type is missing.",
                                null,
                        )

        val samplingPeriodUs =
                call.argument<Int>("samplingPeriodUs") ?: SensorManager.SENSOR_DELAY_UI

        val sensor =
                sensorManager?.getDefaultSensor(type)
                        ?: return result.error(
                                "SENSOR_NOT_FOUND",
                                "Sensor type $type was not found on this device.",
                                null,
                        )

        val permissionError = checkSensorPermissions(sensor)
        if (permissionError != null) {
            result.error(
                    "PERMISSION_DENIED",
                    permissionError,
                    null,
            )
            return
        }

        val key = sensorKey(sensor)
        if (activeSensors.containsKey(key)) {
            result.success(
                    mapOf(
                            "started" to true,
                            "alreadyActive" to true,
                            "sensorKey" to key,
                    )
            )
            return
        }

        try {
            val registered =
                    sensorManager.registerListener(
                            this,
                            sensor,
                            samplingPeriodUs,
                    )

            if (!registered) {
                result.error(
                        "SENSOR_FAILED",
                        "Failed to register listener for ${sensor.name}.",
                        null,
                )
                return
            }

            activeSensors[key] = RegisteredSensor(sensor, samplingPeriodUs)

            result.success(
                    mapOf(
                            "started" to true,
                            "alreadyActive" to false,
                            "sensorKey" to key,
                    )
            )
        } catch (error: SecurityException) {
            result.error(
                    "PERMISSION_DENIED",
                    error.message ?: "Permission denied while registering sensor.",
                    null,
            )
        } catch (error: Exception) {
            result.error(
                    "SENSOR_FAILED",
                    error.message ?: "Failed to register sensor listener.",
                    null,
            )
        }
    }

    private fun startAllSensors(
            call: MethodCall,
            result: MethodChannel.Result,
    ) {
        val samplingPeriodUs =
                call.argument<Int>("samplingPeriodUs") ?: SensorManager.SENSOR_DELAY_UI

        val allSensors =
                sensorManager
                        ?.getSensorList(Sensor.TYPE_ALL)
                        ?.sortedWith(
                                compareBy<Sensor> { it.type }.thenBy { it.name }.thenBy {
                                    it.vendor
                                }
                        )

        val started = mutableListOf<Map<String, Any>>()
        val skipped = mutableListOf<Map<String, Any>>()
        val failed = mutableListOf<Map<String, Any>>()

        allSensors?.forEach { sensor ->
            val permissionError = checkSensorPermissions(sensor)
            if (permissionError != null) {
                skipped.add(
                        mapOf(
                                "sensorKey" to sensorKey(sensor),
                                "type" to sensor.type,
                                "name" to sensor.name,
                                "reason" to permissionError,
                        )
                )
                return@forEach
            }

            val key = sensorKey(sensor)
            if (activeSensors.containsKey(key)) {
                started.add(
                        mapOf(
                                "sensorKey" to key,
                                "type" to sensor.type,
                                "name" to sensor.name,
                                "alreadyActive" to true,
                        )
                )
                return@forEach
            }

            try {
                val registered =
                        sensorManager?.registerListener(
                                this,
                                sensor,
                                samplingPeriodUs,
                        )

                if (registered != null && registered) {
                    activeSensors[key] = RegisteredSensor(sensor, samplingPeriodUs)
                    started.add(
                            mapOf(
                                    "sensorKey" to key,
                                    "type" to sensor.type,
                                    "name" to sensor.name,
                                    "alreadyActive" to false,
                            )
                    )
                } else {
                    failed.add(
                            mapOf(
                                    "sensorKey" to key,
                                    "type" to sensor.type,
                                    "name" to sensor.name,
                                    "reason" to "registerListener returned false",
                            )
                    )
                }
            } catch (error: SecurityException) {
                skipped.add(
                        mapOf(
                                "sensorKey" to key,
                                "type" to sensor.type,
                                "name" to sensor.name,
                                "reason" to (error.message ?: "Permission denied"),
                        )
                )
            } catch (error: Exception) {
                failed.add(
                        mapOf(
                                "sensorKey" to key,
                                "type" to sensor.type,
                                "name" to sensor.name,
                                "reason" to (error.message ?: "Unknown registration failure"),
                        )
                )
            }
        }

        result.success(
                mapOf(
                        "started" to started.isNotEmpty(),
                        "requestedCount" to allSensors?.size,
                        "startedCount" to started.size,
                        "skippedCount" to skipped.size,
                        "failedCount" to failed.size,
                        "startedSensors" to started,
                        "skippedSensors" to skipped,
                        "failedSensors" to failed,
                        "activeCount" to activeSensors.size,
                )
        )
    }

    private fun stopSingleSensor(
            call: MethodCall,
            result: MethodChannel.Result,
    ) {
        val type =
                call.argument<Int>("type")
                        ?: return result.error(
                                "INVALID_ARGS",
                                "Sensor type is missing.",
                                null,
                        )

        val matchingKeys = activeSensors.filterValues { it.sensor.type == type }.keys.toList()

        matchingKeys.forEach { key ->
            val sensor = activeSensors.remove(key)?.sensor
            if (sensor != null) {
                try {
                    sensorManager?.unregisterListener(this, sensor)
                } catch (error: Exception) {
                    Log.w(TAG, "Failed to unregister sensor: $key", error)
                }
            }
        }

        result.success(
                mapOf(
                        "stopped" to true,
                        "stoppedCount" to matchingKeys.size,
                        "activeCount" to activeSensors.size,
                )
        )
    }

    private fun stopAllSensors(
            result: MethodChannel.Result,
    ) {
        stopAllSensorsInternal()
        result.success(
                mapOf(
                        "stopped" to true,
                        "activeCount" to 0,
                )
        )
    }

    private fun stopAllSensorsInternal() {
        try {
            sensorManager?.unregisterListener(this)
        } catch (error: Exception) {
            Log.w(TAG, "Error while unregistering all sensors", error)
        } finally {
            activeSensors.clear()
        }
    }

    // ---------------------------------------------------------------------
    // Permissions
    // ---------------------------------------------------------------------

    private fun checkSensorPermissions(sensor: Sensor): String? {
        return when (sensor.type) {
            Sensor.TYPE_HEART_RATE, Sensor.TYPE_HEART_BEAT, -> {
                if (ContextCompat.checkSelfPermission(
                                activity,
                                Manifest.permission.BODY_SENSORS,
                        ) != PackageManager.PERMISSION_GRANTED
                ) {
                    "Body Sensors permission is required to read heart rate data."
                } else {
                    null
                }
            }
            Sensor.TYPE_STEP_COUNTER, Sensor.TYPE_STEP_DETECTOR, -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                                ContextCompat.checkSelfPermission(
                                        activity,
                                        Manifest.permission.ACTIVITY_RECOGNITION,
                                ) != PackageManager.PERMISSION_GRANTED
                ) {
                    "Activity Recognition permission is required to read step data on Android 10+."
                } else {
                    null
                }
            }
            else -> null
        }
    }

    // ---------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------

    private fun emit(payload: Map<String, Any>) {
        val sink = eventSink ?: return

        mainHandler.post {
            try {
                sink.success(payload)
            } catch (error: Exception) {
                Log.e(TAG, "Failed to send sensor event", error)
            }
        }
    }

    private fun activeSensorsSnapshot(): Map<String, Any> {
        val sensors =
                activeSensors.values.map { registered ->
                    buildMap<String, Any> {
                        put("sensorKey", sensorKey(registered.sensor))
                        put("type", registered.sensor.type)
                        put("typeLabel", sensorTypeLabel(registered.sensor.type))
                        put("name", registered.sensor.name)
                        put("vendor", registered.sensor.vendor)
                        put("samplingPeriodUs", registered.samplingPeriodUs)
                    }
                }

        return mapOf(
                "activeCount" to sensors.size,
                "activeSensors" to sensors,
        )
    }

    private fun sensorKey(sensor: Sensor): String {
        return buildString {
            append(sensor.type)
            append(':')
            append(sensor.name)
            append(':')
            append(sensor.vendor)
            append(':')
            append(sensor.version)
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

    private fun accuracyLabel(accuracy: Int): String {
        return when (accuracy) {
            SensorManager.SENSOR_STATUS_ACCURACY_HIGH -> "HIGH"
            SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM -> "MEDIUM"
            SensorManager.SENSOR_STATUS_ACCURACY_LOW -> "LOW"
            SensorManager.SENSOR_STATUS_UNRELIABLE -> "UNRELIABLE"
            else -> "UNKNOWN"
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
        private const val TAG = "SensorStreamHandler"
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
