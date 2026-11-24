package com.example.peermatrix

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
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
import com.google.firebase.firestore.FirebaseFirestore
import org.json.JSONObject

class AdminUserActivity : Activity() {

    private lateinit var contentLayout: LinearLayout
    private lateinit var searchInput: EditText
    private lateinit var infoTv: TextView
    private lateinit var db: FirebaseFirestore
    private var currentTab = "users" // "users" or "teachers"
    private var teacherSubTab = "active" // "active" or "blocked"
    private var searchQuery = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        db = FirebaseFirestore.getInstance()
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
        header.setPadding(dp(20), dp(24), dp(20), dp(10))

        val backBtn = TextView(this)
        backBtn.text = "←"
        backBtn.textSize = 24f
        backBtn.setTextColor(Color.parseColor("#1E1B4B"))
        backBtn.setPadding(0, 0, dp(16), 0)
        backBtn.setOnClickListener { finish() }

        val title = TextView(this)
        title.text = "User Management"
        title.textSize = 24f
        title.typeface = Typeface.DEFAULT_BOLD
        title.setTextColor(Color.parseColor("#1E1B4B"))

        header.addView(backBtn)
        header.addView(title)
        root.addView(header)

        // Main Tabs
        val tabLayout = LinearLayout(this)
        tabLayout.orientation = LinearLayout.HORIZONTAL
        tabLayout.setPadding(dp(20), 0, dp(20), dp(15))

        val usersTab = createTabButton("All Users", currentTab == "users")
        val teachersTab = createTabButton("Teachers", currentTab == "teachers")

        usersTab.setOnClickListener {
            if (currentTab != "users") {
                currentTab = "users"
                showMainUI()
            }
        }
        teachersTab.setOnClickListener {
            if (currentTab != "teachers") {
                currentTab = "teachers"
                showMainUI()
            }
        }

        val tParams = LinearLayout.LayoutParams(0, dp(44), 1f)
        tabLayout.addView(usersTab, tParams)
        tabLayout.addView(View(this), LinearLayout.LayoutParams(dp(12), 1))
        tabLayout.addView(teachersTab, tParams)
        root.addView(tabLayout)

        // Sub-tabs for Teachers (Active / Blocked)
        if (currentTab == "teachers") {
            val subTabLayout = LinearLayout(this)
            subTabLayout.orientation = LinearLayout.HORIZONTAL
            subTabLayout.setPadding(dp(20), 0, dp(20), dp(15))
            
            val activeBtn = createSubTabButton("Active Teachers", teacherSubTab == "active")
            val blockedBtn = createSubTabButton("Blocked Teachers", teacherSubTab == "blocked")
            
            activeBtn.setOnClickListener {
                if (teacherSubTab != "active") {
                    teacherSubTab = "active"
                    showMainUI()
                }
            }
            blockedBtn.setOnClickListener {
                if (teacherSubTab != "blocked") {
                    teacherSubTab = "blocked"
                    showMainUI()
                }
            }
            
            subTabLayout.addView(activeBtn, LinearLayout.LayoutParams(0, dp(36), 1f))
            subTabLayout.addView(View(this), LinearLayout.LayoutParams(dp(8), 1))
            subTabLayout.addView(blockedBtn, LinearLayout.LayoutParams(0, dp(36), 1f))
            root.addView(subTabLayout)
        }

        // Search Box
        searchInput = EditText(this)
        searchInput.hint = when {
            currentTab == "users" -> "Search users..."
            teacherSubTab == "active" -> "Search active teachers..."
            else -> "Search blocked teachers..."
        }
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
        searchParams.setMargins(dp(20), 0, dp(20), dp(10))
        root.addView(searchInput, searchParams)

        searchInput.addTextChangedListener(object : TextWatcher {
            override fun afterTextChanged(s: Editable?) { 
                searchQuery = s.toString().trim()
                loadData(searchQuery) 
            }
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
        })

        // Info
        infoTv = TextView(this)
        infoTv.textSize = 14f
        infoTv.setTextColor(Color.parseColor("#64748B"))
        infoTv.setPadding(dp(20), 0, dp(20), dp(10))
        root.addView(infoTv)

