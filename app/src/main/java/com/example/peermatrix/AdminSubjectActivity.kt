package com.example.peermatrix

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
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
import org.json.JSONObject
import java.util.*

class AdminSubjectActivity : Activity() {

    private lateinit var contentLayout: LinearLayout
    private var currentTab = "list" // "list", "requests"
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
        title.text = "Manage Subjects"
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

        val listTab = createTabButton("Subject List", currentTab == "list")
        val requestTab = createTabButton("Requests", currentTab == "requests")

        listTab.setOnClickListener {
            currentTab = "list"
            showMainUI()
        }
        requestTab.setOnClickListener {
            currentTab = "requests"
            showMainUI()
        }

        tabLayout.addView(listTab, LinearLayout.LayoutParams(0, dp(48), 1f))
        tabLayout.addView(requestTab, LinearLayout.LayoutParams(0, dp(48), 1f))
        root.addView(tabLayout)

        // Search Bar
        val searchContainer = LinearLayout(this)
        searchContainer.setPadding(dp(20), dp(10), dp(20), dp(10))
        
        val searchInput = EditText(this)
        searchInput.hint = "Search subjects..."
        searchInput.setPadding(dp(16), dp(12), dp(16), dp(12))
        searchInput.textSize = 14f
        val searchBg = GradientDrawable()
        searchBg.setColor(Color.WHITE)
        searchBg.cornerRadius = dp(12).toFloat()
        searchBg.setStroke(dp(1), Color.parseColor("#E2E8F0"))
        searchInput.background = searchBg
        
