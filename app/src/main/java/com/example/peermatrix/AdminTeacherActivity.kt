package com.example.peermatrix

import android.app.Activity
import android.app.AlertDialog
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.*

class AdminTeacherActivity : Activity() {

    private lateinit var contentLayout: LinearLayout
    private var currentTab = "teachers" // "teachers", "blocked"
    private var searchQuery = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showMainUI()
    }

    private fun showMainUI() {
        val root = LinearLayout(this)
        root.orientation = LinearLayout.VERTICAL
        root.setBackgroundColor(Color.parseColor("#F8FBFF"))

        // Header
        val header = LinearLayout(this)
        header.orientation = LinearLayout.HORIZONTAL
        header.gravity = Gravity.CENTER_VERTICAL
        header.setPadding(dp(20), dp(24), dp(20), dp(20))

        val backBtn = TextView(this)
        backBtn.text = "←"
        backBtn.textSize = 24f
        backBtn.setTextColor(Color.parseColor("#1E1B4B"))
        backBtn.setPadding(0, 0, dp(16), 0)
        backBtn.setOnClickListener { finish() }

        val title = TextView(this)
        title.text = "Manage Teachers"
        title.textSize = 24f
        title.typeface = Typeface.DEFAULT_BOLD
        title.setTextColor(Color.parseColor("#1E1B4B"))

        header.addView(backBtn)
        header.addView(title)
        root.addView(header)

        // Tabs
        val tabLayout = LinearLayout(this)
        tabLayout.orientation = LinearLayout.HORIZONTAL
        tabLayout.setPadding(dp(20), 0, dp(20), dp(10))

        val teachersTab = createTabButton("Teachers", currentTab == "teachers")
        val blockedTab = createTabButton("Blocked", currentTab == "blocked")

        teachersTab.setOnClickListener {
            currentTab = "teachers"
            showMainUI()
        }
        blockedTab.setOnClickListener {
            currentTab = "blocked"
            showMainUI()
        }

        tabLayout.addView(teachersTab, LinearLayout.LayoutParams(0, dp(48), 1f))
        tabLayout.addView(View(this), LinearLayout.LayoutParams(dp(12), 1))
        tabLayout.addView(blockedTab, LinearLayout.LayoutParams(0, dp(48), 1f))
        root.addView(tabLayout)

        // Search Box
        val searchInput = EditText(this)
        searchInput.hint = if (currentTab == "teachers") "Search by email or subject..." else "Search blocked teachers..."
        searchInput.textSize = 15f
        searchInput.setPadding(dp(16), dp(12), dp(16), dp(12))
        val searchBg = GradientDrawable()
        searchBg.setColor(Color.WHITE)
        searchBg.cornerRadius = dp(12).toFloat()
        searchBg.setStroke(dp(1), Color.parseColor("#E2E8F0"))
        searchInput.background = searchBg
        searchInput.setText(searchQuery)
        searchInput.setSelection(searchQuery.length)
        
        val searchParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        searchParams.setMargins(dp(20), 0, dp(20), dp(16))
        root.addView(searchInput, searchParams)

        searchInput.addTextChangedListener(object : TextWatcher {
            override fun afterTextChanged(s: Editable?) { 
                searchQuery = s.toString().trim()
                if (currentTab == "teachers") loadTeacherList() else loadBlockedList()
            }
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
        })

        // Scrollable Content
        val scrollView = ScrollView(this)
        scrollView.isFillViewport = true
        contentLayout = LinearLayout(this)
        contentLayout.orientation = LinearLayout.VERTICAL
        contentLayout.setPadding(dp(20), dp(10), dp(20), dp(40))
        scrollView.addView(contentLayout)
        root.addView(scrollView)

        setContentView(root)
        if (currentTab == "teachers") loadTeacherList() else loadBlockedList()
    }

    private fun createTabButton(text: String, active: Boolean): TextView {
        val tv = TextView(this)
        tv.text = text
        tv.gravity = Gravity.CENTER
        tv.textSize = 15f
        tv.typeface = if (active) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        tv.setTextColor(if (active) Color.WHITE else Color.parseColor("#64748B"))

        val bg = GradientDrawable()
        bg.setColor(if (active) Color.parseColor("#4F46E5") else Color.parseColor("#F1F5F9"))
        bg.cornerRadius = dp(12).toFloat()
        tv.background = bg

        return tv
    }

    private fun loadTeacherList() {
        contentLayout.removeAllViews()
        val loading = TextView(this)
        loading.text = "Loading teachers..."
        loading.gravity = Gravity.CENTER
        loading.setPadding(0, dp(100), 0, 0)
        contentLayout.addView(loading)

        FirebaseHistoryManager.getAllTeachersGlobally { allTeachers ->
            runOnUiThread {
                contentLayout.removeAllViews()
                val filtered = if (searchQuery.isEmpty()) {
                    allTeachers
                } else {
                    allTeachers.filter { 
                        (it["email"] as? String ?: "").contains(searchQuery, true) || 
                        (it["subject"] as? String ?: "").contains(searchQuery, true)
                    }
                }

                if (filtered.isEmpty()) {
                    val empty = TextView(this)
                    empty.text = if (searchQuery.isEmpty()) "No teachers found" else "No matching teachers"
                    empty.gravity = Gravity.CENTER
                    empty.setPadding(0, dp(100), 0, 0)
                    empty.setTextColor(Color.parseColor("#94A3B8"))
                    contentLayout.addView(empty)
                    return@runOnUiThread
                }

                for (t in filtered) {
                    val email = t["email"] as? String ?: ""
                    val subject = t["subject"] as? String ?: ""
                    val score = (t["score"] as? Long ?: 0L).toInt()
                    
                    val card = createTeacherCard(email, subject, score)
                    contentLayout.addView(card)
                }
            }
        }
    }

    private fun loadBlockedList() {
        contentLayout.removeAllViews()
        val loading = TextView(this)
        loading.text = "Loading blocked teachers..."
        loading.gravity = Gravity.CENTER
        loading.setPadding(0, dp(100), 0, 0)
        contentLayout.addView(loading)

        FirebaseHistoryManager.getBlockedTeachersGlobally { blocks ->
            runOnUiThread {
                contentLayout.removeAllViews()
                val filtered = if (searchQuery.isEmpty()) blocks 
                               else blocks.filter { 
                                   (it["email"] as? String ?: "").contains(searchQuery, ignoreCase = true) || 
                                   (it["subject"] as? String ?: "").contains(searchQuery, ignoreCase = true) 
                               }

                if (filtered.isEmpty()) {
                    val empty = TextView(this)
                    empty.text = if (searchQuery.isEmpty()) "No blocked teachers" else "No matching results"
                    empty.gravity = Gravity.CENTER
                    empty.setPadding(0, dp(100), 0, 0)
                    empty.setTextColor(Color.parseColor("#94A3B8"))
                    contentLayout.addView(empty)
                    return@runOnUiThread
                }

                for (b in filtered) {
                    val email = b["email"] as? String ?: ""
                    val sub = b["subject"] as? String ?: ""
                    
                    val card = createBlockedCard(email, sub)
                    contentLayout.addView(card)
                }
            }
        }
    }

    private fun createTeacherCard(email: String, subject: String, score: Int): LinearLayout {
        val card = LinearLayout(this)
        card.orientation = LinearLayout.VERTICAL
        card.setPadding(dp(20), dp(20), dp(20), dp(20))
        
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(24).toFloat()
        card.background = bg
        card.elevation = dp(4).toFloat()

        val nameTv = TextView(this)
        nameTv.text = "Loading name..."
        nameTv.textSize = 18f
        nameTv.typeface = Typeface.DEFAULT_BOLD
        nameTv.setTextColor(Color.parseColor("#1E1B4B"))
        
        FirebaseHistoryManager.getUserNameGlobally(email) { name ->
            runOnUiThread { nameTv.text = name }
        }

        val emailTv = TextView(this)
        emailTv.text = email
        emailTv.textSize = 14f
        emailTv.setTextColor(Color.parseColor("#64748B"))

        val subTv = TextView(this)
        subTv.text = "Subject: $subject"
        subTv.textSize = 15f
        subTv.typeface = Typeface.DEFAULT_BOLD
        subTv.setTextColor(Color.parseColor("#4F46E5"))
        subTv.setPadding(0, dp(8), 0, 0)

        val scoreTv = TextView(this)
        scoreTv.text = "Quiz Score: $score"
        scoreTv.textSize = 13f
        scoreTv.setTextColor(Color.parseColor("#10B981"))
        scoreTv.setPadding(0, dp(2), 0, dp(12))

        card.addView(nameTv)
        card.addView(emailTv)
        card.addView(subTv)
        card.addView(scoreTv)

        val removeBtn = createActionButton("Remove Teacher Role", "#EF4444")
        removeBtn.setOnClickListener { confirmRemoveTeacher(email, subject) }
        card.addView(removeBtn)

        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(18))
        card.layoutParams = params
        return card
    }

    private fun createBlockedCard(email: String, subject: String): LinearLayout {
        val card = LinearLayout(this)
        card.orientation = LinearLayout.VERTICAL
        card.setPadding(dp(20), dp(20), dp(20), dp(20))
        
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(24).toFloat()
        card.background = bg
        card.elevation = dp(4).toFloat()

        val nameTv = TextView(this)
        nameTv.text = "Loading name..."
        nameTv.textSize = 18f
        nameTv.typeface = Typeface.DEFAULT_BOLD
        nameTv.setTextColor(Color.parseColor("#1E1B4B"))
        
        FirebaseHistoryManager.getUserNameGlobally(email) { name ->
            runOnUiThread { nameTv.text = name }
        }

        val emailTv = TextView(this)
        emailTv.text = email
        emailTv.textSize = 14f
        emailTv.setTextColor(Color.parseColor("#64748B"))

        val infoTv = TextView(this)
        infoTv.text = "Blocked for Subject: $subject"
        infoTv.textSize = 14f
        infoTv.setTextColor(Color.parseColor("#EF4444"))
        infoTv.setPadding(0, dp(8), 0, dp(16))

        card.addView(nameTv)
        card.addView(emailTv)
        card.addView(infoTv)

        val unblockBtn = createActionButton("Unblock User", "#10B981")
        unblockBtn.setOnClickListener {
            FirebaseHistoryManager.unblockTeacherGlobally(email, subject) { success ->
                runOnUiThread {
                    if (success) {
                        toast("User unblocked")
                        loadBlockedList()
                    } else {
                        toast("Failed to unblock")
                    }
                }
            }
        }
        card.addView(unblockBtn)

        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(18))
        card.layoutParams = params
        return card
    }

    private fun createActionButton(text: String, color: String): TextView {
        val btn = TextView(this)
        btn.text = text
        btn.gravity = Gravity.CENTER
        btn.setTextColor(Color.WHITE)
        btn.textSize = 14f
        btn.typeface = Typeface.DEFAULT_BOLD
        val btnBg = GradientDrawable()
        btnBg.setColor(Color.parseColor(color))
        btnBg.cornerRadius = dp(12).toFloat()
        btn.background = btnBg
        btn.setPadding(dp(16), dp(10), dp(16), dp(10))
        return btn
    }

    private fun confirmRemoveTeacher(email: String, subject: String) {
        AlertDialog.Builder(this)
            .setTitle("Remove Teacher")
            .setMessage("Are you sure you want to remove $email from teaching $subject?")
            .setPositiveButton("Remove") { _, _ ->
                FirebaseHistoryManager.removeTeacherRoleGlobally(email, subject) { success ->
                    runOnUiThread {
                        if (success) {
                            toast("Teacher removed successfully")
                            loadTeacherList()
                        } else {
                            toast("Failed to remove teacher")
                        }
                    }
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
    private fun toast(text: String) = Toast.makeText(this, text, Toast.LENGTH_SHORT).show()
}
