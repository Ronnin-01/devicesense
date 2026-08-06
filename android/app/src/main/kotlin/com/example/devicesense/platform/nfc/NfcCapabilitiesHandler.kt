package com.example.devicesense.platform

import android.content.Context
import android.content.pm.PackageManager
import android.nfc.NfcAdapter
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NfcCapabilitiesHandler(private val context: Context) : MethodHandler {

        override val method: String = "getNfcCapabilities"

        override fun handle(call: MethodCall, result: MethodChannel.Result) {
                val nfcAdapter = NfcAdapter.getDefaultAdapter(context)

                if (nfcAdapter == null) {
                        result.success(
                                mapOf(
                                        "nfcSupported" to false,
                                        "nfcEnabled" to false,
                                        "nfcState" to "UNSUPPORTED",
                                        "isNdefSupported" to false,
                                        "isMifareClassicSupported" to false,
                                        "isHceSupported" to false
                                )
                        )
                        return
                }

                val packageManager = context.packageManager
                val hasHce =
                        packageManager.hasSystemFeature(
                                PackageManager.FEATURE_NFC_HOST_CARD_EMULATION
                        )
                // Mifare Classic support is chipset-dependent (common on NXP chips, often absent on
                // Broadcom)
                val hasMifare = packageManager.hasSystemFeature("com.nxp.mifare")

                val stateLabel = if (nfcAdapter.isEnabled) "ENABLED" else "DISABLED"

                result.success(
                        mapOf(
                                "nfcSupported" to true,
                                "nfcEnabled" to nfcAdapter.isEnabled,
                                "nfcState" to stateLabel,
                                "isNdefSupported" to true,
                                "isMifareClassicSupported" to hasMifare,
                                "isHceSupported" to hasHce
                        )
                )
        }
}