        searchInput.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                searchQuery = s.toString()
                if (currentTab == "list") loadSubjectList() 
                else loadRequestList()
            }
            override fun afterTextChanged(s: Editable?) {}
        })
        
        searchContainer.addView(searchInput, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        root.addView(searchContainer)

        // Scrollable Content
        val scrollView = ScrollView(this)
        scrollView.isFillViewport = true
        contentLayout = LinearLayout(this)
        contentLayout.orientation = LinearLayout.VERTICAL
        contentLayout.setPadding(dp(20), dp(10), dp(20), dp(40))
        scrollView.addView(contentLayout)
        root.addView(scrollView)

        setContentView(root)

        if (currentTab == "list") loadSubjectList() 
        else loadRequestList()
    }

    private fun createTabButton(text: String, active: Boolean): TextView {
        val tv = TextView(this)
        tv.text = text
        tv.gravity = Gravity.CENTER
        tv.textSize = 15f
        tv.typeface = if (active) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        tv.setTextColor(if (active) Color.WHITE else Color.parseColor("#64748B"))

        val bg = GradientDrawable()
        bg.setColor(if (active) Color.parseColor("#8B5CF6") else Color.parseColor("#F1F5F9"))
        bg.cornerRadius = dp(12).toFloat()
        tv.background = bg

        return tv
    }

    private fun loadSubjectList() {
        contentLayout.removeAllViews()

        // Add New Subject Button
        val addBtn = TextView(this)
        addBtn.text = "+ Add New Subject"
        addBtn.setTextColor(Color.WHITE)
        addBtn.textSize = 16f
        addBtn.typeface = Typeface.DEFAULT_BOLD
        addBtn.gravity = Gravity.CENTER
        addBtn.setPadding(0, dp(14), 0, dp(14))
        val addBg = GradientDrawable()
        addBg.setColor(Color.parseColor("#10B981"))
        addBg.cornerRadius = dp(16).toFloat()
        addBtn.background = addBg
        addBtn.setOnClickListener { showAddSubjectDialog() }
        
        val addParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        addParams.setMargins(0, 0, 0, dp(24))
        contentLayout.addView(addBtn, addParams)

        FirebaseHistoryManager.getGlobalSubjects { subjects ->
            runOnUiThread {
                val filtered = subjects.filter { 
                    searchQuery.isEmpty() || it.contains(searchQuery, ignoreCase = true)
                }

                for (name in filtered) {
                    val card = createItemCard(name, "Subject Status: Active")
                    
                    val qBtn = createSmallButton("Questions", "#3B82F6")
                    qBtn.setPadding(dp(12), dp(6), dp(12), dp(6))
                    qBtn.setOnClickListener {
                        val intent = Intent(this@AdminSubjectActivity, AdminQuizActivity::class.java)
                        intent.putExtra("subject", name)
                        startActivity(intent)
                    }
                    
                    val deleteBtn = createSmallButton("Delete", "#EF4444")
                    deleteBtn.setPadding(dp(12), dp(6), dp(12), dp(6))
                    deleteBtn.setOnClickListener {
                        AlertDialog.Builder(this@AdminSubjectActivity)
                            .setTitle("Delete Subject")
                            .setMessage("Are you sure you want to delete '$name'?")
                            .setPositiveButton("Delete") { _, _ ->
                                FirebaseHistoryManager.deleteSubjectGlobally(name) { success ->
                                    runOnUiThread {
                                        if (success) {
                                            toast("Deleted")
                                            loadSubjectList()
                                        } else {
                                            toast("Delete failed")
                                        }
                                    }
                                }
                            }
                            .setNegativeButton("Cancel", null)
                            .show()
                    }

                    val row = LinearLayout(this@AdminSubjectActivity)
                    row.orientation = LinearLayout.HORIZONTAL
                    row.setPadding(0, dp(12), 0, 0)
                    row.addView(qBtn, LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT))
                    row.addView(View(this@AdminSubjectActivity), LinearLayout.LayoutParams(dp(10), 1))
                    row.addView(deleteBtn, LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT))

                    card.addView(row)
                    contentLayout.addView(card)
                }
            }
        }
    }

    private fun loadRequestList() {
        contentLayout.removeAllViews()
        
        val loading = TextView(this)
        loading.text = "Loading requests from Firestore..."
        loading.setPadding(0, dp(20), 0, 0)
        loading.gravity = Gravity.CENTER
        contentLayout.addView(loading)

        FirebaseHistoryManager.getSubjectRequests { list ->
            runOnUiThread {
                contentLayout.removeAllViews()
                
                val filtered = ArrayList<Map<String, Any>>()
                for (item in list) {
                    val status = item.get("status") as? String ?: ""
                    val subject = item.get("subject") as? String ?: ""
                    if (status.equals("pending")) {
                        if (searchQuery.length == 0 || subject.indexOf(searchQuery) != -1) {
                            filtered.add(item)
                        }
                    }
                }

                if (filtered.size == 0) {
                    val empty = TextView(this)
                    empty.text = if (searchQuery.length == 0) "No pending requests" else "No matching results"
                    empty.gravity = Gravity.CENTER
                    empty.setPadding(0, dp(100), 0, 0)
                    empty.setTextColor(Color.parseColor("#94A3B8"))
                    contentLayout.addView(empty)
                    return@runOnUiThread
                }

                for (reqMap in filtered) {
                    val reqJson = JSONObject()
                    for (entry in reqMap.entries) {
                        reqJson.put(entry.key, entry.value)
                    }
                    val card = createRequestCard(reqJson)
                    contentLayout.addView(card)
                }
            }
        }
    }

    private fun createItemCard(title: String, subtitle: String): LinearLayout {
        val card = LinearLayout(this)
        card.orientation = LinearLayout.VERTICAL
        card.setPadding(dp(20), dp(18), dp(20), dp(18))
        
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(20).toFloat()
        card.background = bg
        card.elevation = dp(4).toFloat()

        val titleTv = TextView(this)
        titleTv.text = title
        titleTv.textSize = 17f
        titleTv.typeface = Typeface.DEFAULT_BOLD
        titleTv.setTextColor(Color.parseColor("#0F172A"))

        val subTv = TextView(this)
        subTv.text = subtitle
        subTv.textSize = 13f
        subTv.setTextColor(Color.parseColor("#64748B"))
        subTv.setPadding(0, dp(4), 0, 0)

        card.addView(titleTv)
        card.addView(subTv)

        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(14))
        card.layoutParams = params
        return card
    }

    private fun createRequestCard(req: JSONObject): LinearLayout {
        val card = LinearLayout(this)
        card.orientation = LinearLayout.VERTICAL
        card.setPadding(dp(20), dp(20), dp(20), dp(20))
        
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(24).toFloat()
        card.background = bg
        card.elevation = dp(4).toFloat()

        val subName = TextView(this)
        subName.text = req.getString("subject")
        subName.textSize = 18f
        subName.typeface = Typeface.DEFAULT_BOLD
        subName.setTextColor(Color.parseColor("#1E1B4B"))

        val byText = TextView(this)
        byText.text = "Requested by: " + req.getString("by")
        byText.textSize = 14f
        byText.setTextColor(Color.parseColor("#64748B"))
        byText.setPadding(0, dp(4), 0, dp(16))

        val btnLayout = LinearLayout(this)
        btnLayout.orientation = LinearLayout.HORIZONTAL
        
        val acceptBtn = createSmallButton("Accept", "#10B981")
        val rejectBtn = createSmallButton("Reject", "#EF4444")
        val editBtn = createSmallButton("Edit", "#3B82F6")
        
        acceptBtn.setOnClickListener {
            val requestId = req.getString("id")
            val subNameStr = req.getString("subject")
            
            FirebaseHistoryManager.updateSubjectRequestStatus(requestId, "accepted") { success ->
                if (success) {
                    FirebaseHistoryManager.addSubjectGlobally(subNameStr) { globalSuccess ->
                        runOnUiThread {
                            if (globalSuccess) {
                                toast("Subject Accepted & Added Globally")
                                loadRequestList()
                            } else {
                                toast("Failed to add subject globally")
                            }
                        }
                    }
                } else {
                    runOnUiThread { toast("Failed to update status") }
                }
            }
        }
        rejectBtn.setOnClickListener {
            val requestId = req.getString("id")
            FirebaseHistoryManager.updateSubjectRequestStatus(requestId, "rejected") { success ->
                runOnUiThread {
                    if (success) {
                        toast("Subject Rejected")
                        loadRequestList()
                    } else {
                        toast("Failed to update status")
                    }
                }
            }
        }
        editBtn.setOnClickListener {
            showEditRequestDialog(req)
        }

        btnLayout.addView(acceptBtn, LinearLayout.LayoutParams(0, dp(40), 1f))
        btnLayout.addView(View(this), LinearLayout.LayoutParams(dp(8), dp(1)))
        btnLayout.addView(editBtn, LinearLayout.LayoutParams(0, dp(40), 1f))
        btnLayout.addView(View(this), LinearLayout.LayoutParams(dp(8), dp(1)))
        btnLayout.addView(rejectBtn, LinearLayout.LayoutParams(0, dp(40), 1f))

        card.addView(subName)
        card.addView(byText)
        card.addView(btnLayout)

        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(16))
        card.layoutParams = params
        return card
    }

    private fun createSmallButton(text: String, color: String): TextView {
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
        return tv
    }

    private fun showAddSubjectDialog() {
        val input = EditText(this)
        input.hint = "Enter subject name"
        val container = LinearLayout(this)
        container.setPadding(dp(24), dp(16), dp(24), 0)
        container.addView(input, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))

        AlertDialog.Builder(this)
            .setTitle("Add New Subject")
            .setView(container)
            .setPositiveButton("Add") { _, _ ->
                val name = input.text.toString().trim()
                if (name.isNotEmpty()) {
                    FirebaseHistoryManager.addSubjectGlobally(name) { success ->
                        runOnUiThread {
                            if (success) {
                                toast("Subject added globally")
                                loadSubjectList()
                            } else {
                                toast("Failed to add subject")
                            }
                        }
                    }
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun showEditRequestDialog(req: JSONObject) {
        val input = EditText(this)
        input.setText(req.getString("subject"))
        val container = LinearLayout(this)
        container.setPadding(dp(24), dp(16), dp(24), 0)
        container.addView(input, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))

        AlertDialog.Builder(this)
            .setTitle("Edit & Accept Request")
            .setView(container)
            .setPositiveButton("Save & Accept") { _, _ ->
                val name = input.text.toString().trim()
                if (name.isNotEmpty()) {
                    val requestId = req.getString("id")
                    FirebaseHistoryManager.updateSubjectRequestStatus(requestId, "accepted", name) { success ->
                        if (success) {
                            FirebaseHistoryManager.addSubjectGlobally(name) { globalSuccess ->
                                runOnUiThread {
                                    if (globalSuccess) {
                                        toast("Subject accepted & added")
                                        loadRequestList()
                                    } else {
                                        toast("Global add failed")
                                    }
                                }
                            }
                        } else {
                            runOnUiThread { toast("Update failed") }
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
