package com.example.focus_fin

import android.app.Notification
import android.content.Context
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class SmsBroadcastReceiver : NotificationListenerService() {

    companion object {
        private const val TAG            = "SmsBroadcastReceiver"
        private const val CHANNEL_NAME   = "com.focusfin.sms/receiver"
        private const val ENGINE_ID      = "focusfin_sms_engine"
        private const val PREFS_NAME     = "FlutterSharedPreferences"
        private const val KEY_SENDER_IDS = "flutter.selected_sender_ids"
        private const val KEY_MISSED_QUEUE = "flutter.missed_sms_queue"

        private val ALLOWED_SMS_PACKAGES = listOf(
            "com.google.android.apps.messaging",
            "com.samsung.android.messaging",
            "com.android.mms",
            "com.oneplus.mms",
            "com.miui.smsextra"
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        val extras      = sbn.notification.extras

        if (!ALLOWED_SMS_PACKAGES.contains(packageName)) return

        val senderTitle = extras.getString(Notification.EXTRA_TITLE) ?: "Unknown"
        val messageBody = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

        if (messageBody.trim().isEmpty() || sbn.isOngoing) return

        Log.d(TAG, "🔔 SMS caught from: $senderTitle (via $packageName)")

        val allowedSenders = getSelectedSenderIds(applicationContext)
        if (allowedSenders.isEmpty()) return

        val cleanSender = senderTitle.replace(" ", "").uppercase()
        val isAllowed = allowedSenders.any { allowedId ->
            val cleanAllowed = allowedId.replace(" ", "").uppercase()
            cleanSender.contains(cleanAllowed) || cleanAllowed.contains(cleanSender)
        }

        if (!isAllowed) return

        Log.d(TAG, "✅ Match found for '$senderTitle'! Routing...")
        sendToFlutterOrQueue(applicationContext, senderTitle, messageBody, sbn.postTime)
    }

    private fun getSelectedSenderIds(context: Context): List<String> {
        return try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val json  = prefs.getString(KEY_SENDER_IDS, null) ?: return emptyList()
            val arr   = JSONArray(json)
            List(arr.length()) { arr.getString(it) }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun sendToFlutterOrQueue(
        context: Context, sender: String,
        body: String, timestamp: Long
    ) {
        val amount = extractAmount(body) ?: "?"
        val type   = if (body.lowercase().contains("credit")) "credited" else "debited"

        if (Settings.canDrawOverlays(context)) {
            // Overlay will handle everything — category selection + routing to Flutter
            // Do NOT pre-queue here to avoid double-processing
            Log.d(TAG, "📲 Overlay permission granted — launching OverlayService.")
            OverlayService.start(context, sender, body, amount, type, timestamp)
        } else {
            // No overlay permission — queue raw SMS and try live delivery without category
            Log.d(TAG, "⚠️ No overlay permission — falling back to raw SMS queue.")
            saveToQueue(context, sender, body, timestamp)

            val engine        = FlutterEngineCache.getInstance().get(ENGINE_ID)
            val isEngineAlive = engine != null && engine.dartExecutor.isExecutingDart

            if (isEngineAlive) {
                val args = mapOf("sender" to sender, "body" to body, "timestamp" to timestamp)
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    MethodChannel(engine!!.dartExecutor.binaryMessenger, CHANNEL_NAME)
                        .invokeMethod("onSmSReceived", args, object : MethodChannel.Result {
                            override fun success(result: Any?) {
                                removeFromQueue(context, timestamp)
                            }
                            override fun error(c: String, m: String?, d: Any?) {
                                Log.e(TAG, "❌ Live delivery failed: $m")
                            }
                            override fun notImplemented() {
                                Log.e(TAG, "❌ onSmSReceived not implemented in Flutter.")
                            }
                        })
                }
            }
        }
    }

    private fun extractAmount(body: String): String? {
        val pattern = Regex("""(?:INR|Rs\.?|₹)\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE)
        return pattern.find(body)?.groupValues?.get(1)?.replace(",", "")
    }

    private fun saveToQueue(context: Context, sender: String, body: String, timestamp: Long) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val queue = JSONArray(prefs.getString(KEY_MISSED_QUEUE, "[]"))
            queue.put(JSONObject().apply {
                put("sender",    sender)
                put("body",      body)
                put("timestamp", timestamp)
            })
            prefs.edit().putString(KEY_MISSED_QUEUE, queue.toString()).apply()
            Log.d(TAG, "📥 Saved to raw queue. Total: ${queue.length()}")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to queue SMS: ${e.message}")
        }
    }

    private fun removeFromQueue(context: Context, timestamp: Long) {
        try {
            val prefs    = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val queue    = JSONArray(prefs.getString(KEY_MISSED_QUEUE, "[]"))
            val newQueue = JSONArray()
            for (i in 0 until queue.length()) {
                val item = queue.getJSONObject(i)
                if (item.getLong("timestamp") != timestamp) newQueue.put(item)
            }
            prefs.edit().putString(KEY_MISSED_QUEUE, newQueue.toString()).apply()
            Log.d(TAG, "🗑️ Removed from queue. Remaining: ${newQueue.length()}")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to remove from queue: ${e.message}")
        }
    }
}