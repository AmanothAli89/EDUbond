package com.example.peermatrix

import android.app.Activity
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.os.CountDownTimer
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.*
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

class TeacherQuizActivity : Activity() {

    private var timer: CountDownTimer? = null
    private lateinit var timerText: TextView

    data class Question(
        val question: String,
        val options: List<String>,
        val answer: String
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val subject = intent.getStringExtra("subject") ?: ""
        val email = AppStorage.getCurrentUser(this)

        FirebaseHistoryManager.getQuizStatus(email, subject) { status ->
            val blocked = status?.get("blocked") as? Boolean ?: false
            val attempts = (status?.get("attempts") as? Long ?: 0L).toInt()
            val totalAttempts = (status?.get("totalAttempts") as? Long ?: 0L).toInt()

            runOnUiThread {
                if (blocked) {
                    toast("You are blocked from this subject.")
                    finish()
                    return@runOnUiThread
                }

                if (attempts >= 2) {
                    toast("No more attempts left.")
                    finish()
                    return@runOnUiThread
                }

                // Try to get from cloud first, fallback to local
                FirebaseHistoryManager.getQuizSets(subject) { cloudData ->
                    runOnUiThread {
                        var sets = AppStorage.getQuizSets(this@TeacherQuizActivity, subject)
                        if (cloudData != null) {
                            try {
                                val cloudArray = JSONArray(cloudData)
                                val cloudSets = mutableListOf<JSONArray>()
                                for (i in 0 until cloudArray.length()) cloudSets.add(cloudArray.getJSONArray(i))
                                if (cloudSets.isNotEmpty()) sets = cloudSets
                            } catch (e: Exception) {}
                        }
                        
                        startQuiz(subject, email, totalAttempts, sets)
                    }
                }
            }
        }
    }

    private fun startQuiz(subject: String, email: String, attempts: Int, sets: List<JSONArray>) {
        if (sets.isEmpty() || (attempts < sets.size && sets[attempts].length() < 10)) {
            val validSetIndex = (0 until sets.size).find { sets[it].length() == 10 }
            if (validSetIndex == null) {
                toast("Quiz questions are not set yet. Please contact admin.")
                finish()
                return
            }
        }
        
        val setIndex = attempts % sets.size
        val selectedSet = if (sets.isNotEmpty()) sets[setIndex] else JSONArray()
        
        if (selectedSet.length() < 10) {
            toast("Selected question set is incomplete. Contact Admin.")
            finish()
            return
        }

        val questions = mutableListOf<Question>()
        for (i in 0 until selectedSet.length()) {
            val obj = selectedSet.getJSONObject(i)
            val opts = mutableListOf<String>()
            val optArray = obj.getJSONArray("options")
            for (j in 0 until optArray.length()) opts.add(optArray.getString(j))
            questions.add(Question(obj.getString("question"), opts, obj.getString("answer")))
        }

        showRulesUI(subject, email, questions)
    }

    private fun showRulesUI(subject: String, email: String, questions: List<Question>) {
        val root = LinearLayout(this)
        root.orientation = LinearLayout.VERTICAL
        root.setBackgroundColor(Color.parseColor("#F8FBFF"))
        root.gravity = Gravity.CENTER
        root.setPadding(dp(24), dp(24), dp(24), dp(24))

        val card = LinearLayout(this)
        card.orientation = LinearLayout.VERTICAL
        card.setPadding(dp(24), dp(24), dp(24), dp(24))
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(24).toFloat()
        card.background = bg
        card.elevation = dp(8).toFloat()

        val title = title("Examination Rules")
        title.gravity = Gravity.CENTER
        card.addView(title)

        val rulesList = listOf(
            "• Subject: $subject",
            "• Time Limit: 5 Minutes",
            "• Minimum Score: 7 out of 10",
            "• Total Questions: 10",
            "• Max Attempts: 2",
            "• Quiz will auto-submit when time is up."
        )

        for (rule in rulesList) {
            val tv = TextView(this)
            tv.text = rule
            tv.textSize = 16f
            tv.setTextColor(Color.parseColor("#334155"))
            tv.setPadding(0, dp(8), 0, dp(8))
            card.addView(tv)
        }

        val startBtn = actionButton("Start Exam", "#059669")
        startBtn.setOnClickListener {
            setupUI(subject, questions, email)
        }

        val backBtn = textButton("Cancel")
        backBtn.setOnClickListener { finish() }

        card.addView(startBtn)
        card.addView(backBtn)
        root.addView(card)
        setContentView(root)
    }

