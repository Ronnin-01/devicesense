package com.example.devicesense.platform.permissions

import android.Manifest
import android.os.Build

/** Converts logical PermissionTypes into Android runtime permissions. */
object PermissionMapper {

        fun from(type: PermissionType): PermissionInfo {

                return when (type) {
                        PermissionType.CAMERA ->
                                PermissionInfo(
                                        manifestPermission = Manifest.permission.CAMERA,
                                        runtimeRequired = true,
                                )
                        PermissionType.MICROPHONE ->
                                PermissionInfo(
                                        manifestPermission = Manifest.permission.RECORD_AUDIO,
                                        runtimeRequired = true,
                                )
                        PermissionType.LOCATION ->
                                PermissionInfo(
                                        manifestPermission =
                                                Manifest.permission.ACCESS_FINE_LOCATION,
                                        runtimeRequired = true,
                                )
                        PermissionType.BLUETOOTH_CONNECT ->
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {

                                        PermissionInfo(
                                                manifestPermission =
                                                        Manifest.permission.BLUETOOTH_CONNECT,
                                                runtimeRequired = true,
                                        )
                                } else {

                                        PermissionInfo(
                                                manifestPermission = Manifest.permission.BLUETOOTH,
                                                runtimeRequired = false,
                                        )
                                }
                        PermissionType.BLUETOOTH_SCAN ->
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {

                                        PermissionInfo(
                                                manifestPermission =
                                                        Manifest.permission.BLUETOOTH_SCAN,
                                                runtimeRequired = true,
                                        )
                                } else {

                                        PermissionInfo(
                                                manifestPermission = Manifest.permission.BLUETOOTH,
                                                runtimeRequired = false,
                                        )
                                }
                        PermissionType.NOTIFICATION ->
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {

                                        PermissionInfo(
                                                manifestPermission =
                                                        Manifest.permission.POST_NOTIFICATIONS,
                                                runtimeRequired = true,
                                        )
                                } else {

                                        PermissionInfo(
                                                manifestPermission = "",
                                                runtimeRequired = false,
                                        )
                                }
                        PermissionType.NEARBY_WIFI_DEVICES ->
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {

                                        PermissionInfo(
                                                manifestPermission =
                                                        Manifest.permission.NEARBY_WIFI_DEVICES,
                                                runtimeRequired = true,
                                        )
                                } else {

                                        PermissionInfo(
                                                manifestPermission = "",
                                                runtimeRequired = false,
                                        )
                                }
                        PermissionType.SENSORS ->
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {

                                        PermissionInfo(
                                                manifestPermission =
                                                        Manifest.permission.BODY_SENSORS,
                                                runtimeRequired = true,
                                        )
                                } else {

                                        PermissionInfo(
                                                manifestPermission = "",
                                                runtimeRequired = false,
                                        )
                                }
                }
        }
}
