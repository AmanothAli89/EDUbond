package com.example.peermatrix

import android.app.Activity
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.*
import org.json.JSONArray
import org.json.JSONObject

class AdminQuizActivity : Activity() {

    private lateinit var subject: String
    private lateinit var container: LinearLayout
    private var selectedSetIndex = 0 // 0 to 3
    private val allSets = mutableListOf<JSONArray>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        subject = intent.getStringExtra("subject") ?: ""
        if (subject.isEmpty()) {
            finish()
            return
        }

        loadData()
        showMainUI()
    }

    private fun loadData() {
        // First load from local for speed
        val sets = AppStorage.getQuizSets(this, subject)
        allSets.clear()
        allSets.addAll(sets)
        while (allSets.size < 4) allSets.add(JSONArray())

        // Then sync from Firebase
        FirebaseHistoryManager.getQuizSets(subject) { cloudData ->
            if (cloudData != null) {
                try {
                    val cloudArray = JSONArray(cloudData)
                    val newSets = mutableListOf<JSONArray>()
                    for (i in 0 until cloudArray.length()) {
                        newSets.add(cloudArray.getJSONArray(i))
                    }
                    if (newSets.isNotEmpty()) {
                        runOnUiThread {
                            allSets.clear()
                            allSets.addAll(newSets)
                            while (allSets.size < 4) allSets.add(JSONArray())
                            refreshSetUI()
                        }
                    }
                } catch (e: Exception) {}
            }
        }
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
        title.text = "Quiz Sets: $subject"
        title.textSize = 20f
        title.typeface = Typeface.DEFAULT_BOLD
        title.setTextColor(Color.parseColor("#1E1B4B"))

        header.addView(backBtn)
        header.addView(title)
        root.addView(header)

        // Set Selector
        val selectorScroll = HorizontalScrollView(this)
        val selectorLayout = LinearLayout(this)
        selectorLayout.orientation = LinearLayout.HORIZONTAL
        selectorLayout.setPadding(dp(20), 0, dp(20), dp(16))
        
        for (i in 0..3) {
            val setBtn = createSetButton(i)
            selectorLayout.addView(setBtn)
        }
        selectorScroll.addView(selectorLayout)
        root.addView(selectorScroll)

        val scrollView = ScrollView(this)
        container = LinearLayout(this)
        container.orientation = LinearLayout.VERTICAL
        container.setPadding(dp(20), 0, dp(20), dp(40))
        scrollView.addView(container)
        root.addView(scrollView)

        setContentView(root)
        refreshSetUI()
    }

    private fun createSetButton(index: Int): TextView {
        val tv = TextView(this)
        tv.text = "Set ${index + 1}"
        tv.setPadding(dp(16), dp(8), dp(16), dp(8))
        tv.textSize = 14f
        tv.typeface = Typeface.DEFAULT_BOLD
        
        val bg = GradientDrawable()
        bg.cornerRadius = dp(20).toFloat()
        if (selectedSetIndex == index) {
            bg.setColor(Color.parseColor("#2563EB"))
            tv.setTextColor(Color.WHITE)
        } else {
            bg.setColor(Color.WHITE)
            bg.setStroke(dp(1), Color.parseColor("#CBD5E1"))
            tv.setTextColor(Color.parseColor("#64748B"))
        }
        tv.background = bg
        
        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, dp(10), 0)
        tv.layoutParams = params
        
        tv.setOnClickListener {
            selectedSetIndex = index
            showMainUI() // Refresh everything
        }
        
        return tv
    }

    private fun refreshSetUI() {
        container.removeAllViews()
        val currentSet = allSets[selectedSetIndex]
        
        val desc = TextView(this)
        desc.text = "Configure 10 MCQs for Set ${selectedSetIndex + 1}"
        desc.textSize = 14f
        desc.setTextColor(Color.parseColor("#64748B"))
        desc.setPadding(0, 0, 0, dp(20))
        container.addView(desc)

        val inputFields = mutableListOf<QuizInputGroup>()

        for (i in 0 until 10) {
            val existing = if (i < currentSet.length()) currentSet.getJSONObject(i) else null
            val group = QuizInputGroup(i + 1, existing)
            inputFields.add(group)
            container.addView(group.view)
        }

        val saveBtn = Button(this)
        saveBtn.text = "Save Set ${selectedSetIndex + 1}"
        saveBtn.setTextColor(Color.WHITE)
        saveBtn.typeface = Typeface.DEFAULT_BOLD
        saveBtn.isAllCaps = false
        val bg = GradientDrawable()
        bg.setColor(Color.parseColor("#10B981"))
        bg.cornerRadius = dp(12).toFloat()
        saveBtn.background = bg
        
        saveBtn.setOnClickListener {
            val newSet = JSONArray()
            try {
                for (group in inputFields) {
                    val q = group.getQuestionData()
                    newSet.put(q)
                }
                allSets[selectedSetIndex] = newSet
                
                val finalArray = JSONArray()
                for (s in allSets) finalArray.put(s)
                
                // Save Locally
                AppStorage.saveQuizSets(this, subject, finalArray)
                
                // Save to Firebase for all users
                FirebaseHistoryManager.saveQuizSets(subject, finalArray.toString()) { success ->
                    runOnUiThread {
                        if (success) {
                            Toast.makeText(this, "Set ${selectedSetIndex + 1} Saved to Cloud!", Toast.LENGTH_SHORT).show()
                        } else {
                            Toast.makeText(this, "Saved locally, but failed to upload to cloud.", Toast.LENGTH_SHORT).show()
                        }
                    }
                }
            } catch (e: Exception) {
                Toast.makeText(this, "Please fill all fields for 10 questions", Toast.LENGTH_SHORT).show()
            }
        }

        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(54))
        params.setMargins(0, dp(20), 0, 0)
        container.addView(saveBtn, params)
    }

    inner class QuizInputGroup(val num: Int, existing: JSONObject?) {
        val view = LinearLayout(this@AdminQuizActivity)
        val qInput: EditText
        val opt1: EditText
        val opt2: EditText
        val opt3: EditText
        val opt4: EditText
        val ansInput: EditText

        init {
            view.orientation = LinearLayout.VERTICAL
            view.setPadding(dp(16), dp(16), dp(16), dp(16))
            val bg = GradientDrawable()
            bg.setColor(Color.WHITE)
            bg.cornerRadius = dp(16).toFloat()
            bg.setStroke(dp(1), Color.parseColor("#E2E8F0"))
            view.background = bg
            val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
            params.setMargins(0, 0, 0, dp(16))
            view.layoutParams = params

            val label = TextView(this@AdminQuizActivity)
            label.text = "Question $num"
            label.typeface = Typeface.DEFAULT_BOLD
            label.setTextColor(Color.parseColor("#1E1B4B"))
            view.addView(label)

            qInput = createEditField("Question Text", existing?.optString("question") ?: "")
            opt1 = createEditField("Option 1", existing?.optJSONArray("options")?.optString(0) ?: "")
            opt2 = createEditField("Option 2", existing?.optJSONArray("options")?.optString(1) ?: "")
            opt3 = createEditField("Option 3", existing?.optJSONArray("options")?.optString(2) ?: "")
            opt4 = createEditField("Option 4", existing?.optJSONArray("options")?.optString(3) ?: "")
            ansInput = createEditField("Correct Answer (must match one option)", existing?.optString("answer") ?: "")

            view.addView(qInput)
            view.addView(opt1)
            view.addView(opt2)
            view.addView(opt3)
            view.addView(opt4)
            view.addView(ansInput)
        }

        private fun createEditField(hint: String, value: String): EditText {
            val et = EditText(this@AdminQuizActivity)
            et.hint = hint
            et.setText(value)
            et.textSize = 14f
            et.setPadding(dp(12), dp(10), dp(12), dp(10))
            val bg = GradientDrawable()
            bg.setColor(Color.parseColor("#F1F5F9"))
            bg.cornerRadius = dp(8).toFloat()
            et.background = bg
            val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
            params.setMargins(0, dp(8), 0, 0)
            et.layoutParams = params
            return et
        }

        fun getQuestionData(): JSONObject {
            val q = qInput.text.toString().trim()
            val o1 = opt1.text.toString().trim()
            val o2 = opt2.text.toString().trim()
            val o3 = opt3.text.toString().trim()
            val o4 = opt4.text.toString().trim()
            val ans = ansInput.text.toString().trim()

            if (q.isEmpty() || o1.isEmpty() || o2.isEmpty() || o3.isEmpty() || o4.isEmpty() || ans.isEmpty()) {
                throw Exception("Empty fields")
            }

            val obj = JSONObject()
            obj.put("question", q)
            val opts = JSONArray()
            opts.put(o1)
            opts.put(o2)
            opts.put(o3)
            opts.put(o4)
            obj.put("options", opts)
            obj.put("answer", ans)
            return obj
        }
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
}