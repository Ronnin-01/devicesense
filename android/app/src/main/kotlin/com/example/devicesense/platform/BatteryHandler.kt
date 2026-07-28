package com.example.devicesense.platform

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Exposes a single, on-demand battery snapshot to Dart via the `getBatteryInfo` method.
 *
 * Delegates the actual reading to [BatterySnapshotProvider] so this class only handles
 * method-channel routing — Single Responsibility. Pure query, no side effects: calling this never
 * writes anything (Command-Query Separation) — only [BatterySamplingWorker] appends to history, so
 * "reading battery info" can never surprise you by also mutating state.
 */
class BatteryHandler(context: Context) : MethodHandler {

    private val snapshotProvider = BatterySnapshotProvider(context)

    override val method = "getBatteryInfo"

    override fun handle(call: MethodCall, result: MethodChannel.Result) {
        result.success(snapshotProvider.snapshot())
    }
}
