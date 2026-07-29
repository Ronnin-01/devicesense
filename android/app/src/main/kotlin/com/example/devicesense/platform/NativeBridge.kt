package com.example.devicesense.platform

import android.content.Context
import com.example.devicesense.platform.permissions.PermissionHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NativeBridge(
        private val activity: FlutterActivity,
        private val context: Context,
) {

    private val handlers: List<MethodHandler> =
            listOf(
                    DeviceInfoHandler(),
                    BatteryHandler(context),
                    BatteryHistoryHandler(context),
                    BluetoothHandler(context),
                    PairedDevicesHandler(activity),
                    ConnectedDevicesHandler(context),
                    PermissionHandler(activity),
            )

    fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

        val handler = handlers.firstOrNull { it.method == call.method }

        if (handler == null) {
            result.notImplemented()
            return
        }

        try {
            handler.handle(call, result)
        } catch (error: Exception) {
            result.error(
                    "NATIVE_ERROR",
                    error.message,
                    null,
            )
        }
    }

    fun onRequestPermissionsResult(
            requestCode: Int,
            permissions: Array<String>,
            grantResults: IntArray,
    ) {
        handlers.filterIsInstance<PermissionResultListener>().forEach {
            it.onRequestPermissionsResult(
                    requestCode,
                    permissions,
                    grantResults,
            )
        }
    }
}
