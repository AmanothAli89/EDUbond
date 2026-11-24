package com.example.peermatrix

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.*
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class SharedFilesActivity : Activity() {

    private lateinit var groupId: String

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        groupId = intent.getStringExtra("groupId") ?: ""
        if (groupId.isEmpty()) {
            finish()
            return
        }
        showUI()
    }

    private fun showUI() {
        val root = LinearLayout(this)
        root.orientation = LinearLayout.VERTICAL
        root.setBackgroundColor(Color.parseColor("#F8FBFF"))

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
        title.text = "Shared Files"
        title.textSize = 20f
        title.typeface = Typeface.DEFAULT_BOLD
        title.setTextColor(Color.parseColor("#1E1B4B"))

        header.addView(backBtn)
        header.addView(title)
        root.addView(header)

        val scrollView = ScrollView(this)
        val container = LinearLayout(this)
        container.orientation = LinearLayout.VERTICAL
        container.setPadding(dp(20), 0, dp(20), dp(40))
        scrollView.addView(container)
        root.addView(scrollView)

        FirebaseHistoryManager.getGroupMessages(groupId) { messages ->
            runOnUiThread {
                container.removeAllViews()
                val files = messages.filter { it.containsKey("fileUrl") }

                if (files.isEmpty()) {
                    val empty = TextView(this@SharedFilesActivity)
                    empty.text = "No files shared yet"
                    empty.gravity = Gravity.CENTER
                    empty.setPadding(0, dp(100), 0, 0)
                    empty.setTextColor(Color.parseColor("#94A3B8"))
                    container.addView(empty)
                } else {
                    for (fileMap in files) {
                        val fileJson = JSONObject()
                        for (entry in fileMap.entries) {
                            fileJson.put(entry.key, entry.value)
                        }
                        container.addView(createFileCard(fileJson))
                    }
                }
            }
        }

        setContentView(root)
    }

    private fun createFileCard(msg: JSONObject): LinearLayout {
        val card = LinearLayout(this)
        card.orientation = LinearLayout.HORIZONTAL
        card.gravity = Gravity.CENTER_VERTICAL
        card.setPadding(dp(16), dp(16), dp(16), dp(16))
        
        val bg = GradientDrawable()
        bg.setColor(Color.WHITE)
        bg.cornerRadius = dp(16).toFloat()
        card.background = bg
        card.elevation = dp(2).toFloat()

        val type = msg.optString("fileType", "")
        val icon = TextView(this)
        icon.text = if (type.contains("image")) "🖼️" else "📄"
        icon.textSize = 24f
        card.addView(icon)

        val infoLayout = LinearLayout(this)
        infoLayout.orientation = LinearLayout.VERTICAL
        infoLayout.setPadding(dp(12), 0, 0, 0)

        val nameTv = TextView(this)
        nameTv.text = msg.optString("fileName", "Unknown File")
        nameTv.textSize = 15f
        nameTv.typeface = Typeface.DEFAULT_BOLD
        nameTv.setTextColor(Color.parseColor("#1E1B4B"))

        val metaTv = TextView(this)
        val senderEmail = msg.optString("senderEmail", "")
        FirebaseHistoryManager.getUserNameGlobally(senderEmail) { name ->
            runOnUiThread {
                metaTv.text = "Shared by $name • ${SimpleDateFormat("hh:mm a", Locale.getDefault()).format(Date(msg.optLong("timestamp", 0)))}"
            }
        }
        metaTv.textSize = 12f
        metaTv.setTextColor(Color.parseColor("#64748B"))
        metaTv.setPadding(0, dp(2), 0, dp(0))

        infoLayout.addView(nameTv)
        infoLayout.addView(metaTv)
        card.addView(infoLayout, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))

        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(12))
        card.layoutParams = params
        
        card.setOnClickListener {
            val urlStr = msg.optString("fileUrl")
            val fileType = msg.optString("fileType")
            if (urlStr.isNotEmpty()) {
                openFile(urlStr, fileType)
            }
        }

        val currentUser = AppStorage.getCurrentUser(this)
        if (msg.optString("senderEmail").equals(currentUser, ignoreCase = true)) {
            card.setOnLongClickListener {
                val msgId = msg.optString("id")
                if (msgId.isNotEmpty()) {
                    android.app.AlertDialog.Builder(this)
                        .setMessage("Do you want to unsend this file?")
                        .setPositiveButton("Unsend") { _, _ ->
                            FirebaseHistoryManager.deleteMessage(groupId, msgId) { success ->
                                if (!success) toast("Failed to unsend")
                            }
                        }
                        .setNegativeButton("Cancel", null)
                        .show()
                }
                true
            }
        }
        
        return card
    }

    private fun openFile(urlStr: String, type: String) {
        try {
            val uri = Uri.parse(urlStr)
            if (urlStr.startsWith("http")) {
                startActivity(Intent(Intent.ACTION_VIEW, uri))
                return
            }
            val intent = Intent(Intent.ACTION_VIEW)
            intent.setDataAndType(uri, type)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
            startActivity(intent)
        } catch (e: Exception) {
            toast("Could not open file")
        }
    }

    private fun toast(m: String) = Toast.makeText(this, m, Toast.LENGTH_SHORT).show()

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
}