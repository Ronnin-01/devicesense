package com.example.devicesense.platform

import android.os.Build

class DeviceInfoHandler {

    fun getDeviceInfo(): Map<String, String> {

        return mapOf(
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
                "socman" to Build.SOC_MANUFACTURER,
                "socmodel" to Build.SOC_MODEL,
                "odmsku" to Build.ODM_SKU,
                "time" to Build.TIME.toString(),
        )
    }
}
