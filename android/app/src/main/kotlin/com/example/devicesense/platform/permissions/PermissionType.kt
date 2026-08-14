package com.example.devicesense.platform.permissions

/**
 * Logical permissions understood by the native layer.
 *
 * These are independent of Android Manifest permissions.
 */
enum class PermissionType {
    CAMERA,
    MICROPHONE,
    BLUETOOTH_CONNECT,
    BLUETOOTH_SCAN,
    LOCATION,
    NOTIFICATION,
    NEARBY_WIFI_DEVICES,
    SENSORS,
    ACTIVITY_RECOGNITION;

    companion object {

        /** Converts the Flutter enum name into a native PermissionType. */
        fun from(value: String): PermissionType {

            return when (value) {
                "camera" -> CAMERA
                "microphone" -> MICROPHONE
                "bluetoothConnect" -> BLUETOOTH_CONNECT
                "bluetoothScan" -> BLUETOOTH_SCAN
                "location" -> LOCATION
                "notification" -> NOTIFICATION
                "BLUETOOTH_SCAN" -> BLUETOOTH_SCAN
                "nearbyWifiDevices" -> NEARBY_WIFI_DEVICES
                "sensors" -> SENSORS
                "activityRecognition" -> ACTIVITY_RECOGNITION
                else ->
                        throw IllegalArgumentException(
                                "Unknown permission type: $value",
                        )
            }
        }
    }
}
