package com.example.devicesense.platform

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Persists a bounded, rolling history of battery snapshots to SharedPreferences as a JSON array.
 * Uses `org.json` — bundled with the Android SDK itself, so this needs no new Gradle dependency.
 *
 * Single Responsibility: this class only knows how to read/write history. It doesn't know how a
 * snapshot is produced ([BatterySnapshotProvider]) or how it reaches Dart ([BatteryHistoryHandler]
 * ).
 */
class BatteryHistoryStore(context: Context) {

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /** Appends one snapshot, dropping the oldest entries past [MAX_ENTRIES]. */
    fun append(snapshot: Map<String, Any>) {
        val existing = readRawList()
        existing.add(JSONObject(snapshot))

        while (existing.size > MAX_ENTRIES) {
            existing.removeAt(0) // drop the oldest sample first
        }

        val updated = JSONArray()
        existing.forEach { updated.put(it) }

        prefs.edit().putString(KEY_HISTORY, updated.toString()).apply()
    }

    /** Returns all stored snapshots, oldest first. */
    fun readAll(): List<Map<String, Any?>> {
        return readRawList().map { obj ->
            obj.keys().asSequence().associateWith { key -> obj.get(key) }
        }
    }

    private fun readRawList(): MutableList<JSONObject> {
        val stored = prefs.getString(KEY_HISTORY, null) ?: return mutableListOf()
        return try {
            val array = JSONArray(stored)
            (0 until array.length()).map { array.getJSONObject(it) }.toMutableList()
        } catch (error: Exception) {
            // Corrupted or unexpected data — start fresh rather than crash.
            mutableListOf()
        }
    }

    private companion object {
        const val PREFS_NAME = "battery_history_prefs"
        const val KEY_HISTORY = "battery_history"

        // Keep this bounded so a device that runs for years doesn't grow
        // this file forever. At a 6-hour sampling interval, 500 entries
        // is roughly 4 months of history.
        const val MAX_ENTRIES = 500
    }
}
