package com.example.focus_fin

import android.content.Context
import android.content.Intent
import android.util.Log
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val ENGINE_CHANNEL   = "com.focusfin.sms/engine"
    private val SMS_CHANNEL      = "com.focusfin.sms/receiver"
    private val SETTINGS_CHANNEL = "com.focusfin/settings"
    private val ENGINE_ID        = "focusfin_sms_engine"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Cache the engine so SmsBroadcastReceiver can reuse it
        FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine)

        // 1. Engine registration channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ENGINE_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "cacheEngine") {
                    val engineId = call.argument<String>("engineId") ?: ENGINE_ID
                    FlutterEngineCache.getInstance().put(engineId, flutterEngine)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }

        // 2. SMS channel — handles getSmsFromSender called by Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSmsFromSender" -> {
                        val sender = call.argument<String>("sender") ?: ""
                        val limit  = call.argument<Int>("limit") ?: 50

                        try {
                            val messages = mutableListOf<Map<String, Any?>>()
                            val uri = Uri.parse("content://sms/inbox")

                            val cursor = contentResolver.query(
                                uri,
                                arrayOf("address", "body", "date"),
                                "address LIKE ?",
                                arrayOf("%$sender%"),
                                "date DESC"
                            )

                            cursor?.use {
                                var count = 0
                                while (it.moveToNext() && count < limit) {
                                    messages.add(
                                        mapOf(
                                            "sender"    to (it.getString(it.getColumnIndexOrThrow("address")) ?: ""),
                                            "body"      to (it.getString(it.getColumnIndexOrThrow("body")) ?: ""),
                                            "timestamp" to it.getLong(it.getColumnIndexOrThrow("date"))
                                        )
                                    )
                                    count++
                                }
                            }

                            result.success(messages)
                        } catch (e: Exception) {
                            result.error("SMS_READ_ERROR", e.message, null)
                        }
                    }

                    // ─── NEW: FLUTTER ASKING FOR MISSED MESSAGES ───
                    "getAndClearMissedSmsQueue" -> {
                        try {
                            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                            val json = prefs.getString("flutter.missed_sms_queue", "[]")

                            // Convert the JSON array into a List of Maps so Flutter understands it
                            val messagesList = mutableListOf<Map<String, Any>>()
                            if (json != null && json != "[]") {
                                val arr = org.json.JSONArray(json)
                                for (i in 0 until arr.length()) {
                                    val obj = arr.getJSONObject(i)
                                    messagesList.add(mapOf(
                                        "sender" to obj.getString("sender"),
                                        "body" to obj.getString("body"),
                                        "timestamp" to obj.getLong("timestamp")
                                    ))
                                }
                            }

                            // Clear the queue so we don't process them twice
                            prefs.edit().remove("flutter.missed_sms_queue").apply()

                            Log.d("MainActivity", "📤 Sent ${messagesList.size} queued messages to Flutter.")
                            result.success(messagesList)

                        } catch (e: Exception) {
                            result.error("QUEUE_ERROR", "Failed to get queue: ${e.message}", null)
                        }
                    }

                    "getAndClearCategoryQueue" -> {
                        try {
                            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                            val json = prefs.getString("flutter.category_queue", "[]")
                            val list = mutableListOf<Map<String, Any>>()

                            if (!json.isNullOrEmpty() && json != "[]") {
                                val arr = org.json.JSONArray(json)
                                for (i in 0 until arr.length()) {
                                    val obj = arr.getJSONObject(i)
                                    list.add(mapOf(
                                        "sender"    to obj.getString("sender"),
                                        "body"      to obj.getString("body"),
                                        "amount"    to obj.getString("amount"),
                                        "type"      to obj.getString("type"),
                                        "timestamp" to obj.getLong("timestamp"),
                                        "category"  to obj.getString("category")
                                    ))
                                }
                            }

                            prefs.edit().remove("flutter.category_queue").apply()
                            result.success(list)
                        } catch (e: Exception) {
                            result.error("CAT_QUEUE_ERROR", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        // 3. Settings channel — Handles opening & checking the Notification Access settings
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SETTINGS_ERROR", "Failed to open settings: ${e.message}", null)
                        }
                    }
                    "checkPermission" -> {
                        val enabledListeners = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
                        val isGranted = enabledListeners != null && enabledListeners.contains(packageName)
                        result.success(isGranted)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}