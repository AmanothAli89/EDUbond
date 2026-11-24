package com.example.peermatrix

import android.app.Activity
import android.content.Context
import android.graphics.*
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import java.text.SimpleDateFormat
import java.util.*

class AdminReportsActivity : Activity() {

    private lateinit var db: FirebaseFirestore
    private lateinit var contentLayout: LinearLayout
    private lateinit var totalUsersTv: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        db = FirebaseFirestore.getInstance()
        setupUI()
        loadData()
    }

    private fun setupUI() {
        val scrollView = ScrollView(this)
        scrollView.isFillViewport = true
        scrollView.setBackgroundColor(Color.parseColor("#F8FBFF"))

        val root = LinearLayout(this)
        root.orientation = LinearLayout.VERTICAL
        root.setPadding(dp(20), dp(24), dp(20), dp(40))

        // Header
        val header = LinearLayout(this)
        header.orientation = LinearLayout.HORIZONTAL
        header.gravity = Gravity.CENTER_VERTICAL
        header.setPadding(0, 0, 0, dp(24))

        val backBtn = TextView(this)
        backBtn.text = "←"
        backBtn.textSize = 24f
        backBtn.setTextColor(Color.parseColor("#1E1B4B"))
        backBtn.setPadding(0, 0, dp(16), 0)
        backBtn.setOnClickListener { finish() }

        val title = TextView(this)
        title.text = "System Reports"
        title.textSize = 24f
        title.typeface = Typeface.DEFAULT_BOLD
        title.setTextColor(Color.parseColor("#1E1B4B"))

        header.addView(backBtn)
        header.addView(title)
        root.addView(header)

        // Total Users Card
        val totalCard = createStatCard("Total Users", "0")
        totalUsersTv = totalCard.second
        root.addView(totalCard.first)

        // Graphs Container
        contentLayout = LinearLayout(this)
        contentLayout.orientation = LinearLayout.VERTICAL
        root.addView(contentLayout)

        scrollView.addView(root)
        setContentView(scrollView)
    }

    private fun loadData() {
        // 1. Total Users
        db.collection("users").get().addOnSuccessListener { snapshot ->
            totalUsersTv.text = snapshot.size().toString()
        }

        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, -7)
        val weekAgo = calendar.timeInMillis

        // 2. New Users Weekly
        fetchWeeklyData("users", "updatedAt", weekAgo) { data ->
            runOnUiThread { addGraphSection("New Users (Weekly)", data, "#3B82F6") }
        }

        // 3. New Groups Weekly
        fetchWeeklyData("groups", "timestamp", weekAgo) { data ->
            runOnUiThread { addGraphSection("New Groups (Weekly)", data, "#10B981") }
        }

        // 4. New Teachers Weekly
        db.collection("user_roles")
            .whereEqualTo("role", "teacher")
            .whereGreaterThanOrEqualTo("timestamp", weekAgo)
            .get()
            .addOnSuccessListener { snapshot ->
                val counts = processSnapshotToWeeklyData(snapshot.documents.map { it.data!! }, "timestamp")
                runOnUiThread { addGraphSection("New Teachers (Weekly)", counts, "#8B5CF6") }
            }
    }

    private fun fetchWeeklyData(collection: String, timestampField: String, since: Long, onResult: (Map<String, Int>) -> Unit) {
        db.collection(collection)
            .whereGreaterThanOrEqualTo(timestampField, since)
            .get()
            .addOnSuccessListener { snapshot ->
                val dataList = snapshot.documents.mapNotNull { it.data }
                val counts = processSnapshotToWeeklyData(dataList, timestampField)
                onResult(counts)
            }
            .addOnFailureListener { onResult(emptyMap()) }
    }

    private fun processSnapshotToWeeklyData(dataList: List<Map<String, Any>>, timestampField: String): Map<String, Int> {
        val counts = mutableMapOf<String, Int>()
        val sdf = SimpleDateFormat("EEE", Locale.getDefault())
        
        // Initialize last 7 days with 0
        val cal = Calendar.getInstance()
        for (i in 0 until 7) {
            counts[sdf.format(cal.time)] = 0
            cal.add(Calendar.DAY_OF_YEAR, -1)
        }

        for (data in dataList) {
            val ts = data[timestampField]
            val date = when (ts) {
                is Long -> Date(ts)
                is com.google.firebase.Timestamp -> ts.toDate()
                else -> null
            }
            if (date != null) {
                val day = sdf.format(date)
                counts[day] = (counts[day] ?: 0) + 1
            }
        }
        return counts
    }

    private fun addGraphSection(title: String, data: Map<String, Int>, color: String) {
        val section = LinearLayout(this)
        section.orientation = LinearLayout.VERTICAL
        section.setPadding(0, dp(24), 0, 0)

        val titleTv = TextView(this)
        titleTv.text = title
        titleTv.textSize = 18f
        titleTv.typeface = Typeface.DEFAULT_BOLD
        titleTv.setTextColor(Color.parseColor("#1E1B4B"))
        titleTv.setPadding(0, 0, 0, dp(12))
        section.addView(titleTv)

        val graphCard = LinearLayout(this)
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(24).toFloat()
        graphCard.background = bg
        graphCard.elevation = dp(4).toFloat()
        graphCard.setPadding(dp(16), dp(16), dp(16), dp(16))
        
        val chart = WeeklyBarChartView(this, data, Color.parseColor(color))
        graphCard.addView(chart, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(200)))
        
        section.addView(graphCard)
        contentLayout.addView(section)
    }

    private fun createStatCard(label: String, value: String): Pair<LinearLayout, TextView> {
        val card = LinearLayout(this)
        card.orientation = LinearLayout.VERTICAL
        card.setPadding(dp(24), dp(24), dp(24), dp(24))
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(24).toFloat()
        card.background = bg
        card.elevation = dp(4).toFloat()

        val labelTv = TextView(this)
        labelTv.text = label
        labelTv.textSize = 14f
        labelTv.setTextColor(Color.parseColor("#64748B"))

        val valTv = TextView(this)
        valTv.text = value
        valTv.textSize = 32f
        valTv.typeface = Typeface.DEFAULT_BOLD
        valTv.setTextColor(Color.parseColor("#0061FF"))
        valTv.setPadding(0, dp(4), 0, 0)

        card.addView(labelTv)
        card.addView(valTv)
        
        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(16))
        card.layoutParams = params
        
        return Pair(card, valTv)
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    inner class WeeklyBarChartView(context: Context, val data: Map<String, Int>, val barColor: Int) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textSize = dp(10).toFloat()
            textAlign = Paint.Align.CENTER
            color = Color.parseColor("#94A3B8")
        }

        override fun onDraw(canvas: Canvas) {
            val w = width.toFloat()
            val h = height.toFloat()
            val padding = dp(20).toFloat()
            val graphH = h - padding * 2
            val graphW = w - padding * 2

            val sdf = SimpleDateFormat("EEE", Locale.getDefault())
            val days = mutableListOf<String>()
            val cal = Calendar.getInstance()
            cal.add(Calendar.DAY_OF_YEAR, -6)
            for (i in 0 until 7) {
                days.add(sdf.format(cal.time))
                cal.add(Calendar.DAY_OF_YEAR, 1)
            }

            val maxVal = data.values.maxOrNull()?.coerceAtLeast(5) ?: 5
            val barWidth = graphW / 14f
            val spacing = graphW / 7f

            paint.color = barColor
            
            for ((i, day) in days.withIndex()) {
                val count = data[day] ?: 0
                val barH = (count.toFloat() / maxVal) * graphH
                val left = padding + i * spacing + barWidth
                val top = h - padding - barH
                val right = left + barWidth
                val bottom = h - padding
                
                // Draw Bar
                val rect = RectF(left, top, right, bottom)
                canvas.drawRoundRect(rect, dp(4).toFloat(), dp(4).toFloat(), paint)
                
                // Draw Label
                canvas.drawText(day, left + barWidth / 2, h - dp(4).toFloat(), textPaint)
                
                // Draw Count on Top
                if (count > 0) {
                    canvas.drawText(count.toString(), left + barWidth / 2, top - dp(4).toFloat(), textPaint)
                }
            }

            // Draw Base Line
            paint.color = Color.parseColor("#E2E8F0")
            paint.strokeWidth = dp(1).toFloat()
            canvas.drawLine(padding, h - padding, w - padding, h - padding, paint)
        }
    }
}
