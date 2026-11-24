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
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore

class UserHomeActivity : Activity() {

    private lateinit var auth: FirebaseAuth
    private lateinit var db: FirebaseFirestore
    private lateinit var welcomeTitle: TextView
    private lateinit var profileBadge: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        auth = FirebaseAuth.getInstance()
        db = FirebaseFirestore.getInstance()

        val firebaseUser = auth.currentUser
        if (firebaseUser == null) {
            AppStorage.logout(this)
            goToLoginPage()
            return
        }

        val email = firebaseUser.email ?: ""
        if (email.isEmpty()) {
            auth.signOut()
            AppStorage.logout(this)
            goToLoginPage()
            return
        }

        AppStorage.setCurrentUser(this, email)
        showDashboard()
        
        val fallbackName = firebaseUser.displayName ?: email
        loadUserData(firebaseUser.uid, email, fallbackName)
    }

    private fun showDashboard() {
        val scrollView = ScrollView(this)
        scrollView.isFillViewport = true
        scrollView.setBackgroundColor(Color.parseColor("#F8FBFF"))

        val root = LinearLayout(this)
        root.orientation = LinearLayout.VERTICAL
        root.setPadding(dp(20), dp(24), dp(20), dp(40))

        // 1. Header
        val header = LinearLayout(this)
        header.orientation = LinearLayout.HORIZONTAL
        header.gravity = Gravity.CENTER_VERTICAL
        header.setPadding(0, 0, 0, dp(28))

        val title = TextView(this)
        title.text = "EduBond Dashboard"
        title.textSize = 24f
        title.typeface = Typeface.DEFAULT_BOLD
        title.setTextColor(Color.parseColor("#0061FF"))
        val titleParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        title.layoutParams = titleParams

        profileBadge = TextView(this)
        profileBadge.text = "??"
        profileBadge.textSize = 14f
        profileBadge.typeface = Typeface.DEFAULT_BOLD
        profileBadge.setTextColor(Color.WHITE)
        profileBadge.gravity = Gravity.CENTER
        
        val badgeBg = GradientDrawable()
        badgeBg.setColor(Color.parseColor("#93C5FD"))
        badgeBg.shape = GradientDrawable.OVAL
        profileBadge.background = badgeBg
        profileBadge.setOnClickListener {
            startActivity(Intent(this, UserProfileActivity::class.java))
        }
        
        header.addView(title)
        header.addView(profileBadge, LinearLayout.LayoutParams(dp(44), dp(44)))
        root.addView(header)

        // 2. Hero Card
        val heroCard = LinearLayout(this)
        heroCard.orientation = LinearLayout.VERTICAL
        heroCard.setPadding(dp(28), dp(32), dp(28), dp(32))
        
        val heroBg = GradientDrawable(
            GradientDrawable.Orientation.LEFT_RIGHT,
            intArrayOf(Color.parseColor("#1D4ED8"), Color.parseColor("#7C3AED"))
        )
        heroBg.cornerRadius = dp(32).toFloat()
        heroCard.background = heroBg
        heroCard.elevation = dp(8).toFloat()

        welcomeTitle = TextView(this)
        welcomeTitle.text = "Welcome, User"
        welcomeTitle.textSize = 28f
        welcomeTitle.typeface = Typeface.DEFAULT_BOLD
        welcomeTitle.setTextColor(Color.WHITE)

        val subHero = TextView(this)
        subHero.text = "Ready to learn together?"
        subHero.textSize = 16f
        subHero.setTextColor(Color.parseColor("#BFDBFE"))
        subHero.setPadding(0, dp(8), 0, 0)

        heroCard.addView(welcomeTitle)
        heroCard.addView(subHero)
        
        val heroParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        heroParams.setMargins(0, 0, 0, dp(32))
        root.addView(heroCard, heroParams)

        // 3. Grid Menu
        val grid = GridLayout(this)
        grid.columnCount = 2
        grid.rowCount = 2
        grid.alignmentMode = GridLayout.ALIGN_BOUNDS
        
        val cardWidth = (resources.displayMetrics.widthPixels - dp(64)) / 2

        // Card 1: Search & Learn
        val searchCard = createMenuCard("Search & Learn", "#2563EB", SearchIcon(this), cardWidth)
        searchCard.setOnClickListener {
            startActivity(Intent(this, SubjectActivity::class.java))
        }

        // Card 2: Group Requests
        val requestsCard = createMenuCard("Group Requests", "#7C3AED", UsersIcon(this), cardWidth)
        requestsCard.setOnClickListener {
            startActivity(Intent(this, RequestsActivity::class.java))
        }

        // Card 3: My Groups
        val groupsCard = createMenuCard("My Groups", "#059669", ChatIcon(this), cardWidth)
        groupsCard.setOnClickListener {
            startActivity(Intent(this, MyGroupsActivity::class.java))
        }

        // Card 4: Logout
        val logoutCard = createMenuCard("Logout", "#475569", LogoutIcon(this), cardWidth)
        logoutCard.setOnClickListener {
            android.app.AlertDialog.Builder(this)
                .setTitle("Logout")
                .setMessage("Are you sure want to logout?")
                .setPositiveButton("Confirm") { _, _ ->
                    auth.signOut()
                    AppStorage.logout(this)
                    goToLoginPage()
                }
                .setNegativeButton("Cancel", null)
                .show()
        }

        grid.addView(searchCard)
        grid.addView(requestsCard)
        grid.addView(groupsCard)
        grid.addView(logoutCard)

        root.addView(grid)

        scrollView.addView(root)
        setContentView(scrollView)
    }

    private fun loadUserData(uid: String, email: String, fallbackName: String) {
        profileBadge.text = (if (fallbackName.isNotEmpty()) fallbackName.take(2).uppercase() else "US")
        
        db.collection("users").document(uid).get()
            .addOnSuccessListener { doc ->
                val username = doc.getString("username")
                if (!username.isNullOrEmpty()) {
                    welcomeTitle.text = "Welcome, $username"
                    profileBadge.text = username.take(2).uppercase()
                } else {
                    welcomeTitle.text = "Welcome, $fallbackName"
                }
            }
            .addOnFailureListener {
                welcomeTitle.text = "Welcome, $email"
            }
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

        val iconWrapper = LinearLayout(this)
        iconWrapper.gravity = Gravity.CENTER
        val circleBg = GradientDrawable()
        circleBg.setColor(adjustAlpha(Color.parseColor(iconColor), 0.08f))
        circleBg.shape = GradientDrawable.OVAL
        iconWrapper.background = circleBg
        iconWrapper.addView(iconView, LinearLayout.LayoutParams(dp(32), dp(32)))
        
        card.addView(iconWrapper, LinearLayout.LayoutParams(dp(68), dp(68)))

        val text = TextView(this)
        text.text = label
        text.textSize = 16f
        text.typeface = Typeface.DEFAULT_BOLD
        text.setTextColor(Color.parseColor("#0F172A"))
        text.setPadding(0, dp(20), 0, 0)
        
        card.addView(text)
        return card
    }

    private fun adjustAlpha(color: Int, factor: Float): Int {
        val alpha = Math.round(Color.alpha(color) * factor)
        return Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color))
    }

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
    private fun dpf(value: Float) = value * resources.displayMetrics.density

    private fun goToLoginPage() {
        val intent = Intent(this, MainActivity::class.java)
        intent.putExtra("fromLogout", true)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish()
    }

    // --- Custom Vector Icons ---

    inner class SearchIcon(context: Context) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#2563EB")
            style = Paint.Style.STROKE
            strokeWidth = dpf(2.5f)
        }
        override fun onDraw(canvas: Canvas) {
            val w = width.toFloat()
            val h = height.toFloat()
            canvas.drawCircle(w * 0.45f, h * 0.45f, w * 0.25f, paint)
            canvas.drawLine(w * 0.65f, h * 0.65f, w * 0.85f, h * 0.85f, paint)
        }
    }

    inner class UsersIcon(context: Context) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#7C3AED")
            style = Paint.Style.STROKE
            strokeWidth = dpf(2.5f)
        }
        override fun onDraw(canvas: Canvas) {
            val w = width.toFloat()
            val h = height.toFloat()
            canvas.drawCircle(w * 0.5f, h * 0.35f, w * 0.18f, paint)
            canvas.drawArc(w * 0.2f, h * 0.6f, w * 0.8f, h * 0.95f, 180f, 180f, false, paint)
            canvas.drawCircle(w * 0.25f, h * 0.45f, w * 0.12f, paint)
        }
    }

    inner class ChatIcon(context: Context) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#059669")
            style = Paint.Style.STROKE
            strokeWidth = dpf(2.5f)
        }
        override fun onDraw(canvas: Canvas) {
            val w = width.toFloat()
            val h = height.toFloat()
            val rect = RectF(w * 0.15f, h * 0.2f, w * 0.85f, h * 0.75f)
            canvas.drawRoundRect(rect, dpf(4f), dpf(4f), paint)
            val path = Path()
            path.moveTo(w * 0.3f, h * 0.75f)
            path.lineTo(w * 0.3f, h * 0.9f)
            path.lineTo(w * 0.5f, h * 0.75f)
            canvas.drawPath(path, paint)
        }
    }

    inner class LogoutIcon(context: Context) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#475569")
            style = Paint.Style.STROKE
            strokeWidth = dpf(2.5f)
        }
        override fun onDraw(canvas: Canvas) {
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