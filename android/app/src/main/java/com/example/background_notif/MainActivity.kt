package com.example.background_notif

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File

class MainActivity : FlutterActivity() {

    companion object {
        private const val METHOD_CHANNEL =
            "com.example.background_notif/methods"

        private const val EVENT_CHANNEL =
            "com.example.background_notif/events"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ---------------------------------------------------------
        // Method Channel
        // ---------------------------------------------------------

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "openNotificationSettings" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS
                        )

                        startActivity(intent)

                        result.success(true)

                    } catch (e: Exception) {
                        result.error(
                            "SETTINGS_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                "getSavedNotifications" -> {
                    try {
                        result.success(
                            getSavedNotifications()
                        )
                    } catch (e: Exception) {
                        result.error(
                            "READ_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        // ---------------------------------------------------------
        // Event Channel
        // ---------------------------------------------------------

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(
            object : EventChannel.StreamHandler {

                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?
                ) {
                    NotificationListenerService.eventSink = events
                }

                override fun onCancel(
                    arguments: Any?
                ) {
                    NotificationListenerService.eventSink = null
                }
            }
        )
    }

    private fun getSavedNotifications(): List<Map<String, Any>> {

        val directory = File(
            filesDir,
            "notifications"
        )

        if (!directory.exists()) {
            return emptyList()
        }

        return directory
            .listFiles()
            ?.filter {
                it.isFile && it.extension == "json"
            }
            ?.sortedByDescending {
                it.lastModified()
            }
            ?.mapNotNull { file ->

                try {
                    val json =
                        JSONObject(file.readText())

                    mapOf(
                        "packageName" to json.optString(
                            "packageName",
                            ""
                        ),

                        "tag" to json.optString(
                            "tag",
                            ""
                        ),

                        "title" to json.optString(
                            "title",
                            ""
                        ),

                        "text" to json.optString(
                            "text",
                            ""
                        ),

                        "bigText" to json.optString(
                            "bigText",
                            ""
                        ),

                        "timestamp" to json.optLong(
                            "timestamp",
                            0L
                        )
                    )

                } catch (e: Exception) {
                    null
                }
            }
            ?: emptyList()
    }
}