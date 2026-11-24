package com.example.peermatrix

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import org.json.JSONObject

class MyGroupsActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showMyGroupsUI()
    }

    private fun showMyGroupsUI() {
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
        header.setPadding(0, 0, 0, dp(32))

        val title = TextView(this)
        title.text = "My Groups"
        title.textSize = 26f
        title.typeface = Typeface.DEFAULT_BOLD
        title.setTextColor(Color.parseColor("#1E1B4B"))
        header.addView(title)
        root.addView(header)

        // Group List Container
        val listContainer = LinearLayout(this)
        listContainer.orientation = LinearLayout.VERTICAL
        root.addView(listContainer)

        FirebaseHistoryManager.getGroupsForUser(email) { groups ->
            runOnUiThread {
                listContainer.removeAllViews()
                if (groups.isEmpty()) {
                    val emptyTv = TextView(this)
                    emptyTv.text = "You haven't joined any groups yet."
                    emptyTv.textSize = 16f
                    emptyTv.setTextColor(Color.parseColor("#94A3B8"))
                    emptyTv.gravity = Gravity.CENTER
                    emptyTv.setPadding(0, dp(100), 0, 0)
                    listContainer.addView(emptyTv)
                } else {
                    for (groupData in groups) {
                        val group = JSONObject(groupData)
                        val groupCard = createGroupCard(group)
                        groupCard.setOnClickListener {
                            val intent = Intent(this, GroupRoomActivity::class.java)
                            intent.putExtra("groupId", group.getString("id"))
                            intent.putExtra("groupName", group.getString("name"))
                            startActivity(intent)
                        }
                        listContainer.addView(groupCard)
                    }
                }
            }
        }

        // Back Button
        val backBtn = actionButton("BACK", "#334155")
        val backParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(56))
        backParams.setMargins(0, dp(32), 0, 0)
        backBtn.setOnClickListener { finish() }
        root.addView(backBtn, backParams)

        scrollView.addView(root)
        setContentView(scrollView)
    }

    private fun createGroupCard(group: JSONObject): LinearLayout {
        val card = LinearLayout(this)
        card.orientation = LinearLayout.VERTICAL
        card.setPadding(dp(24), dp(22), dp(24), dp(22))
        
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(24).toFloat()
        card.background = bg
        card.elevation = dp(4).toFloat()

        val groupName = TextView(this)
        groupName.text = group.getString("name")
        groupName.textSize = 18f
        groupName.typeface = Typeface.DEFAULT_BOLD
        groupName.setTextColor(Color.parseColor("#1E1B4B"))

        val subjectName = TextView(this)
        subjectName.text = group.getString("subject")
        subjectName.textSize = 14f
        subjectName.setTextColor(Color.parseColor("#64748B"))
        subjectName.setPadding(0, dp(4), 0, 0)

        card.addView(groupName)
        card.addView(subjectName)

        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(18))
        card.layoutParams = params
        return card
    }

    private fun actionButton(text: String, color: String): TextView {
        val btn = TextView(this)
        btn.text = text
        btn.textSize = 15f
        btn.typeface = Typeface.DEFAULT_BOLD
        btn.setTextColor(Color.WHITE)
        btn.gravity = Gravity.CENTER
        btn.setPadding(0, dp(14), 0, dp(14))
        
        val bg = GradientDrawable()
        bg.setColor(Color.parseColor(color))
        bg.cornerRadius = dp(12).toFloat()
        btn.background = bg
        
        return btn
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    override fun onResume() {
        super.onResume()
        showMyGroupsUI()
    }
}