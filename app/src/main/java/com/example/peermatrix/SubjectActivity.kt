package com.example.peermatrix

import android.app.Activity
import android.content.Context
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
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast

class SubjectActivity : Activity() {

    private lateinit var listLayout: LinearLayout
    private var allSubjects: List<String> = emptyList()
    private lateinit var searchInput: EditText
    private var isListVisible = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

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

        val title = TextView(this)
        title.text = "Subject Search"
        title.textSize = 26f
        title.typeface = Typeface.DEFAULT_BOLD
        title.setTextColor(Color.parseColor("#1E1B4B"))
        header.addView(title)
        root.addView(header)

        // Search Section Card
        val searchCard = createCard()
        
        searchInput = EditText(this)
        searchInput.hint = "Search subject, e.g. Data S"
        searchInput.textSize = 16f
        searchInput.setPadding(dp(16), dp(14), dp(16), dp(14))
        val searchBg = GradientDrawable()
        searchBg.setColor(Color.parseColor("#F1F5F9"))
        searchBg.cornerRadius = dp(14).toFloat()
        searchBg.setStroke(dp(1), Color.parseColor("#CBD5E1"))
        searchInput.background = searchBg
        
        val searchParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        searchParams.setMargins(0, 0, 0, dp(16))
        searchCard.addView(searchInput, searchParams)

        val requestBtn = actionButton("REQUEST NEW SUBJECT ADD", "#0D9466")
        searchCard.addView(requestBtn)
        
        root.addView(searchCard)

        // List Toggle Header
        val listHeader = LinearLayout(this)
        listHeader.orientation = LinearLayout.HORIZONTAL
        listHeader.gravity = Gravity.CENTER_VERTICAL
        listHeader.setPadding(0, dp(12), 0, dp(12))
        listHeader.isClickable = true
        listHeader.isFocusable = true

        val listTitle = TextView(this)
        listTitle.text = "Subject List:"
        listTitle.textSize = 18f
        listTitle.typeface = Typeface.DEFAULT_BOLD
        listTitle.setTextColor(Color.parseColor("#475569"))
        
        val toggleHint = TextView(this)
        toggleHint.text = " (Click to show)"
        toggleHint.textSize = 13f
        toggleHint.setTextColor(Color.parseColor("#94A3B8"))
        
        listHeader.addView(listTitle)
        listHeader.addView(toggleHint)
        root.addView(listHeader)

        listLayout = LinearLayout(this)
        listLayout.orientation = LinearLayout.VERTICAL
        listLayout.visibility = View.VISIBLE
        root.addView(listLayout)

        // Back Button at the bottom
        val backBtn = actionButton("BACK", "#334155")
        val backParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(56))
        backParams.setMargins(0, dp(32), 0, 0)
        root.addView(backBtn, backParams)

        scrollView.addView(root)
        setContentView(scrollView)

        FirebaseHistoryManager.getGlobalSubjects { list ->
            runOnUiThread {
                allSubjects = list
                showSubjects("") // Initial load
            }
        }

        listHeader.setOnClickListener {
            toggleList(!isListVisible)
        }

        // Initialize as visible
        isListVisible = true
        toggleList(true)

        searchInput.addTextChangedListener(object : TextWatcher {
            override fun afterTextChanged(s: Editable?) {
                val query = s.toString().trim()
                if (query.isNotEmpty()) {
                    toggleList(true)
                }
                showSubjects(query)
            }
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
        })

        requestBtn.setOnClickListener {
            val subjectName = searchInput.text.toString().trim()
            if (subjectName.isEmpty()) {
                toast("Please enter a subject name in the search box first.")
                return@setOnClickListener
            }
            
            FirebaseHistoryManager.submitSubjectRequest(subjectName, email) { success ->
                runOnUiThread {
                    if (success) {
                        toast("Subject add request sent to admin")
                    } else {
                        toast("Failed to send request")
                    }
                }
            }
        }

        backBtn.setOnClickListener { finish() }
    }

    private fun toggleList(show: Boolean) {
        isListVisible = show
        listLayout.visibility = if (show) View.VISIBLE else View.GONE
    }

    private fun showSubjects(query: String) {
        listLayout.removeAllViews()

        val filtered = allSubjects.filter {
            it.contains(query, ignoreCase = true)
        }

        if (filtered.isEmpty() && query.isNotEmpty()) {
            val emptyTv = TextView(this)
            emptyTv.text = "No matching subjects found."
            emptyTv.textSize = 15f
            emptyTv.setTextColor(Color.parseColor("#94A3B8"))
            emptyTv.setPadding(dp(12), dp(16), 0, 0)
            listLayout.addView(emptyTv)
            return
        }

        for (subject in filtered) {
            val subCard = createItemCard(subject)
            subCard.setOnClickListener {
                val intent = Intent(this, SubjectDetailActivity::class.java)
                intent.putExtra("subject", subject.trim())
                startActivity(intent)
            }
            listLayout.addView(subCard)
        }
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
        return card
    }

    private fun createItemCard(title: String): LinearLayout {
        val card = LinearLayout(this)
        card.orientation = LinearLayout.HORIZONTAL
        card.gravity = Gravity.CENTER_VERTICAL
        card.setPadding(dp(20), dp(18), dp(20), dp(18))
        
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(16).toFloat()
        card.background = bg
        card.elevation = dp(2).toFloat()

        val tv = TextView(this)
        tv.text = title.uppercase()
        tv.textSize = 15f
        tv.typeface = Typeface.DEFAULT_BOLD
        tv.setTextColor(Color.parseColor("#334155"))
        tv.gravity = Gravity.CENTER
        
        card.addView(tv, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))

        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, dp(8), 0, dp(8))
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
    private fun toast(m: String) = Toast.makeText(this, m, Toast.LENGTH_SHORT).show()
}