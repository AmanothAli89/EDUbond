package com.example.peermatrix

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast

class SubjectDetailActivity : Activity() {

    private lateinit var subject: String

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        subject = (intent.getStringExtra("subject") ?: "").trim()
        if (subject.isEmpty()) {
            finish()
            return
        }
        showRoleSelectionUI()
    }

    private fun showRoleSelectionUI() {
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
        header.setPadding(0, 0, 0, dp(32))

        val backBtn = TextView(this)
        backBtn.text = "←"
        backBtn.textSize = 24f
        backBtn.setTextColor(Color.parseColor("#1E1B4B"))
        backBtn.setPadding(0, 0, dp(16), 0)
        backBtn.setOnClickListener { finish() }

        val title = TextView(this)
        title.text = subject
        title.textSize = 24f
        title.typeface = Typeface.DEFAULT_BOLD
        title.setTextColor(Color.parseColor("#1E1B4B"))

        header.addView(backBtn)
        header.addView(title)
        root.addView(header)

        // Instruction
        val instruction = TextView(this)
        instruction.text = "Select your role for this subject:"
        instruction.textSize = 16f
        instruction.setTextColor(Color.parseColor("#64748B"))
        instruction.setPadding(0, 0, 0, dp(24))
        root.addView(instruction)

        // Cards Container
        val cardContainer = LinearLayout(this)
        cardContainer.orientation = LinearLayout.VERTICAL
        root.addView(cardContainer)

        // Option 1: Study
        val studyCard = createOptionCard(
            title = "I want to study this",
            subtitle = "Join groups and learn from others",
            iconColor = "#2563EB",
            icon = StudyOptionIcon(this)
        )
        studyCard.setOnClickListener {
            handleStudySelection()
        }
        cardContainer.addView(studyCard)

        // Option 2: Teach
        val teachCard = createOptionCard(
            title = "I want to teach this",
            subtitle = "Share your knowledge and mentor peers",
            iconColor = "#7C3AED",
            icon = TeachOptionIcon(this)
        )
        teachCard.setOnClickListener {
            handleTeachSelection()
        }
        cardContainer.addView(teachCard)

        setContentView(scrollView)
        scrollView.addView(root)
    }

    private fun createOptionCard(title: String, subtitle: String, iconColor: String, icon: View): LinearLayout {
        val card = LinearLayout(this)
        card.orientation = LinearLayout.HORIZONTAL
        card.gravity = Gravity.CENTER_VERTICAL
        card.setPadding(dp(20), dp(24), dp(20), dp(24))
        
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(24).toFloat()
        card.background = bg
        card.elevation = dp(6).toFloat()

        val iconWrapper = LinearLayout(this)
        iconWrapper.gravity = Gravity.CENTER
        val circleBg = GradientDrawable()
        circleBg.setColor(adjustAlpha(Color.parseColor(iconColor), 0.1f))
        circleBg.shape = GradientDrawable.OVAL
        iconWrapper.background = circleBg
        iconWrapper.addView(icon, LinearLayout.LayoutParams(dp(30), dp(30)))
        
        card.addView(iconWrapper, LinearLayout.LayoutParams(dp(64), dp(64)))

        val textLayout = LinearLayout(this)
        textLayout.orientation = LinearLayout.VERTICAL
        textLayout.setPadding(dp(20), 0, 0, 0)

        val titleTv = TextView(this)
        titleTv.text = title
        titleTv.textSize = 18f
        titleTv.typeface = Typeface.DEFAULT_BOLD
        titleTv.setTextColor(Color.parseColor("#1E1B4B"))

        val subTv = TextView(this)
        subTv.text = subtitle
        subTv.textSize = 14f
        subTv.setTextColor(Color.parseColor("#64748B"))
        subTv.setPadding(0, dp(4), 0, 0)

        textLayout.addView(titleTv)
        textLayout.addView(subTv)
        card.addView(textLayout, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))

        val arrow = TextView(this)
        arrow.text = "→"
        arrow.textSize = 20f
        arrow.setTextColor(Color.parseColor("#CBD5E1"))
        card.addView(arrow)

        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(20))
        card.layoutParams = params
        return card
    }

    private fun handleStudySelection() {
        val email = AppStorage.getCurrentUser(this)
        
        FirebaseHistoryManager.addSubjectRole(email, subject, "learner") { success ->
            if (success) {
                toast("You are now a learner for $subject")
            } else {
                toast("Failed to update status")
            }
            showSubjectGroupsUI()
        }
    }

    private fun handleTeachSelection() {
        val email = AppStorage.getCurrentUser(this)

        // Check cloud roles and quiz status
        FirebaseHistoryManager.getUserSubjectRoles(email) { roles ->
            val isTeacher = roles.any { 
                (it["subject"] as? String) == subject && (it["role"] as? String) == "teacher" 
            }
            
            if (isTeacher) {
                runOnUiThread { toast("You are already a teacher for $subject") }
                return@getUserSubjectRoles
            }

            FirebaseHistoryManager.getQuizStatus(email, subject) { status ->
                val isBlocked = status?.get("blocked") as? Boolean ?: false
                
                runOnUiThread {
                    if (isBlocked) {
                        toast("You are blocked from teaching $subject due to previous failed attempts.")
                        return@runOnUiThread
                    }

                    val intent = Intent(this@SubjectDetailActivity, TeacherQuizActivity::class.java)
                    intent.putExtra("subject", subject)
                    startActivity(intent)
                }
            }
        }
    }

    private fun showSubjectGroupsUI() {
        val email = AppStorage.getCurrentUser(this)
        
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
        header.setPadding(0, 0, 0, dp(28))

        val backBtn = TextView(this)
        backBtn.text = "←"
        backBtn.textSize = 24f
        backBtn.setTextColor(Color.parseColor("#1E1B4B"))
        backBtn.setPadding(0, 0, dp(16), 0)
        backBtn.setOnClickListener { showRoleSelectionUI() }

        val title = TextView(this)
        title.text = subject
        title.textSize = 24f
        title.typeface = Typeface.DEFAULT_BOLD
        title.setTextColor(Color.parseColor("#1E1B4B"))

        header.addView(backBtn)
        header.addView(title)
        root.addView(header)

        // Create Group Card
        val createCard = createCard()
        val cTitle = TextView(this)
        cTitle.text = "Start a Study Group"
        cTitle.textSize = 18f
        cTitle.typeface = Typeface.DEFAULT_BOLD
        cTitle.setTextColor(Color.parseColor("#1E1B4B"))
        cTitle.setPadding(0, 0, 0, dp(16))
        createCard.addView(cTitle)

        val groupNameInput = EditText(this)
        groupNameInput.hint = "Enter Group Name"
        groupNameInput.setPadding(dp(16), dp(12), dp(16), dp(12))
        val inputBg = GradientDrawable()
        inputBg.setColor(Color.parseColor("#F1F5F9"))
        inputBg.cornerRadius = dp(12).toFloat()
        groupNameInput.background = inputBg
        val iParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        iParams.setMargins(0, 0, 0, dp(16))
        createCard.addView(groupNameInput, iParams)

        val createBtn = TextView(this)
        createBtn.text = "Create Group"
        createBtn.gravity = Gravity.CENTER
        createBtn.setTextColor(Color.WHITE)
        createBtn.typeface = Typeface.DEFAULT_BOLD
        val btnBg = GradientDrawable()
        btnBg.setColor(Color.parseColor("#2563EB"))
        btnBg.cornerRadius = dp(12).toFloat()
        createBtn.background = btnBg
        createBtn.setPadding(0, dp(14), 0, dp(14))
        createBtn.setOnClickListener {
            val name = groupNameInput.text.toString().trim()
            if (name.isEmpty()) {
                toast("Please enter a group name")
                return@setOnClickListener
            }
            
            FirebaseHistoryManager.createGroup(subject, email, name) { success ->
                if (success) {
                    toast("Group created!")
                    showSubjectGroupsUI()
                } else {
                    toast("Failed to create group")
                }
            }
        }
        createCard.addView(createBtn)
        root.addView(createCard)

        // Available Groups Label
        val label = TextView(this)
        label.text = "Available Groups"
        label.textSize = 18f
        label.typeface = Typeface.DEFAULT_BOLD
        label.setTextColor(Color.parseColor("#475569"))
        label.setPadding(0, dp(12), 0, dp(16))
        root.addView(label)

        val groupsContainer = LinearLayout(this)
        groupsContainer.orientation = LinearLayout.VERTICAL
        root.addView(groupsContainer)

        FirebaseHistoryManager.getGroupsBySubject(subject) { groups ->
            runOnUiThread {
                groupsContainer.removeAllViews()
                if (groups.isEmpty()) {
                    val empty = TextView(this)
                    empty.text = "No groups available for this subject yet."
                    empty.setTextColor(Color.parseColor("#94A3B8"))
                    empty.gravity = Gravity.CENTER
                    empty.setPadding(0, dp(40), 0, 0)
                    groupsContainer.addView(empty)
                } else {
                    for (groupData in groups) {
                        val groupJson = org.json.JSONObject(groupData)
                        groupsContainer.addView(createGroupItemCard(groupJson, email))
                    }
                }
            }
        }

        setContentView(scrollView)
        scrollView.addView(root)
    }

    private fun createGroupItemCard(group: org.json.JSONObject, email: String): LinearLayout {
        val card = LinearLayout(this)
        card.orientation = LinearLayout.VERTICAL
        card.setPadding(dp(20), dp(20), dp(20), dp(20))
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(24).toFloat()
        card.background = bg
        card.elevation = dp(4).toFloat()

        val groupId = group.getString("id")
        val groupName = group.getString("name")
        
        val membersArr = group.optJSONArray("members")
        val teachersArr = group.optJSONArray("teachers")
        val memberCount = membersArr?.length() ?: 0
        val teacherCount = teachersArr?.length() ?: 0
        
        var alreadyInGroup = false
        if (membersArr != null) {
            for (i in 0 until membersArr.length()) {
                if (membersArr.getString(i).equals(email, ignoreCase = true)) {
                    alreadyInGroup = true
                    break
                }
            }
        }
        if (!alreadyInGroup && teachersArr != null) {
            for (i in 0 until teachersArr.length()) {
                if (teachersArr.getString(i).equals(email, ignoreCase = true)) {
                    alreadyInGroup = true
                    break
                }
            }
        }
        // Also check creator
        if (group.optString("createdBy").equals(email, ignoreCase = true)) {
            alreadyInGroup = true
        }

        val nameTv = TextView(this)
        nameTv.text = groupName
        nameTv.textSize = 17f
        nameTv.typeface = Typeface.DEFAULT_BOLD
        nameTv.setTextColor(Color.parseColor("#1E1B4B"))
        card.addView(nameTv)

        val statsTv = TextView(this)
        statsTv.text = "Members: $memberCount  •  Teachers: $teacherCount"
        statsTv.textSize = 13f
        statsTv.setTextColor(Color.parseColor("#64748B"))
        statsTv.setPadding(0, dp(4), 0, dp(16))
        card.addView(statsTv)

        val actionBtn = TextView(this)
        actionBtn.gravity = Gravity.CENTER
        actionBtn.setPadding(0, dp(12), 0, dp(12))
        actionBtn.typeface = Typeface.DEFAULT_BOLD
        val btnBg = GradientDrawable()
        btnBg.cornerRadius = dp(12).toFloat()
        
        if (alreadyInGroup) {
            actionBtn.text = "Open Group"
            actionBtn.setTextColor(Color.WHITE)
            btnBg.setColor(Color.parseColor("#059669"))
            actionBtn.setOnClickListener {
                val intent = Intent(this, GroupRoomActivity::class.java)
                intent.putExtra("groupId", groupId)
                intent.putExtra("groupName", groupName)
                startActivity(intent)
            }
        } else {
            actionBtn.text = "Request to Join"
            actionBtn.setTextColor(Color.parseColor("#2563EB"))
            btnBg.setColor(Color.parseColor("#EFF6FF"))
            actionBtn.setOnClickListener {
                FirebaseHistoryManager.requestToJoinGroup(groupId, groupName, subject, email) { success ->
                    if (success) {
                        toast("Request sent!")
                    } else {
                        toast("Failed to send request")
                    }
                }
            }
        }
        actionBtn.background = btnBg
        card.addView(actionBtn)

        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(16))
        card.layoutParams = params
        return card
    }

    private fun createCard(): LinearLayout {
        val card = LinearLayout(this)
        card.orientation = LinearLayout.VERTICAL
        card.setPadding(dp(20), dp(24), dp(20), dp(24))
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(24).toFloat()
        card.background = bg
        card.elevation = dp(4).toFloat()
        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(24))
        card.layoutParams = params
        return card
    }

    private fun adjustAlpha(color: Int, factor: Float): Int {
        val alpha = Math.round(Color.alpha(color) * factor)
        return Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color))
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
    private fun toast(m: String) = Toast.makeText(this, m, Toast.LENGTH_SHORT).show()

    inner class StudyOptionIcon(context: Context) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#2563EB")
            style = Paint.Style.STROKE
            strokeWidth = 3f * resources.displayMetrics.density
        }
        override fun onDraw(canvas: Canvas) {
            val w = width.toFloat()
            val h = height.toFloat()
            val path = Path()
            path.moveTo(w * 0.2f, h * 0.3f)
            path.lineTo(w * 0.8f, h * 0.3f)
            path.lineTo(w * 0.8f, h * 0.8f)
            path.lineTo(w * 0.2f, h * 0.8f)
            path.close()
            canvas.drawPath(path, paint)
            canvas.drawLine(w * 0.35f, h * 0.45f, w * 0.65f, h * 0.45f, paint)
            canvas.drawLine(w * 0.35f, h * 0.6f, w * 0.65f, h * 0.6f, paint)
        }
    }

    inner class TeachOptionIcon(context: Context) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#7C3AED")
            style = Paint.Style.STROKE
            strokeWidth = 3f * resources.displayMetrics.density
        }
        override fun onDraw(canvas: Canvas) {
            val w = width.toFloat()
            val h = height.toFloat()
            canvas.drawCircle(w * 0.5f, h * 0.35f, w * 0.2f, paint)
            canvas.drawArc(w * 0.2f, h * 0.65f, w * 0.8f, h * 0.95f, 180f, 180f, false, paint)
        }
    }
}