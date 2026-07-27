package com.example.devicesense

import android.app.Application
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.example.devicesense.platform.BatterySamplingWorker
import java.util.concurrent.TimeUnit

/**
 * Schedules background work once, at process startup — not tied to any Activity's lifecycle. This
 * matters because WorkManager can restart your app's process purely to run a background job,
 * without ever creating [MainActivity]; scheduling here (rather than in an Activity) is correct for
 * both cases.
 */
class DeviceSenseApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        scheduleBatterySampling()
    }

    private fun scheduleBatterySampling() {
        val constraints =
                Constraints.Builder()
                        // Don't sample when the battery is already critically low —
                        // avoid background work exactly when the user needs battery
                        // most. Deliberately NOT requiring charging: samples should
                        // span both charging and discharging states, or a future
                        // health estimate would only ever see one side of the story.
                        .setRequiresBatteryNotLow(true)
                        .build()

        val request =
                PeriodicWorkRequestBuilder<BatterySamplingWorker>(
                                SAMPLING_INTERVAL_HOURS,
                                TimeUnit.HOURS,
                        )
                        .setConstraints(constraints)
                        .build()

        WorkManager.getInstance(this)
                .enqueueUniquePeriodicWork(
                        UNIQUE_WORK_NAME,
                        // KEEP: onCreate() runs on every process start. Without KEEP,
                        // re-enqueueing here would restart the periodic cycle every
                        // time the app opens instead of leaving an already-scheduled
                        // job alone.
                        ExistingPeriodicWorkPolicy.KEEP,
                        request,
                )
    }

    private companion object {
        const val UNIQUE_WORK_NAME = "battery_sampling_work"
        const val SAMPLING_INTERVAL_HOURS = 6L
    }
}
