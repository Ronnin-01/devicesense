package com.example.devicesense.platform

// optional
import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.ListenableWorker.Result // shadows kotlin.Result in this file — required, not
import androidx.work.WorkerParameters

/**
 * Runs periodically in the background (scheduled by
 * [com.example.devicesense.DeviceSenseApplication]) to append one battery snapshot to history —
 * powering future battery-health estimation without needing the app to be open.
 *
 * Adds no new reading or storage logic of its own. It reuses [BatterySnapshotProvider] and
 * [BatteryHistoryStore] — the exact same classes the interactive
 * `getBatteryInfo`/`getBatteryHistory` calls use — and only decides *when* to call them.
 */
class BatterySamplingWorker(
        context: Context,
        params: WorkerParameters,
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            val snapshot = BatterySnapshotProvider(applicationContext).snapshot()
            BatteryHistoryStore(applicationContext).append(snapshot)

            Log.d(TAG, "Captured battery snapshot: level=${snapshot["level"]}%")
            Result.success()
        } catch (error: Exception) {
            // Transient failures (e.g. a system service briefly
            // unavailable) should retry on WorkManager's backoff
            // schedule rather than silently dropping this sample.
            Log.w(TAG, "Battery sampling failed, will retry", error)
            Result.retry()
        }
    }

    private companion object {
        const val TAG = "BatterySamplingWorker"
    }
}
