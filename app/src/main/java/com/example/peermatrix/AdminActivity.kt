package com.example.peermatrix

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.GridLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast

class AdminActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showAdminDashboard()
    }

    private fun showAdminDashboard() {
        val scrollView = ScrollView(this)
        scrollView.isFillViewport = true
        scrollView.setBackgroundColor(Color.parseColor("#F8FBFF"))

        val root = LinearLayout(this)
        root.orientation = LinearLayout.VERTICAL
        root.setPadding(dp(20), dp(24), dp(20), dp(40))

        // 1. Header Row
        val header = LinearLayout(this)
        header.orientation = LinearLayout.HORIZONTAL
        header.gravity = Gravity.CENTER_VERTICAL
        header.setPadding(0, 0, 0, dp(28))

        val title = TextView(this)
        title.text = "Admin Panel"
        title.textSize = 26f
        title.typeface = Typeface.DEFAULT_BOLD
        title.setTextColor(Color.parseColor("#1E1B4B"))
        val titleParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        title.layoutParams = titleParams

        val badgeBox = View(this)
        val badgeBg = GradientDrawable()
        badgeBg.setColor(Color.WHITE)
        badgeBg.shape = GradientDrawable.OVAL
        badgeBox.background = badgeBg
        badgeBox.elevation = dp(4).toFloat()

        val badgeIcon = AdminShieldIcon(this)
        val badgeParams = LinearLayout.LayoutParams(dp(48), dp(48))
        badgeBox.layoutParams = badgeParams
        
        // Wrap badge icon in the white circle
        val iconWrapper = LinearLayout(this)
        iconWrapper.gravity = Gravity.CENTER
        iconWrapper.background = badgeBg
        iconWrapper.elevation = dp(4).toFloat()
        iconWrapper.addView(badgeIcon, LinearLayout.LayoutParams(dp(24), dp(24)))
        
        header.addView(title)
        header.addView(iconWrapper, LinearLayout.LayoutParams(dp(54), dp(54)))
        root.addView(header)

        // 2. Hero Section (Gradient Card)
        val heroCard = LinearLayout(this)
        heroCard.orientation = LinearLayout.VERTICAL
        heroCard.setPadding(dp(28), dp(32), dp(28), dp(32))
        
        val heroBg = GradientDrawable(
            GradientDrawable.Orientation.LEFT_RIGHT,
            intArrayOf(Color.parseColor("#6366F1"), Color.parseColor("#A855F7"))
        )
        heroBg.cornerRadius = dp(32).toFloat()
        heroCard.background = heroBg
        heroCard.elevation = dp(8).toFloat()

        val welcomeText = TextView(this)
        welcomeText.text = "Welcome, Admin"
        welcomeText.textSize = 28f
        welcomeText.typeface = Typeface.DEFAULT_BOLD
        welcomeText.setTextColor(Color.WHITE)

        val subHeroText = TextView(this)
        subHeroText.text = "System overview and management"
        subHeroText.textSize = 15f
        subHeroText.setTextColor(Color.parseColor("#E0E7FF"))
        subHeroText.setPadding(0, dp(8), 0, 0)

        heroCard.addView(welcomeText)
        heroCard.addView(subHeroText)
        
        val heroParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        heroParams.setMargins(0, 0, 0, dp(32))
        root.addView(heroCard, heroParams)

        // 3. Grid Menu
        val grid = GridLayout(this)
        grid.columnCount = 2
        grid.rowCount = 2
        grid.alignmentMode = GridLayout.ALIGN_BOUNDS
        
        val cardWidth = (resources.displayMetrics.widthPixels - dp(64)) / 2

        // Card 1: Manage Users
        val userCard = createMenuCard("Manage Users", "#3B82F6", UserMenuIcon(this), cardWidth)
        userCard.setOnClickListener {
            startActivity(Intent(this, AdminUserActivity::class.java))
        }

        // Card 2: Subjects
        val subjectsCard = createMenuCard("Subjects", "#8B5CF6", BookMenuIcon(this), cardWidth)
        subjectsCard.setOnClickListener {
            startActivity(Intent(this, AdminSubjectActivity::class.java))
        }

        // Card 3: Reports
        val reportsCard = createMenuCard("Reports", "#10B981", ReportMenuIcon(this), cardWidth)
        reportsCard.setOnClickListener {
            startActivity(Intent(this, AdminReportsActivity::class.java))
        }

        // Card 4: Logout
        val logoutCard = createMenuCard("Logout", "#475569", LogoutMenuIcon(this), cardWidth)
        logoutCard.setOnClickListener {
            android.app.AlertDialog.Builder(this)
                .setTitle("Logout")
                .setMessage("Are you sure want to logout?")
                .setPositiveButton("Confirm") { _, _ ->
                    val intent = Intent(this, MainActivity::class.java)
                    intent.putExtra("fromLogout", true)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    startActivity(intent)
                    finish()
                }
                .setNegativeButton("Cancel", null)
                .show()
        }

        grid.addView(userCard)
        grid.addView(subjectsCard)
        grid.addView(reportsCard)
        grid.addView(logoutCard)

        root.addView(grid)

        scrollView.addView(root)
        setContentView(scrollView)
    }

    private fun createMenuCard(label: String, iconColor: String, iconView: View, width: Int): LinearLayout {
        val card = LinearLayout(this)
        card.orientation = LinearLayout.VERTICAL
        card.gravity = Gravity.CENTER
        card.setPadding(dp(16), dp(32), dp(16), dp(32))
        
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(28).toFloat()
        card.background = bg
        card.elevation = dp(6).toFloat()

        val params = GridLayout.LayoutParams()
        params.width = width
        params.height = ViewGroup.LayoutParams.WRAP_CONTENT
        params.setMargins(dp(6), dp(6), dp(6), dp(6))
        card.layoutParams = params

        // Icon Circle
        val iconCircle = LinearLayout(this)
        iconCircle.gravity = Gravity.CENTER
        val circleBg = GradientDrawable()
        circleBg.setColor(adjustAlpha(Color.parseColor(iconColor), 0.1f))
        circleBg.shape = GradientDrawable.OVAL
        iconCircle.background = circleBg
        
        val iconCircleParams = LinearLayout.LayoutParams(dp(68), dp(68))
        iconCircle.addView(iconView, LinearLayout.LayoutParams(dp(32), dp(32)))
        
        card.addView(iconCircle, iconCircleParams)

        val text = TextView(this)
        text.text = label
        text.textSize = 17f
        text.typeface = Typeface.DEFAULT_BOLD
        text.setTextColor(Color.parseColor("#0F172A"))
        text.setPadding(0, dp(20), 0, 0)
        
        card.addView(text)

        return card
    }

    private fun adjustAlpha(color: Int, factor: Float): Int {
        val alpha = Math.round(Color.alpha(color) * factor)
        val red = Color.red(color)
        val green = Color.green(color)
        val blue = Color.blue(color)
        return Color.argb(alpha, red, green, blue)
    }

    private fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
    }

    private fun dpf(value: Float): Float {
        return value * resources.displayMetrics.density
    }

    private fun toast(text: String) {
        Toast.makeText(this, text, Toast.LENGTH_SHORT).show()
    }

    // Custom Icons
    inner class AdminShieldIcon(context: Context) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        override fun onDraw(canvas: Canvas) {
            val w = width.toFloat()
            val h = height.toFloat()
            paint.color = Color.parseColor("#1E1B4B")
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = dp(2).toFloat()
            val path = Path()
            path.moveTo(w * 0.5f, h * 0.1f)
            path.lineTo(w * 0.9f, h * 0.25f)
            path.lineTo(w * 0.9f, h * 0.6f)
            path.quadTo(w * 0.9f, h * 0.85f, w * 0.5f, h * 0.95f)
            path.quadTo(w * 0.1f, h * 0.85f, w * 0.1f, h * 0.6f)
            path.lineTo(w * 0.1f, h * 0.25f)
            path.close()
            canvas.drawPath(path, paint)
            val check = Path()
            check.moveTo(w * 0.35f, h * 0.55f)
            check.lineTo(w * 0.45f, h * 0.65f)
            check.lineTo(w * 0.65f, h * 0.45f)
            canvas.drawPath(check, paint)
        }
    }

    inner class UserMenuIcon(context: Context) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        override fun onDraw(canvas: Canvas) {
            paint.color = Color.parseColor("#3B82F6")
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = dpf(2.5f)
            val w = width.toFloat()
            val h = height.toFloat()
            canvas.drawCircle(w * 0.5f, h * 0.35f, w * 0.2f, paint)
            val rect = RectF(w * 0.2f, h * 0.65f, w * 0.8f, h * 0.95f)
            canvas.drawArc(rect, 180f, 180f, false, paint)
        }
    }

    inner class TeacherMenuIcon(context: Context) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        override fun onDraw(canvas: Canvas) {
            paint.color = Color.parseColor("#EC4899")
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = dpf(2.5f)
            val w = width.toFloat()
            val h = height.toFloat()
            
            // Mortarboard (cap)
            val path = Path()
            path.moveTo(w * 0.1f, h * 0.4f)
            path.lineTo(w * 0.5f, h * 0.2f)
            path.lineTo(w * 0.9f, h * 0.4f)
            path.lineTo(w * 0.5f, h * 0.6f)
            path.close()
            canvas.drawPath(path, paint)
            
            // Bottom part of cap
            val rect = RectF(w * 0.3f, h * 0.5f, w * 0.7f, h * 0.7f)
            canvas.drawArc(rect, 0f, 180f, false, paint)
            
            // Tassel
            canvas.drawLine(w * 0.9f, h * 0.4f, w * 0.9f, h * 0.7f, paint)
            canvas.drawCircle(w * 0.9f, h * 0.75f, dpf(2f), paint)
        }
    }

    inner class BookMenuIcon(context: Context) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        override fun onDraw(canvas: Canvas) {
            paint.color = Color.parseColor("#8B5CF6")
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = dpf(2.5f)
            val w = width.toFloat()
            val h = height.toFloat()
            canvas.drawRoundRect(w * 0.2f, h * 0.2f, w * 0.8f, h * 0.8f, dp(4).toFloat(), dp(4).toFloat(), paint)
            canvas.drawLine(w * 0.35f, h * 0.4f, w * 0.65f, h * 0.4f, paint)
            canvas.drawLine(w * 0.35f, h * 0.6f, w * 0.65f, h * 0.6f, paint)
        }
    }

    inner class ReportMenuIcon(context: Context) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        override fun onDraw(canvas: Canvas) {
            paint.color = Color.parseColor("#10B981")
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = dpf(2.5f)
            val w = width.toFloat()
            val h = height.toFloat()
            val path = Path()
            path.moveTo(w * 0.2f, h * 0.1f)
            path.lineTo(w * 0.6f, h * 0.1f)
            path.lineTo(w * 0.8f, h * 0.3f)
            path.lineTo(w * 0.8f, h * 0.9f)
            path.lineTo(w * 0.2f, h * 0.9f)
            path.close()
            canvas.drawPath(path, paint)
            canvas.drawLine(w * 0.35f, h * 0.45f, w * 0.65f, h * 0.45f, paint)
            canvas.drawLine(w * 0.35f, h * 0.6f, w * 0.65f, h * 0.6f, paint)
            canvas.drawLine(w * 0.35f, h * 0.75f, w * 0.55f, h * 0.75f, paint)
        }
    }

    inner class LogoutMenuIcon(context: Context) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        override fun onDraw(canvas: Canvas) {
            paint.color = Color.parseColor("#475569")
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = dpf(2.5f)
            val w = width.toFloat()
            val h = height.toFloat()
            val path = Path()
            path.moveTo(w * 0.5f, h * 0.2f)
            path.lineTo(w * 0.2f, h * 0.2f)
            path.lineTo(w * 0.2f, h * 0.8f)
            path.lineTo(w * 0.5f, h * 0.8f)
            canvas.drawPath(path, paint)
            canvas.drawLine(w * 0.4f, h * 0.5f, w * 0.85f, h * 0.5f, paint)
            val arrow = Path()
            arrow.moveTo(w * 0.7f, h * 0.35f)
            arrow.lineTo(w * 0.85f, h * 0.5f)
            arrow.lineTo(w * 0.7f, h * 0.65f)
            canvas.drawPath(arrow, paint)
        }
    }
}