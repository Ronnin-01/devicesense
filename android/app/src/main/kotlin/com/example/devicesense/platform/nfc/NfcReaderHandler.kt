package com.example.devicesense.platform

import android.app.Activity
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NfcReaderHandler(private val activity: Activity) :
        EventChannel.StreamHandler, NfcAdapter.ReaderCallback {

    private var eventSink: EventChannel.EventSink? = null
    // Use volatile to ensure visibility across the main thread and background reader threads
    @Volatile private var isReading = false

    fun handleControlCall(call: MethodCall, result: MethodChannel.Result) {
        val nfcAdapter = NfcAdapter.getDefaultAdapter(activity)

        when (call.method) {
            "startNfcReader" -> {
                if (nfcAdapter == null) {
                    result.error("NFC_UNSUPPORTED", "NFC is not supported on this device.", null)
                    return
                }
                if (!nfcAdapter.isEnabled) {
                    result.error("NFC_DISABLED", "NFC is currently turned off in Settings.", null)
                    return
                }

                startReader(nfcAdapter)
                result.success(true)
            }
            "stopNfcReader" -> {
                stopReader(nfcAdapter)
                result.success(true)
            }
            "getNfcReaderStatus" -> {
                result.success(
                        mapOf(
                                "isReading" to isReading,
                                "nfcSupported" to (nfcAdapter != null),
                                "nfcEnabled" to (nfcAdapter?.isEnabled == true)
                        )
                )
            }
            else -> result.notImplemented()
        }
    }

    @Synchronized
    private fun startReader(nfcAdapter: NfcAdapter?) {
        if (nfcAdapter == null || !nfcAdapter.isEnabled || isReading) return

        val flags =
                NfcAdapter.FLAG_READER_NFC_A or
                        NfcAdapter.FLAG_READER_NFC_B or
                        NfcAdapter.FLAG_READER_NFC_F or
                        NfcAdapter.FLAG_READER_NFC_V or
                        NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS

        try {
            nfcAdapter.enableReaderMode(activity, this, flags, null)
            isReading = true
            activity.runOnUiThread {
                try {
                    eventSink?.success(
                            mapOf("event" to "nfcState", "isReading" to true, "nfcEnabled" to true)
                    )
                } catch (e: Exception) {
                    Log.e("NfcReaderHandler", "Failed to send nfcState event", e)
                }
            }
        } catch (e: Exception) {
            Log.e("NfcReaderHandler", "Error enabling reader mode", e)
            activity.runOnUiThread {
                try {
                    eventSink?.success(
                            mapOf(
                                    "event" to "nfcError",
                                    "message" to (e.message ?: "Failed to start NFC reader mode")
                            )
                    )
                } catch (ex: Exception) {
                    Log.e("NfcReaderHandler", "Failed to send nfcError event", ex)
                }
            }
        }
    }

    @Synchronized
    private fun stopReader(nfcAdapter: NfcAdapter?) {
        if (nfcAdapter != null && isReading) {
            try {
                nfcAdapter.disableReaderMode(activity)
            } catch (e: Exception) {
                Log.e("NfcReaderHandler", "Error disabling reader mode", e)
            }
        }
        isReading = false
        activity.runOnUiThread {
            try {
                eventSink?.success(mapOf("event" to "readerStopped", "isReading" to false))
            } catch (e: Exception) {
                // If the channel is already torn down, we silently catch it to prevent crashes
                Log.e("NfcReaderHandler", "Failed to send readerStopped event", e)
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
        val nfcAdapter = NfcAdapter.getDefaultAdapter(activity)

        try {
            if (nfcAdapter == null) {
                events?.success(
                        mapOf(
                                "event" to "nfcError",
                                "message" to "NFC hardware is not supported on this device."
                        )
                )
                return
            }

            events?.success(
                    mapOf(
                            "event" to "nfcState",
                            "isReading" to isReading,
                            "nfcEnabled" to nfcAdapter.isEnabled
                    )
            )
        } catch (e: Exception) {
            Log.e("NfcReaderHandler", "Error sending initial stream state", e)
        }
    }

    override fun onCancel(arguments: Any?) {
        val nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
        stopReader(nfcAdapter)
        this.eventSink = null // Ensure we don't hold a reference to a dead channel
    }

    override fun onTagDiscovered(tag: Tag?) {
        if (tag == null) return

        val tagDetails = parseTag(tag)

        activity.runOnUiThread {
            try {
                eventSink?.success(mapOf("event" to "tagDetected", "tag" to tagDetails))

                // Battery Optimization: Disable reader mode immediately after reading one tag
                val nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
                stopReader(nfcAdapter)
            } catch (e: Exception) {
                Log.e("NfcReaderHandler", "Failed to send tagDetected event", e)
            }
        }
    }

    private fun parseTag(tag: Tag): Map<String, Any> {
        val tagId = bytesToHex(tag.id)
        val techList = tag.techList.map { it.substringAfterLast(".") }

        var maxSize = 0
        var isWritable = false
        var isReadOnly = false
        var canMakeReadOnly = false
        val records = mutableListOf<Map<String, Any>>()

        val ndef = Ndef.get(tag)
        if (ndef != null) {
            try {
                ndef.connect()
                maxSize = ndef.maxSize
                isWritable = ndef.isWritable
                val msg = ndef.cachedNdefMessage ?: ndef.ndefMessage
                if (msg != null) {
                    for (rec in msg.records) {
                        records.add(
                                mapOf(
                                        "tnf" to rec.tnf.toInt(),
                                        "type" to String(rec.type, Charsets.UTF_8),
                                        "payload" to String(rec.payload, Charsets.UTF_8),
                                        "payloadHex" to bytesToHex(rec.payload),
                                        "parsedText" to parsePayloadText(rec.type, rec.payload)
                                )
                        )
                    }
                }
                isReadOnly = !ndef.isWritable
                canMakeReadOnly = ndef.canMakeReadOnly()
                ndef.close()
            } catch (e: Exception) {
                Log.e("NfcReaderHandler", "Error reading NDEF data", e)
            }
        }

        return mapOf(
                "id" to tagId,
                "techs" to techList,
                "maxSize" to maxSize,
                "isWritable" to isWritable,
                "isReadOnly" to isReadOnly,
                "canMakeReadOnly" to canMakeReadOnly,
                "records" to records,
                "timestamp" to System.currentTimeMillis()
        )
    }

    private fun bytesToHex(bytes: ByteArray?): String {
        if (bytes == null || bytes.isEmpty()) return "N/A"
        return bytes.joinToString(":") { String.format("%02X", it) }
    }

    private fun parsePayloadText(typeBytes: ByteArray, payload: ByteArray): String {
        if (payload.isEmpty()) return ""
        try {
            val typeStr = String(typeBytes, Charsets.UTF_8)
            if (typeStr == "T" && payload.isNotEmpty()) {
                val statusByte = payload[0].toInt()
                val isUtf16 = (statusByte and 0x80) != 0
                val languageCodeLength = statusByte and 0x3F
                val charset = if (isUtf16) Charsets.UTF_16 else Charsets.UTF_8
                if (payload.size >= 1 + languageCodeLength) {
                    return String(
                            payload,
                            1 + languageCodeLength,
                            payload.size - (1 + languageCodeLength),
                            charset
                    )
                }
            }
            if (typeStr == "U" && payload.isNotEmpty()) {
                val prefixCode = payload[0].toInt()
                val prefix = URI_PREFIXES.getOrNull(prefixCode) ?: ""
                val uriBody = String(payload, 1, payload.size - 1, Charsets.UTF_8)
                return prefix + uriBody
            }
        } catch (e: Exception) {
            Log.e("NfcReaderHandler", "Error parsing record payload", e)
        }
        return String(payload, Charsets.UTF_8).filter { it.code in 32..126 }
    }

    companion object {
        private val URI_PREFIXES =
                arrayOf(
                        "",
                        "http://www.",
                        "https://www.",
                        "http://",
                        "https://",
                        "tel:",
                        "mailto:",
                        "ftp://anonymous:anonymous@",
                        "ftp://ftp.",
                        "ftps://",
                        "sftp://",
                        "smb://",
                        "nfs://",
                        "ftp://",
                        "dav://",
                        "news:",
                        "telnet://",
                        "imap:",
                        "rtsp://",
                        "urn:",
                        "pop:",
                        "sip:",
                        "sips:",
                        "tftp:",
                        "btspp://",
                        "btl2cap://",
                        "btgoep://",
                        "tcpobex://",
                        "irdaobex://",
                        "file://",
                        "urn:epc:id:",
                        "urn:epc:tag:",
                        "urn:epc:pat:",
                        "urn:epc:raw:",
                        "urn:epc:",
                        "urn:nfc:"
                )
    }
}
