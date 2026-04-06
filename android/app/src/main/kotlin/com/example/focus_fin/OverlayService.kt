package com.example.focus_fin

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class OverlayService : Service() {

    private lateinit var windowManager: WindowManager
    private var overlayView: View? = null

    companion object {
        const val EXTRA_SENDER    = "sender"
        const val EXTRA_BODY      = "body"
        const val EXTRA_AMOUNT    = "amount"
        const val EXTRA_TYPE      = "type"
        const val EXTRA_TIMESTAMP = "timestamp"

        private const val ENGINE_ID        = "focusfin_sms_engine"
        private const val CHANNEL_NAME     = "com.focusfin.sms/receiver"
        private const val PREFS_NAME       = "FlutterSharedPreferences"
        private const val KEY_CAT_QUEUE    = "flutter.category_queue"
        private const val NOTIF_CHANNEL_ID = "focusfin_overlay"

        val CATEGORIES = listOf(
            "Food", "Travel", "Petrol", "Shopping", "Education",
            "Entertainment", "Bills", "Individual", "Events", "Groceries", "Others"
        )

        fun start(
            context: Context,
            sender: String, body: String,
            amount: String, type: String,
            timestamp: Long
        ) {
            val intent = Intent(context, OverlayService::class.java).apply {
                putExtra(EXTRA_SENDER,    sender)
                putExtra(EXTRA_BODY,      body)
                putExtra(EXTRA_AMOUNT,    amount)
                putExtra(EXTRA_TYPE,      type)
                putExtra(EXTRA_TIMESTAMP, timestamp)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        startForegroundWithNotification()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val sender    = intent?.getStringExtra(EXTRA_SENDER)    ?: return START_NOT_STICKY
        val body      = intent.getStringExtra(EXTRA_BODY)       ?: ""
        val amount    = intent.getStringExtra(EXTRA_AMOUNT)     ?: "?"
        val txType    = intent.getStringExtra(EXTRA_TYPE)       ?: "debited"
        val timestamp = intent.getLongExtra(EXTRA_TIMESTAMP, System.currentTimeMillis())

        showOverlay(sender, body, amount, txType, timestamp)
        return START_NOT_STICKY
    }

    private fun showOverlay(
        sender: String, body: String,
        amount: String, type: String,
        timestamp: Long
    ) {
        dismissOverlay()

        val dp = { v: Int ->
            TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics
            ).toInt()
        }

        val isCredit    = type == "credited"
        val typeColor   = if (isCredit) "#1B8A4E" else "#C0392B"
        val typeBgColor = if (isCredit) "#E6F4EE" else "#FDECEA"

        // ── Root card ──────────────────────────────────────────────────────
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(10), dp(16), dp(20))
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadii = floatArrayOf(
                    dp(18).toFloat(), dp(18).toFloat(),
                    dp(18).toFloat(), dp(18).toFloat(),
                    0f, 0f, 0f, 0f
                )
            }
        }

        // ── Handle ─────────────────────────────────────────────────────────
        val handle = View(this).apply {
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#DDDDDD"))
                cornerRadius = dp(2).toFloat()
            }
        }
        card.addView(handle, LinearLayout.LayoutParams(dp(32), dp(3)).apply {
            gravity = Gravity.CENTER_HORIZONTAL
            bottomMargin = dp(10)
        })

        // ── Amount + sender row ────────────────────────────────────────────
        val topRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        // Left: pill + amount stacked
        val leftCol = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        val pill = TextView(this).apply {
            text = type.uppercase()
            setTextColor(Color.parseColor(typeColor))
            textSize = 9f
            setPadding(dp(7), dp(2), dp(7), dp(2))
            background = GradientDrawable().apply {
                setColor(Color.parseColor(typeBgColor))
                cornerRadius = dp(20).toFloat()
            }
        }
        leftCol.addView(pill, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { marginEnd = dp(8) })

        val amountView = TextView(this).apply {
            text = "₹$amount"
            setTextColor(Color.parseColor(typeColor))
            textSize = 20f
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        leftCol.addView(amountView, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ))

        topRow.addView(leftCol, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))

        // Right: sender name
        val senderView = TextView(this).apply {
            text = sender
            setTextColor(Color.parseColor("#AAAAAA"))
            textSize = 11f
            gravity = Gravity.END
        }
        topRow.addView(senderView, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ))

        card.addView(topRow, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { bottomMargin = dp(12) })

        // ── Prompt ─────────────────────────────────────────────────────────
        val prompt = TextView(this).apply {
            text = "What was this for?"
            setTextColor(Color.parseColor("#333333"))
            textSize = 12f
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        card.addView(prompt, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { bottomMargin = dp(8) })

        // ── Horizontal scrolling chips ─────────────────────────────────────
        val scrollView = HorizontalScrollView(this).apply {
            isHorizontalScrollBarEnabled = false
            overScrollMode = View.OVER_SCROLL_NEVER
        }

        val chipRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, dp(2), 0, dp(4))
        }

        CATEGORIES.forEach { category ->
            val chip = TextView(this).apply {
                text = category
                textSize = 12f
                setTextColor(Color.parseColor("#333333"))
                setPadding(dp(14), dp(7), dp(14), dp(7))
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#F4F4F4"))
                    cornerRadius = dp(20).toFloat()
                    setStroke(dp(1), Color.parseColor("#E0E0E0"))
                }
                setOnClickListener {
                    // Visual feedback — darken chip briefly
                    background = GradientDrawable().apply {
                        setColor(Color.parseColor("#E8E8E8"))
                        cornerRadius = dp(20).toFloat()
                        setStroke(dp(1), Color.parseColor("#CCCCCC"))
                    }
                    onCategorySelected(sender, body, amount, type, timestamp, category)
                    dismissOverlay()
                    stopSelf()
                }
            }
            chipRow.addView(chip, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { marginEnd = dp(8) })
        }

        scrollView.addView(chipRow)
        card.addView(scrollView, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { bottomMargin = dp(8) })

        // ── Dismiss ────────────────────────────────────────────────────────
        val dismiss = TextView(this).apply {
            text = "Dismiss"
            setTextColor(Color.parseColor("#BBBBBB"))
            textSize = 11f
            gravity = Gravity.CENTER
            setOnClickListener { dismissOverlay(); stopSelf() }
        }
        card.addView(dismiss, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ))

        // ── WindowManager params ───────────────────────────────────────────
        val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayType,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.BOTTOM
        }

        overlayView = card
        windowManager.addView(card, params)
    }

    private fun onCategorySelected(
        sender: String, body: String,
        amount: String, type: String,
        timestamp: Long, category: String
    ) {
        val engine  = FlutterEngineCache.getInstance().get(ENGINE_ID)
        val isAlive = engine != null && engine.dartExecutor.isExecutingDart

        if (isAlive) {
            val args = mapOf(
                "sender"    to sender,
                "body"      to body,
                "amount"    to amount,
                "type"      to type,
                "timestamp" to timestamp,
                "category"  to category
            )
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                MethodChannel(engine!!.dartExecutor.binaryMessenger, CHANNEL_NAME)
                    .invokeMethod("onCategorySelected", args)
            }
        } else {
            saveToQueue(sender, body, amount, type, timestamp, category)
        }
    }

    private fun saveToQueue(
        sender: String, body: String,
        amount: String, type: String,
        timestamp: Long, category: String
    ) {
        try {
            val prefs    = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val existing = JSONArray(prefs.getString(KEY_CAT_QUEUE, "[]"))
            existing.put(JSONObject().apply {
                put("sender",    sender)
                put("body",      body)
                put("amount",    amount)
                put("type",      type)
                put("timestamp", timestamp)
                put("category",  category)
            })
            prefs.edit().putString(KEY_CAT_QUEUE, existing.toString()).apply()
        } catch (e: Exception) {
            android.util.Log.e("OverlayService", "❌ Failed to save to queue: ${e.message}")
        }
    }

    private fun dismissOverlay() {
        overlayView?.let {
            try { windowManager.removeView(it) } catch (_: Exception) {}
            overlayView = null
        }
    }

    private fun startForegroundWithNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIF_CHANNEL_ID,
                "FocusFin Overlay",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
        val notif = NotificationCompat.Builder(this, NOTIF_CHANNEL_ID)
            .setContentTitle("FocusFin")
            .setContentText("Categorize your transaction")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        startForeground(1001, notif)
    }

    override fun onDestroy() {
        dismissOverlay()
        super.onDestroy()
    }
}