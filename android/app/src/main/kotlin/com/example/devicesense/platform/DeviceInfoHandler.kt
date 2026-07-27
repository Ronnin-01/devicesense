package com.example.devicesense.platform

import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DeviceInfoHandler : MethodHandler {

    override val method: String = "getDeviceInfo"

    override fun handle(call: MethodCall, result: MethodChannel.Result) {
        result.success(collectDeviceInfo())
    }

    private fun collectDeviceInfo(): Map<String, String> {
        val info =
                mutableMapOf(
                        "manufacturer" to Build.MANUFACTURER,
                        "brand" to Build.BRAND,
                        "model" to Build.MODEL,
                        "device" to Build.DEVICE,
                        "hardware" to Build.HARDWARE,
                        "board" to Build.BOARD,
                        "product" to Build.PRODUCT,
                        "androidVersion" to Build.VERSION.RELEASE,
                        "sdk" to Build.VERSION.SDK_INT.toString(),
                        "abi" to Build.SUPPORTED_ABIS.joinToString(),
                        "bootloader" to Build.BOOTLOADER,
                        "display" to Build.DISPLAY,
                        "fingerprint" to Build.FINGERPRINT,
                        "host" to Build.HOST,
                        "time" to Build.TIME.toString(),
                        "tags" to Build.TAGS,
                        "securityPatch" to Build.VERSION.SECURITY_PATCH,
                        "buildType" to Build.TYPE,
                        "codename" to Build.VERSION.CODENAME,
                        "incremental" to Build.VERSION.INCREMENTAL,
                        "release" to Build.VERSION.RELEASE,
                        "baseOS" to Build.VERSION.BASE_OS,
                )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            info["socman"] = Build.SOC_MANUFACTURER
            info["socmodel"] = Build.SOC_MODEL
            info["odmsku"] = Build.ODM_SKU
        } else {
            info["socman"] = "Unavailable (requires Android 12+)"
            info["socmodel"] = "Unavailable (requires Android 12+)"
            info["odmsku"] = "Unavailable (requires Android 12+)"
        }

        return info
    }
}
