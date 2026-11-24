package com.example.peermatrix

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import org.json.JSONArray
import org.json.JSONObject

class GroupInfoActivity : Activity() {

    private lateinit var groupId: String
    private lateinit var contentLayout: LinearLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        groupId = intent.getStringExtra("groupId") ?: ""
        if (groupId.isEmpty()) {
            finish()
            return
        }
        setupUI()
    }

    private fun setupUI() {
        val scrollView = ScrollView(this)
        scrollView.isFillViewport = true
        scrollView.setBackgroundColor(Color.parseColor("#F8FBFF"))

        contentLayout = LinearLayout(this)
        contentLayout.orientation = LinearLayout.VERTICAL
        contentLayout.setPadding(dp(20), dp(24), dp(20), dp(40))

        FirebaseHistoryManager.getGroupInfo(groupId) { data ->
            if (data == null) {
                runOnUiThread { finish() }
                return@getGroupInfo
            }

            val groupName = data["name"] as? String ?: "Group Info"
            val subject = data["subject"] as? String ?: ""
            val createdBy = data["createdBy"] as? String ?: ""
            val members = data["members"] as? List<String> ?: emptyList()
            val teachers = data["teachers"] as? List<String> ?: emptyList()

            runOnUiThread {
                contentLayout.removeAllViews()

                // Header
                val header = LinearLayout(this@GroupInfoActivity)
                header.orientation = LinearLayout.HORIZONTAL
                header.gravity = Gravity.CENTER_VERTICAL
                header.setPadding(0, 0, 0, dp(32))

                val backBtn = TextView(this@GroupInfoActivity)
                backBtn.text = "←"
                backBtn.textSize = 24f
                backBtn.setTextColor(Color.parseColor("#1E1B4B"))
                backBtn.setPadding(0, 0, dp(16), 0)
                backBtn.setOnClickListener { finish() }

                val title = TextView(this@GroupInfoActivity)
                title.text = groupName
                title.textSize = 26f
                title.typeface = Typeface.DEFAULT_BOLD
                title.setTextColor(Color.parseColor("#1E1B4B"))

                header.addView(backBtn)
                header.addView(title)
                contentLayout.addView(header)

                // Group Details Card
                val infoCard = createCard()
                infoCard.setPadding(dp(20), dp(20), dp(20), dp(20))
                infoCard.addView(infoRow("Subject:", subject))
                infoCard.addView(View(this@GroupInfoActivity).apply { layoutParams = LinearLayout.LayoutParams(1, dp(8)) })
                infoCard.addView(infoRow("Creator:", createdBy))
                contentLayout.addView(infoCard)

                // Teachers Section
                addSectionTitle("Teachers")
                if (teachers.isEmpty()) {
                    contentLayout.addView(emptyText("No teachers added yet."))
                } else {
                    for (email in teachers) {
                        contentLayout.addView(createMemberCard(email))
                    }
                }

                // Members Section
                addSectionTitle("Members")
                if (members.isEmpty()) {
                    contentLayout.addView(emptyText("No members found."))
                } else {
                    for (email in members) {
                        contentLayout.addView(createMemberCard(email))
                    }
                }

                // Available Teachers Section
                addSectionTitle("Hire Qualified Teachers")
                val availableTeachersContainer = LinearLayout(this@GroupInfoActivity)
                availableTeachersContainer.orientation = LinearLayout.VERTICAL
                contentLayout.addView(availableTeachersContainer)

                FirebaseHistoryManager.getQualifiedTeachers(subject) { availableTeachers ->
                    runOnUiThread {
                        val filteredTeachers = availableTeachers.filter { teacherEmail ->
                            !teachers.contains(teacherEmail)
                        }

                        if (filteredTeachers.isEmpty()) {
                            availableTeachersContainer.addView(emptyText("No other qualified teachers available for this subject."))
                        } else {
                            for (teacherEmail in filteredTeachers) {
                                availableTeachersContainer.addView(createAvailableTeacherCard(teacherEmail, subject, groupName))
                            }
                        }
                    }
                }

                // Buttons Section
                addSharedFilesAndLeaveButtons(groupName)
            }
        }

        scrollView.addView(contentLayout)
        setContentView(scrollView)
    }

    private fun addSharedFilesAndLeaveButtons(groupName: String) {
        // Shared Files Button
        val sharedFilesBtn = TextView(this)
        sharedFilesBtn.text = "📁 View Shared Files"
        sharedFilesBtn.setTextColor(Color.WHITE)
        sharedFilesBtn.textSize = 17f
        sharedFilesBtn.typeface = Typeface.DEFAULT_BOLD
        sharedFilesBtn.gravity = Gravity.CENTER
        sharedFilesBtn.setPadding(0, dp(16), 0, dp(16))
        val sharedBg = GradientDrawable()
        sharedBg.setColor(Color.parseColor("#3B82F6"))
        sharedBg.cornerRadius = dp(16).toFloat()
        sharedFilesBtn.background = sharedBg
        sharedFilesBtn.setOnClickListener {
            val intent = Intent(this, SharedFilesActivity::class.java)
            intent.putExtra("groupId", groupId)
            startActivity(intent)
        }
        val sharedParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        sharedParams.setMargins(0, dp(40), 0, 0)
        contentLayout.addView(sharedFilesBtn, sharedParams)

        // Leave Group Button
        val leaveBtn = TextView(this)
        leaveBtn.text = "Leave Group"
        leaveBtn.setTextColor(Color.WHITE)
        leaveBtn.textSize = 18f
        leaveBtn.typeface = Typeface.DEFAULT_BOLD
        leaveBtn.gravity = Gravity.CENTER
        leaveBtn.setPadding(0, dp(18), 0, dp(18))
        val leaveBg = GradientDrawable()
        leaveBg.setColor(Color.parseColor("#EF4444"))
        leaveBg.cornerRadius = dp(16).toFloat()
        leaveBtn.background = leaveBg
        leaveBtn.setOnClickListener { confirmLeaveGroup() }

        val leaveParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        leaveParams.setMargins(0, dp(12), 0, 0)
        contentLayout.addView(leaveBtn, leaveParams)
    }

    private fun createMemberCard(email: String): LinearLayout {
        val card = createCard()
        card.setPadding(dp(20), dp(16), dp(20), dp(16))
        
        val nameTv = TextView(this)
        FirebaseHistoryManager.getUserNameGlobally(email) { name ->
            runOnUiThread { nameTv.text = name }
        }
        nameTv.textSize = 17f
        nameTv.typeface = Typeface.DEFAULT_BOLD
        nameTv.setTextColor(Color.parseColor("#1E1B4B"))

        val emailTv = TextView(this)
        emailTv.text = email
        emailTv.textSize = 14f
        emailTv.setTextColor(Color.parseColor("#64748B"))
        emailTv.setPadding(0, dp(2), 0, 0)

        card.addView(nameTv)
        card.addView(emailTv)
        
        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(12))
        card.layoutParams = params
        return card
    }

    private fun createAvailableTeacherCard(teacherEmail: String, subject: String, groupName: String): LinearLayout {
        val card = createCard()
        card.orientation = LinearLayout.HORIZONTAL
        card.gravity = Gravity.CENTER_VERTICAL
        card.setPadding(dp(20), dp(16), dp(20), dp(16))

        val infoLayout = LinearLayout(this)
        infoLayout.orientation = LinearLayout.VERTICAL
        infoLayout.layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)

        val nameTv = TextView(this)
        FirebaseHistoryManager.getUserNameGlobally(teacherEmail) { name ->
            runOnUiThread { nameTv.text = name }
        }
        nameTv.textSize = 17f
        nameTv.typeface = Typeface.DEFAULT_BOLD
        nameTv.setTextColor(Color.parseColor("#1E1B4B"))

        val emailTv = TextView(this)
        emailTv.text = teacherEmail
        emailTv.textSize = 14f
        emailTv.setTextColor(Color.parseColor("#64748B"))
        emailTv.setPadding(0, dp(2), 0, 0)

        infoLayout.addView(nameTv)
        infoLayout.addView(emailTv)

        val requestBtn = TextView(this)
        requestBtn.text = "Request"
        requestBtn.textSize = 14f
        requestBtn.typeface = Typeface.DEFAULT_BOLD
        requestBtn.setTextColor(Color.WHITE)
        requestBtn.setPadding(dp(18), dp(10), dp(18), dp(10))
        val btnBg = GradientDrawable()
        btnBg.setColor(Color.parseColor("#2563EB"))
        btnBg.cornerRadius = dp(10).toFloat()
        requestBtn.background = btnBg
        
        requestBtn.setOnClickListener {
            val currentUser = AppStorage.getCurrentUser(this)
            FirebaseHistoryManager.requestTeacherToJoin(groupId, groupName, subject, currentUser, teacherEmail) { success ->
                runOnUiThread {
                    if (success) {
                        toast("Request sent to teacher")
                        requestBtn.text = "Sent"
                        requestBtn.alpha = 0.5f
                        requestBtn.setOnClickListener(null)
                    } else {
                        toast("Failed to send request")
                    }
                }
            }
        }

        card.addView(infoLayout)
        card.addView(requestBtn)
        
        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(12))
        card.layoutParams = params
        return card
    }

    private fun addSectionTitle(text: String) {
        val tv = TextView(this)
        tv.text = text
        tv.textSize = 20f
        tv.typeface = Typeface.DEFAULT_BOLD
        tv.setTextColor(Color.parseColor("#1E1B4B"))
        tv.setPadding(0, dp(32), 0, dp(16))
        contentLayout.addView(tv)
    }

    private fun infoRow(label: String, value: String): LinearLayout {
        val row = LinearLayout(this)
        row.orientation = LinearLayout.HORIZONTAL
        row.setPadding(0, dp(4), 0, dp(4))
        
        val labelTv = TextView(this)
        labelTv.text = label
        labelTv.textSize = 15f
        labelTv.typeface = Typeface.DEFAULT_BOLD
        labelTv.setTextColor(Color.parseColor("#64748B"))
        labelTv.layoutParams = LinearLayout.LayoutParams(dp(90), ViewGroup.LayoutParams.WRAP_CONTENT)

        val valueTv = TextView(this)
        valueTv.text = value
        valueTv.textSize = 15f
        valueTv.setTextColor(Color.parseColor("#1E1B4B"))

        row.addView(labelTv)
        row.addView(valueTv)
        return row
    }

    private fun emptyText(text: String): TextView {
        val tv = TextView(this)
        tv.text = text
        tv.textSize = 15f
        tv.setTextColor(Color.parseColor("#94A3B8"))
        tv.setPadding(dp(4), 0, 0, 0)
        return tv
    }

    private fun createCard(): LinearLayout {
        val card = LinearLayout(this)
        card.orientation = LinearLayout.VERTICAL
        card.setPadding(dp(20), dp(16), dp(20), dp(16))
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(20).toFloat()
        card.background = bg
        card.elevation = dp(4).toFloat()
        return card
    }

    private fun confirmLeaveGroup() {
        AlertDialog.Builder(this)
            .setTitle("Leave Group")
            .setMessage("Are you sure you want to leave this group?")
            .setPositiveButton("Leave") { _, _ ->
                val email = AppStorage.getCurrentUser(this)
                FirebaseHistoryManager.leaveGroup(groupId, email) { success ->
                    runOnUiThread {
                        if (success) {
                            toast("You left the group")
                            val intent = Intent(this@GroupInfoActivity, MyGroupsActivity::class.java)
                            intent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP
                            startActivity(intent)
                            finish()
                        } else {
                            toast("Failed to leave group")
                        }
                    }
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun getGroupTeachersArray(group: JSONObject): JSONArray {
        val teachers = group.optJSONArray("teachers") ?: JSONArray()
        val oldTeacher = group.optString("teacher", "")
        if (oldTeacher.isNotEmpty()) {
            var exists = false
            for (i in 0 until teachers.length()) {
                if (teachers.getString(i).equals(oldTeacher, ignoreCase = true)) {
                    exists = true; break
                }
            }
            if (!exists) teachers.put(oldTeacher)
        }
        return teachers
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
    private fun toast(m: String) = Toast.makeText(this, m, Toast.LENGTH_SHORT).show()
}