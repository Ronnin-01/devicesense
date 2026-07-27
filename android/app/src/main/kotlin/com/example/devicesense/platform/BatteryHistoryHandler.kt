package com.example.devicesense.platform

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Exposes the background-collected battery history to Dart via the `getBatteryHistory` method.
 *
 * Read-only by design (Command-Query Separation): this handler never writes — only
 * [BatterySamplingWorker] appends new samples — so "reading history" can never accidentally change
 * it.
 */
class BatteryHistoryHandler(context: Context) : MethodHandler {

    private val historyStore = BatteryHistoryStore(context)

    override val method = "getBatteryHistory"

    override fun handle(call: MethodCall, result: MethodChannel.Result) {
        result.success(historyStore.readAll())
    }
}
