package com.example.background_notif

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class NotificationListenerService : NotificationListenerService() {

    companion object {
        const val TAG = "NotificationListener"

        // Flutter listens to this while the UI is alive.
        var eventSink: io.flutter.plugin.common.EventChannel.EventSink? = null
    }

    private val savedDir: File
        get() = File(filesDir, "notifications")

    override fun onListenerConnected() {
        super.onListenerConnected()

        savedDir.mkdirs()

        Log.d(TAG, "Notification Listener connected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val notification = sbn.notification
            val extras = notification.extras

            val packageName = sbn.packageName

            val tag = sbn.tag ?: "no_tag"

            val title = extras
                ?.getCharSequence(Notification.EXTRA_TITLE)
                ?.toString()
                ?: ""

            val text = extras
                ?.getCharSequence(Notification.EXTRA_TEXT)
                ?.toString()
                ?: ""

            val bigText = extras
                ?.getCharSequence(Notification.EXTRA_BIG_TEXT)
                ?.toString()
                ?: ""

            val timestamp = sbn.postTime

            val data = JSONObject().apply {
                put("packageName", packageName)
                put("tag", tag)
                put("title", title)
                put("text", text)
                put("bigText", bigText)
                put("timestamp", timestamp)
            }

            Log.d(
                TAG,
                "Notification posted: " +
                    "package=$packageName " +
                    "title=$title " +
                    "text=$text"
            )

            // Save permanently.
            saveNotification(data)

            // Send immediately to Flutter if Flutter is running.
            eventSink?.success(
                mapOf(
                    "packageName" to packageName,
                    "tag" to tag,
                    "title" to title,
                    "text" to text,
                    "bigText" to bigText,
                    "timestamp" to timestamp
                )
            )

        } catch (e: Exception) {
            Log.e(TAG, "Error processing notification", e)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        Log.d(
            TAG,
            "Notification removed: package=${sbn.packageName}"
        )
    }

    private fun saveNotification(data: JSONObject) {
        try {
            savedDir.mkdirs()

            val timestamp = SimpleDateFormat(
                "yyyyMMdd_HHmmss_SSS",
                Locale.US
            ).format(Date())

            val packageName = data
                .optString("packageName", "unknown")
                .replace(Regex("[^a-zA-Z0-9._-]"), "_")

            val fileName =
                "${timestamp}_${packageName}.json"

            val file = File(savedDir, fileName)

            file.writeText(data.toString())

            Log.d(TAG, "Saved notification: ${file.absolutePath}")

        } catch (e: Exception) {
            Log.e(TAG, "Failed to save notification", e)
        }
    }
}