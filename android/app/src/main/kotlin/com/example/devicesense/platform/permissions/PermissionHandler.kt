package com.example.devicesense.platform.permissions

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.example.devicesense.platform.MethodHandler
import com.example.devicesense.platform.PermissionResultListener
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Handles all Android runtime permissions.
 *
 * Responsibilities:
 * - Check permission status
 * - Request runtime permission
 * - Open application settings
 *
 * This class is completely generic and is not tied to Bluetooth, Camera, NFC, or any specific
 * hardware.
 */
class PermissionHandler(
        private val activity: Activity,
) : MethodHandler, PermissionResultListener {

        override val method: String = "permission"

        companion object {
                private const val REQUEST_PERMISSION = 1001
        }

        /** Stores the Flutter result until Android returns the permission callback. */
        private var pendingResult: MethodChannel.Result? = null

        override fun handle(
                call: MethodCall,
                result: MethodChannel.Result,
        ) {

                val action = call.argument<String>("action")

                when (action) {
                        "check" -> checkPermission(call, result)
                        "request" -> requestPermission(call, result)
                        "openSettings" -> openAppSettings(result)
                        else -> result.notImplemented()
                }
        }

        /** Returns true if permission has already been granted. */
        private fun checkPermission(
                call: MethodCall,
                result: MethodChannel.Result,
        ) {

                val permissionName =
                        call.argument<String>("permission")
                                ?: return result.error(
                                        "INVALID_PERMISSION",
                                        "Permission name is missing.",
                                        null,
                                )

                val permissionType = PermissionType.from(permissionName)

                val permissionInfo = PermissionMapper.from(permissionType)

                if (!permissionInfo.runtimeRequired) {

                        result.success(PermissionStatus.NOT_REQUIRED.serialize())

                        return
                }

                val granted =
                        ContextCompat.checkSelfPermission(
                                activity,
                                permissionInfo.manifestPermission,
                        ) == PackageManager.PERMISSION_GRANTED

                val status =
                        if (granted) {
                                PermissionStatus.GRANTED
                        } else {
                                PermissionStatus.DENIED
                        }

                result.success(status.serialize())
        }

        /** Requests a runtime permission. */
        private fun requestPermission(
                call: MethodCall,
                result: MethodChannel.Result,
        ) {

                if (pendingResult != null) {

                        result.error(
                                "REQUEST_RUNNING",
                                "Another permission request is already active.",
                                null,
                        )

                        return
                }

                val permissionName =
                        call.argument<String>("permission")
                                ?: return result.error(
                                        "INVALID_PERMISSION",
                                        "Permission name is missing.",
                                        null,
                                )

                val permissionType = PermissionType.from(permissionName)

                val permissionInfo = PermissionMapper.from(permissionType)

                if (!permissionInfo.runtimeRequired) {

                        result.success(PermissionStatus.NOT_REQUIRED.serialize())

                        return
                }

                pendingResult = result

                ActivityCompat.requestPermissions(
                        activity,
                        arrayOf(permissionInfo.manifestPermission),
                        REQUEST_PERMISSION,
                )
        }

        /** Opens this application's settings page. */
        private fun openAppSettings(
                result: MethodChannel.Result,
        ) {

                val intent =
                        Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts(
                                        "package",
                                        activity.packageName,
                                        null,
                                ),
                        )

                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

                activity.startActivity(intent)

                result.success(true)
        }

        /** Receives Android permission result. */
        override fun onRequestPermissionsResult(
                requestCode: Int,
                permissions: Array<String>,
                grantResults: IntArray,
        ) {

                if (requestCode != REQUEST_PERMISSION) {
                        return
                }

                val granted =
                        grantResults.isNotEmpty() &&
                                grantResults[0] == PackageManager.PERMISSION_GRANTED

                val status =
                        if (granted) {

                                PermissionStatus.GRANTED
                        } else {

                                val permanentlyDenied =
                                        !ActivityCompat.shouldShowRequestPermissionRationale(
                                                activity,
                                                permissions.first(),
                                        )

                                if (permanentlyDenied) {
                                        PermissionStatus.PERMANENTLY_DENIED
                                } else {
                                        PermissionStatus.DENIED
                                }
                        }

                pendingResult?.success(status.serialize())

                // IMPORTANT
                pendingResult = null
        }
}
