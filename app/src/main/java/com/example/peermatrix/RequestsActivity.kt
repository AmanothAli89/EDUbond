package com.example.peermatrix

import android.app.Activity
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
import org.json.JSONObject

class RequestsActivity : Activity() {

    private lateinit var contentLayout: LinearLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showUI()
    }

    private fun showUI() {
        val scrollView = ScrollView(this)
        scrollView.isFillViewport = true
        scrollView.setBackgroundColor(Color.parseColor("#F8FBFF"))

        contentLayout = LinearLayout(this)
        contentLayout.orientation = LinearLayout.VERTICAL
        contentLayout.setPadding(dp(20), dp(24), dp(20), dp(40))

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
        title.text = "Requests"
        title.textSize = 26f
        title.typeface = Typeface.DEFAULT_BOLD
        title.setTextColor(Color.parseColor("#1E1B4B"))

        header.addView(backBtn)
        header.addView(title)
        contentLayout.addView(header)

        loadRequests()

        scrollView.addView(contentLayout)
        setContentView(scrollView)
    }

    private fun loadRequests() {
        val email = AppStorage.getCurrentUser(this)

        // 1. Incoming Join Requests
        addSectionTitle("Join Requests")
        val joinContainer = LinearLayout(this)
        joinContainer.orientation = LinearLayout.VERTICAL
        contentLayout.addView(joinContainer)

        FirebaseHistoryManager.getIncomingJoinRequests(email) { requests ->
            runOnUiThread {
                joinContainer.removeAllViews()
                if (requests.isEmpty()) {
                    joinContainer.addView(emptyText("No pending join requests."))
                } else {
                    for (reqData in requests) {
                        joinContainer.addView(createJoinRequestCard(JSONObject(reqData)))
                    }
                }
            }
        }

        // 2. Incoming Teaching Requests
        addSectionTitle("Teaching Requests")
        val teachContainer = LinearLayout(this)
        teachContainer.orientation = LinearLayout.VERTICAL
        contentLayout.addView(teachContainer)

        FirebaseHistoryManager.getIncomingTeacherRequests(email) { requests ->
            runOnUiThread {
                teachContainer.removeAllViews()
                if (requests.isEmpty()) {
                    teachContainer.addView(emptyText("No pending teaching requests."))
                } else {
                    for (reqData in requests) {
                        teachContainer.addView(createTeachingRequestCard(JSONObject(reqData)))
                    }
                }
            }
        }

        // 3. My Sent Requests
        addSectionTitle("My Sent Requests")
        val sentContainer = LinearLayout(this)
        sentContainer.orientation = LinearLayout.VERTICAL
        contentLayout.addView(sentContainer)

        FirebaseHistoryManager.getSentRequests(email) { requests ->
            runOnUiThread {
                sentContainer.removeAllViews()
                if (requests.isEmpty()) {
                    sentContainer.addView(emptyText("You haven't sent any requests."))
                } else {
                    for (reqData in requests) {
                        val req = JSONObject(reqData)
                        sentContainer.addView(createStatusCard(
                            "Join: ${req.optString("groupName")}", 
                            "Status: ${req.optString("status")}"
                        ))
                    }
                }
            }
        }
    }

    private fun createJoinRequestCard(req: JSONObject): LinearLayout {
        val card = createCard()
        val requester = req.getString("requester")
        val requestId = req.getString("id")
        val groupId = req.getString("groupId")
        
        val requesterTv = TextView(this)
        requesterTv.text = "Requester: $requester"
        requesterTv.textSize = 15f
        requesterTv.setTextColor(Color.parseColor("#1E1B4B"))
        
        val groupTv = TextView(this)
        groupTv.text = "Group: ${req.optString("groupName")}"
        groupTv.textSize = 15f
        groupTv.setTextColor(Color.parseColor("#1E1B4B"))
        groupTv.setPadding(0, dp(2), 0, 0)

        card.addView(requesterTv)
        card.addView(groupTv)
        
        val btnLayout = LinearLayout(this)
        btnLayout.setPadding(0, dp(16), 0, 0)
        
        val accBtn = actionBtn("Approve", "#10B981") {
            FirebaseHistoryManager.acceptJoinRequest(requestId, groupId, requester) { success ->
                if (success) {
                    toast("Approved Successfully")
                    showUI()
                } else {
                    toast("Failed to approve")
                }
            }
        }
        val rejBtn = actionBtn("Reject", "#EF4444") {
            FirebaseHistoryManager.rejectJoinRequest(requestId) { success ->
                if (success) {
                    toast("Rejected Successfully")
                    showUI()
                } else {
                    toast("Failed to reject")
                }
            }
        }
        
        btnLayout.addView(accBtn)
        val spacer = View(this)
        btnLayout.addView(spacer, dp(16), 1)
        btnLayout.addView(rejBtn)
        card.addView(btnLayout)
        
        return card
    }

    private fun createTeachingRequestCard(req: JSONObject): LinearLayout {
        val card = createCard()
        val email = AppStorage.getCurrentUser(this)
        val requestId = req.getString("id")
        val groupId = req.getString("groupId")
        
        val groupTv = TextView(this)
        groupTv.text = "Group: ${req.optString("groupName")}"
        groupTv.textSize = 15f
        groupTv.setTextColor(Color.parseColor("#1E1B4B"))

        val subTv = TextView(this)
        subTv.text = "Subject: ${req.optString("subject")}"
        subTv.textSize = 15f
        subTv.setTextColor(Color.parseColor("#1E1B4B"))
        subTv.setPadding(0, dp(2), 0, 0)

        card.addView(groupTv)
        card.addView(subTv)
        
        val btnLayout = LinearLayout(this)
        btnLayout.setPadding(0, dp(16), 0, 0)
        
        val accBtn = actionBtn("Accept", "#10B981") {
            FirebaseHistoryManager.acceptTeacherRequest(requestId, groupId, email) { success ->
                if (success) {
                    toast("Accepted Successfully")
                    showUI()
                } else {
                    toast("Failed to accept")
                }
            }
        }
        val rejBtn = actionBtn("Reject", "#EF4444") {
            FirebaseHistoryManager.rejectTeacherRequest(requestId) { success ->
                if (success) {
                    toast("Rejected Successfully")
                    showUI()
                } else {
                    toast("Failed to reject")
                }
            }
        }
        
        btnLayout.addView(accBtn)
        val spacer = View(this)
        btnLayout.addView(spacer, dp(16), 1)
        btnLayout.addView(rejBtn)
        card.addView(btnLayout)
        
        return card
    }

    private fun createStatusCard(title: String, status: String): LinearLayout {
        val card = createCard()
        card.setPadding(dp(20), dp(18), dp(20), dp(18))

        val t = TextView(this)
        t.text = title
        t.textSize = 17f
        t.typeface = Typeface.DEFAULT_BOLD
        t.setTextColor(Color.parseColor("#1E1B4B"))
        
        val s = TextView(this)
        s.text = status
        s.textSize = 14f
        s.setTextColor(Color.parseColor("#64748B"))
        s.setPadding(0, dp(4), 0, 0)
        
        card.addView(t)
        card.addView(s)
        return card
    }

    private fun addSectionTitle(text: String) {
        val tv = TextView(this)
        tv.text = text
        tv.textSize = 20f
        tv.typeface = Typeface.DEFAULT_BOLD
        tv.setTextColor(Color.parseColor("#475569"))
        tv.setPadding(0, dp(32), 0, dp(16))
        contentLayout.addView(tv)
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
        card.setPadding(dp(20), dp(20), dp(20), dp(20))
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(24).toFloat()
        card.background = bg
        card.elevation = dp(4).toFloat()
        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(16))
        card.layoutParams = params
        return card
    }

    private fun actionBtn(text: String, color: String, onClick: () -> Unit): TextView {
        val tv = TextView(this)
        tv.text = text
        tv.setTextColor(Color.WHITE)
        tv.textSize = 15f
        tv.typeface = Typeface.DEFAULT_BOLD
        tv.gravity = Gravity.CENTER
        tv.setPadding(dp(20), dp(10), dp(20), dp(10))
        val bg = GradientDrawable()
        bg.setColor(Color.parseColor(color))
        bg.cornerRadius = dp(12).toFloat()
        tv.background = bg
        tv.setOnClickListener { onClick() }
        return tv
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
    private fun toast(m: String) = Toast.makeText(this, m, Toast.LENGTH_SHORT).show()
}