    private fun setupUI(subject: String, questions: List<Question>, email: String) {
        val root = RelativeLayout(this)
        root.setBackgroundColor(Color.parseColor("#F8FBFF"))

        // Top Header with Timer
        val header = LinearLayout(this)
        header.id = View.generateViewId()
        header.orientation = LinearLayout.HORIZONTAL
        header.gravity = Gravity.CENTER_VERTICAL
        header.setPadding(dp(20), dp(16), dp(20), dp(16))
        header.setBackgroundColor(Color.WHITE)
        header.elevation = dp(4).toFloat()

        val titleTv = TextView(this)
        titleTv.text = "Quiz: $subject"
        titleTv.textSize = 18f
        titleTv.typeface = Typeface.DEFAULT_BOLD
        titleTv.setTextColor(Color.parseColor("#1E1B4B"))
        val titleParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        header.addView(titleTv, titleParams)

        timerText = TextView(this)
        timerText.text = "05:00"
        timerText.textSize = 18f
        timerText.typeface = Typeface.MONOSPACE
        timerText.setTextColor(Color.parseColor("#DC2626"))
        timerText.setPadding(dp(12), dp(6), dp(12), dp(6))
        val timerBg = GradientDrawable()
        timerBg.setColor(Color.parseColor("#FEE2E2"))
        timerBg.cornerRadius = dp(8).toFloat()
        timerText.background = timerBg
        header.addView(timerText)

        val headerParams = RelativeLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        headerParams.addRule(RelativeLayout.ALIGN_PARENT_TOP)
        root.addView(header, headerParams)

        val scrollView = ScrollView(this)
        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.VERTICAL
        layout.setPadding(dp(20), dp(24), dp(20), dp(40))
        scrollView.addView(layout)

        val scrollParams = RelativeLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        scrollParams.addRule(RelativeLayout.BELOW, header.id)
        root.addView(scrollView, scrollParams)

        val radioGroups = mutableListOf<RadioGroup>()

        for ((index, q) in questions.withIndex()) {
            val qCard = createQuestionCard(index + 1, q)
            val group = qCard.second
            radioGroups.add(group)
            layout.addView(qCard.first)
        }

        val submitButton = actionButton("Submit Quiz", "#2563EB")
        layout.addView(submitButton)

        fun performSubmit() {
            timer?.cancel()
            var score = 0
            for (i in questions.indices) {
                val selectedId = radioGroups[i].checkedRadioButtonId
                if (selectedId != -1) {
                    val selectedRadio = radioGroups[i].findViewById<RadioButton>(selectedId)
                    if (selectedRadio.text.toString() == questions[i].answer) {
                        score++
                    }
                }
            }

            val passed = score >= 7
            FirebaseHistoryManager.recordQuizResult(email, subject, passed) { _, blocked ->
                runOnUiThread {
                    if (passed) {
                        FirebaseHistoryManager.addSubjectRole(email, subject, "teacher", score) { _ ->
                            runOnUiThread {
                                toast("Congratulations! You passed with score $score/10.")
                                finish()
                            }
                        }
                    } else {
                        if (blocked) {
                            toast("Time's up or Failed. Score: $score/10. Blocked from this subject.")
                        } else {
                            toast("Failed. Score: $score/10. 1 attempt left.")
                        }
                        finish()
                    }
                }
            }
        }

        submitButton.setOnClickListener {
            var allAnswered = true
            for (group in radioGroups) {
                if (group.checkedRadioButtonId == -1) {
                    allAnswered = false
                    break
                }
            }

            if (!allAnswered) {
                toast("Please answer all questions before submitting")
            } else {
                performSubmit()
            }
        }

        setContentView(root)

        // Start Countdown Timer (5 Minutes)
        timer = object : CountDownTimer(300000, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val minutes = (millisUntilFinished / 1000) / 60
                val seconds = (millisUntilFinished / 1000) % 60
                timerText.text = String.format(Locale.getDefault(), "%02d:%02d", minutes, seconds)
                
                if (millisUntilFinished < 60000) {
                    timerText.setTextColor(Color.RED) // Last minute warning
                }
            }

            override fun onFinish() {
                timerText.text = "00:00"
                toast("Time is up! Submitting automatically...")
                performSubmit()
            }
        }.start()
    }

    private fun createQuestionCard(num: Int, q: Question): Pair<LinearLayout, RadioGroup> {
        val card = LinearLayout(this)
        card.orientation = LinearLayout.VERTICAL
        card.setPadding(dp(16), dp(16), dp(16), dp(16))
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(16).toFloat()
        card.background = bg
        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(16))
        card.layoutParams = params

        val qText = TextView(this)
        qText.text = "$num. ${q.question}"
        qText.textSize = 16f
        qText.typeface = Typeface.DEFAULT_BOLD
        qText.setTextColor(Color.parseColor("#1E1B4B"))
        card.addView(qText)

        val group = RadioGroup(this)
        group.orientation = RadioGroup.VERTICAL
        group.setPadding(0, dp(8), 0, 0)

        for (option in q.options) {
            val rb = RadioButton(this)
            rb.text = option
            rb.setTextColor(Color.parseColor("#475569"))
            rb.setPadding(dp(8), dp(8), dp(8), dp(8))
            group.addView(rb)
        }
        card.addView(group)

        return Pair(card, group)
    }

    private fun title(t: String): TextView {
        val tv = TextView(this)
        tv.text = t
        tv.textSize = 22f
        tv.typeface = Typeface.DEFAULT_BOLD
        tv.setTextColor(Color.parseColor("#1E1B4B"))
        tv.setPadding(0, 0, 0, dp(8))
        return tv
    }

    private fun subtitle(t: String): TextView {
        val tv = TextView(this)
        tv.text = t
        tv.textSize = 14f
        tv.setTextColor(Color.parseColor("#64748B"))
        tv.setPadding(0, 0, 0, dp(16))
        return tv
    }

    private fun actionButton(text: String, color: String): Button {
        val btn = Button(this)
        btn.text = text
        btn.isAllCaps = false
        btn.setTextColor(Color.WHITE)
        btn.typeface = Typeface.DEFAULT_BOLD
        val bg = GradientDrawable()
        bg.setColor(Color.parseColor(color))
        bg.cornerRadius = dp(12).toFloat()
        btn.background = bg
        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(54))
        params.setMargins(0, dp(12), 0, 0)
        btn.layoutParams = params
        return btn
    }

    private fun textButton(text: String): TextView {
        val tv = TextView(this)
        tv.text = text
        tv.textSize = 15f
        tv.setTextColor(Color.parseColor("#2563EB"))
        tv.typeface = Typeface.DEFAULT_BOLD
        tv.gravity = Gravity.CENTER
        tv.setPadding(0, dp(16), 0, 0)
        return tv
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
    private fun toast(text: String) {
        Toast.makeText(this, text, Toast.LENGTH_SHORT).show()
    }

    override fun onDestroy() {
        timer?.cancel()
        super.onDestroy()
    }
}