        // Scrollable Content
        val scrollView = ScrollView(this)
        scrollView.isFillViewport = true
        contentLayout = LinearLayout(this)
        contentLayout.orientation = LinearLayout.VERTICAL
        contentLayout.setPadding(dp(20), dp(10), dp(20), dp(40))
        scrollView.addView(contentLayout)
        root.addView(scrollView)

        setContentView(root)
        loadData(searchQuery)
    }

    private fun createTabButton(text: String, active: Boolean): TextView {
        val tv = TextView(this)
        tv.text = text
        tv.gravity = Gravity.CENTER
        tv.textSize = 15f
        tv.typeface = if (active) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        tv.setTextColor(if (active) Color.WHITE else Color.parseColor("#64748B"))

        val bg = GradientDrawable()
        bg.setColor(if (active) Color.parseColor("#2563EB") else Color.parseColor("#F1F5F9"))
        bg.cornerRadius = dp(12).toFloat()
        tv.background = bg

        return tv
    }

    private fun createSubTabButton(text: String, active: Boolean): TextView {
        val tv = TextView(this)
        tv.text = text
        tv.gravity = Gravity.CENTER
        tv.textSize = 13f
        tv.typeface = if (active) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        tv.setTextColor(if (active) Color.parseColor("#4F46E5") else Color.parseColor("#64748B"))

        val bg = GradientDrawable()
        bg.setColor(if (active) Color.parseColor("#EEF2FF") else Color.TRANSPARENT)
        bg.cornerRadius = dp(8).toFloat()
        if (active) bg.setStroke(dp(1), Color.parseColor("#4F46E5"))
        tv.background = bg

        return tv
    }

    private fun loadData(query: String = "") {
        when {
            currentTab == "users" -> loadUserList(query)
            teacherSubTab == "active" -> loadTeacherList(query)
            else -> loadBlockedList(query)
        }
    }

    private fun loadUserList(query: String = "") {
        contentLayout.removeAllViews()
        infoTv.text = "Fetching users..."
        
        db.collection("users").get()
            .addOnSuccessListener { documents ->
                val users = mutableListOf<Map<String, Any>>()
                for (doc in documents) {
                    val data = doc.data
                    val username = data["username"] as? String ?: ""
                    val email = data["email"] as? String ?: ""
                    if (query.isEmpty() || username.contains(query, true) || email.contains(query, true)) {
                        users.add(data)
                    }
                }

                infoTv.text = "Showing ${users.size} users"
                contentLayout.removeAllViews()

                if (users.isEmpty()) {
                    showEmptyView(if (query.isEmpty()) "No users found" else "No matching users")
                } else {
                    for (user in users) {
                        contentLayout.addView(createUserCard(user))
                    }
                }
            }
            .addOnFailureListener { e -> toast("Error: ${e.message}") }
    }

    private fun loadTeacherList(query: String = "") {
        contentLayout.removeAllViews()
        infoTv.text = "Fetching active teachers..."
        
        db.collection("user_roles").whereEqualTo("role", "teacher").get()
            .addOnSuccessListener { documents ->
                val roles = mutableListOf<Map<String, Any>>()
                for (doc in documents) {
                    val data = doc.data
                    val email = data["email"] as? String ?: ""
                    val subject = data["subject"] as? String ?: ""
                    if (query.isEmpty() || email.contains(query, true) || subject.contains(query, true)) {
                        val roleWithId = data.toMutableMap()
                        roleWithId["docId"] = doc.id
                        roles.add(roleWithId)
                    }
                }

                infoTv.text = "Showing ${roles.size} active teachers"
                contentLayout.removeAllViews()

                if (roles.isEmpty()) {
                    showEmptyView(if (query.isEmpty()) "No active teachers" else "No matching results")
                } else {
                    for (role in roles) {
                        contentLayout.addView(createTeacherRoleCard(role))
                    }
                }
            }
            .addOnFailureListener { e -> toast("Error: ${e.message}") }
    }

    private fun loadBlockedList(query: String = "") {
        contentLayout.removeAllViews()
        infoTv.text = "Loading blocked teachers..."
        
        FirebaseHistoryManager.getBlockedTeachersGlobally { list ->
            runOnUiThread {
                val filtered = list.filter {
                    val email = it["email"] as? String ?: ""
                    val sub = it["subject"] as? String ?: ""
                    query.isEmpty() || email.contains(query, true) || sub.contains(query, true)
                }

                infoTv.text = "Showing ${filtered.size} blocked teachers"
                contentLayout.removeAllViews()

                if (filtered.isEmpty()) {
                    showEmptyView(if (query.isEmpty()) "No blocked teachers" else "No matching results")
                } else {
                    for (b in filtered) {
                        val email = b["email"] as? String ?: ""
                        val sub = b["subject"] as? String ?: ""
                        contentLayout.addView(createBlockedCard(email, sub))
                    }
                }
            }
        }
    }

    private fun showEmptyView(msg: String) {
        val empty = TextView(this)
        empty.text = msg
        empty.gravity = Gravity.CENTER
        empty.setPadding(0, dp(100), 0, 0)
        empty.setTextColor(Color.parseColor("#94A3B8"))
        contentLayout.addView(empty)
    }

    private fun createUserCard(user: Map<String, Any>): LinearLayout {
        val username = user["username"] as? String ?: "Unknown"
        val email = user["email"] as? String ?: "No Email"
        val uid = user["uid"] as? String ?: ""

        val card = LinearLayout(this)
        card.orientation = LinearLayout.VERTICAL
        card.setPadding(dp(20), dp(20), dp(20), dp(20))
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(24).toFloat()
        card.background = bg
        card.elevation = dp(4).toFloat()

        val nameTv = TextView(this)
        nameTv.text = username
        nameTv.textSize = 18f
        nameTv.typeface = Typeface.DEFAULT_BOLD
        nameTv.setTextColor(Color.parseColor("#1E1B4B"))

        val emailTv = TextView(this)
        emailTv.text = email
        emailTv.textSize = 14f
        emailTv.setTextColor(Color.parseColor("#64748B"))
        emailTv.setPadding(0, dp(2), 0, dp(8))

        card.addView(nameTv)
        card.addView(emailTv)

        val actions = LinearLayout(this)
        actions.orientation = LinearLayout.HORIZONTAL
        
        val addRoleBtn = createActionBtn("Add Role", "#10B981")
        addRoleBtn.setOnClickListener { showAddRoleDialog(email) }
        
        val removeBtn = createActionBtn("Remove", "#EF4444")
        removeBtn.setOnClickListener { confirmRemoveUser(uid, email) }

        actions.addView(addRoleBtn, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        actions.addView(View(this), LinearLayout.LayoutParams(dp(8), 1))
        actions.addView(removeBtn, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        
        card.addView(actions)

        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(18))
        card.layoutParams = params
        return card
    }

    private fun createTeacherRoleCard(role: Map<String, Any>): LinearLayout {
        val email = role["email"] as? String ?: ""
        val subject = role["subject"] as? String ?: ""
        val docId = role["docId"] as? String ?: ""
        val score = role["score"] as? Long ?: 0

        val card = LinearLayout(this)
        card.orientation = LinearLayout.VERTICAL
        card.setPadding(dp(20), dp(20), dp(20), dp(20))
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(24).toFloat()
        card.background = bg
        card.elevation = dp(4).toFloat()

        val subTv = TextView(this)
        subTv.text = subject
        subTv.textSize = 18f
        subTv.typeface = Typeface.DEFAULT_BOLD
        subTv.setTextColor(Color.parseColor("#4F46E5"))

        val teacherTv = TextView(this)
        teacherTv.text = "Teacher: $email"
        teacherTv.textSize = 14f
        teacherTv.setTextColor(Color.parseColor("#1E1B4B"))
        teacherTv.setPadding(0, dp(4), 0, dp(2))

        val scoreTv = TextView(this)
        scoreTv.text = "Verified Score: $score/10"
        scoreTv.textSize = 12f
        scoreTv.setTextColor(Color.parseColor("#059669"))
        scoreTv.setPadding(0, 0, 0, dp(12))

        val removeBtn = createActionBtn("Remove Teaching Role", "#EF4444")
        removeBtn.setOnClickListener {
            AlertDialog.Builder(this)
                .setTitle("Remove Role")
                .setMessage("Remove $email from teaching $subject?")
                .setPositiveButton("Remove") { _, _ ->
                    db.collection("user_roles").document(docId).delete()
                        .addOnSuccessListener {
                            toast("Role removed")
                            loadTeacherList(searchQuery)
                        }
                }
                .setNegativeButton("Cancel", null)
                .show()
        }

        card.addView(subTv)
        card.addView(teacherTv)
        card.addView(scoreTv)
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

        val emailTv = TextView(this)
        emailTv.text = email
        emailTv.textSize = 17f
        emailTv.typeface = Typeface.DEFAULT_BOLD
        emailTv.setTextColor(Color.parseColor("#1E1B4B"))

        val infoTv = TextView(this)
        infoTv.text = "Blocked from: $subject"
        infoTv.textSize = 14f
        infoTv.setTextColor(Color.parseColor("#EF4444"))
        infoTv.setPadding(0, dp(4), 0, dp(12))

        val unblockBtn = createActionBtn("Unblock User", "#10B981")
        unblockBtn.setOnClickListener {
            FirebaseHistoryManager.unblockTeacherGlobally(email, subject) { success ->
                runOnUiThread {
                    if (success) {
                        toast("User unblocked")
                        loadBlockedList(searchQuery)
                    } else {
                        toast("Unblock failed")
                    }
                }
            }
        }

        card.addView(emailTv)
        card.addView(infoTv)
        card.addView(unblockBtn)

        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(18))
        card.layoutParams = params
        return card
    }

    private fun createActionBtn(text: String, color: String): TextView {
        val tv = TextView(this)
        tv.text = text
        tv.gravity = Gravity.CENTER
        tv.setTextColor(Color.WHITE)
        tv.textSize = 13f
        tv.typeface = Typeface.DEFAULT_BOLD
        val bg = GradientDrawable()
        bg.setColor(Color.parseColor(color))
        bg.cornerRadius = dp(10).toFloat()
        tv.background = bg
        tv.setPadding(dp(12), dp(10), dp(12), dp(10))
        return tv
    }

    private fun showAddRoleDialog(email: String) {
        FirebaseHistoryManager.getGlobalSubjects { subjects ->
            runOnUiThread {
                if (subjects.isEmpty()) {
                    toast("No subjects found. Please add subjects first.")
                    return@runOnUiThread
                }

                val subjectArray = subjects.toTypedArray()
                var selectedIndex = 0

                AlertDialog.Builder(this@AdminUserActivity)
                    .setTitle("Assign Teaching Role")
                    .setSingleChoiceItems(subjectArray, 0) { _, which -> selectedIndex = which }
                    .setPositiveButton("Assign") { _, _ ->
                        val selectedSubject = subjectArray[selectedIndex]
                        assignTeacherRole(email, selectedSubject)
                    }
                    .setNegativeButton("Cancel", null)
                    .show()
            }
        }
    }

    private fun assignTeacherRole(email: String, subject: String) {
        val roleId = "${email.replace(".", "_")}_${subject.replace(" ", "_")}"
        val data = hashMapOf(
            "email" to email,
            "subject" to subject,
            "role" to "teacher",
            "score" to 10,
            "timestamp" to System.currentTimeMillis()
        )

        db.collection("user_roles").document(roleId).set(data)
            .addOnSuccessListener {
                toast("Assigned $email to $subject")
                if (currentTab == "teachers") loadTeacherList(searchQuery)
            }
            .addOnFailureListener { e -> toast("Error: ${e.message}") }
    }

    private fun confirmRemoveUser(uid: String, email: String) {
        AlertDialog.Builder(this)
            .setTitle("Remove User")
            .setMessage("Are you sure you want to remove $email from the database?")
            .setPositiveButton("Remove") { _, _ ->
                db.collection("users").document(uid).delete()
                    .addOnSuccessListener {
                        toast("User removed")
                        loadUserList(searchQuery)
                    }
                    .addOnFailureListener { e -> toast("Failed: ${e.message}") }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
    private fun toast(text: String) = Toast.makeText(this, text, Toast.LENGTH_SHORT).show()
}
