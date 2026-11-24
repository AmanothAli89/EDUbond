package com.example.peermatrix

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.*
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class GroupRoomActivity : Activity() {

    private val PICK_FILE_REQUEST = 101
    private lateinit var groupId: String
    private lateinit var messageInput: EditText
    private lateinit var chatContainer: LinearLayout
    private lateinit var scrollView: ScrollView
    private lateinit var groupName: String

    private lateinit var titleTv: TextView
    private lateinit var subTv: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        groupId = intent.getStringExtra("groupId") ?: ""
        groupName = intent.getStringExtra("groupName") ?: "Group"
        
        if (groupId.isEmpty()) {
            finish()
            return
        }

        setupChatUI()
        loadGroupInfo()
        observeMessages() // Use real-time updates from Firebase
    }

    private fun loadGroupInfo() {
        FirebaseHistoryManager.getGroupInfo(groupId) { data ->
            if (data != null) {
                runOnUiThread {
                    groupName = data["name"] as? String ?: groupName
                    titleTv.text = groupName
                    
                    val teachers = data["teachers"] as? List<String> ?: emptyList()
                    if (teachers.isNotEmpty()) {
                        subTv.text = "Teachers: ${teachers.joinToString(", ")}"
                    } else {
                        subTv.text = "tap for group info"
                    }
                }
            }
        }
    }

    private fun observeMessages() {
        FirebaseHistoryManager.getGroupMessages(groupId) { messages ->
            runOnUiThread {
                chatContainer.removeAllViews()
                val email = AppStorage.getCurrentUser(this)
                for (data in messages) {
                    val senderEmail = data["senderEmail"] as? String ?: ""
                    val text = data["message"] as? String ?: ""
                    val isMe = senderEmail.equals(email, ignoreCase = true)
                    val timeMillis = data["timestamp"] as? Long ?: 0L
                    val timeStr = SimpleDateFormat("hh:mm a", Locale.getDefault()).format(Date(timeMillis))
                    
                    val seenBy = data["seenBy"] as? List<String> ?: emptyList()
                    val msgId = data["id"] as? String ?: ""
                    if (!seenBy.contains(email)) {
                        FirebaseHistoryManager.markMessageAsRead(groupId, msgId, email)
                    }

                    addChatBubble(
                        msgId,
                        text,
                        senderEmail,
                        timeStr,
                        isMe,
                        data["fileName"] as? String ?: "",
                        data["fileType"] as? String ?: "",
                        data["fileUrl"] as? String ?: "",
                        seenBy
                    )
                }
                scrollView.post { scrollView.fullScroll(View.FOCUS_DOWN) }
            }
        }
    }

    private fun setupChatUI() {
        val root = RelativeLayout(this)
        root.fitsSystemWindows = true // Handle status bar and navigation bar
        root.setBackgroundColor(Color.parseColor("#E5DDD5")) // WhatsApp-ish background

        // 1. Header (WhatsApp Style)
        val header = LinearLayout(this)
        header.id = View.generateViewId()
        header.orientation = LinearLayout.HORIZONTAL
        header.gravity = Gravity.CENTER_VERTICAL
        header.setBackgroundColor(Color.parseColor("#075E54")) // WhatsApp Green
        header.setPadding(dp(12), dp(12), dp(12), dp(12))

        val backBtn = TextView(this)
        backBtn.text = "←"
        backBtn.textSize = 22f
        backBtn.setTextColor(Color.WHITE)
        backBtn.setPadding(0, 0, dp(16), 0)
        backBtn.setOnClickListener { finish() }

        val titleLayout = LinearLayout(this)
        titleLayout.orientation = LinearLayout.VERTICAL
        titleLayout.layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)

        titleTv = TextView(this)
        titleTv.text = groupName
        titleTv.textSize = 18f
        titleTv.typeface = Typeface.DEFAULT_BOLD
        titleTv.setTextColor(Color.WHITE)

        subTv = TextView(this)
        subTv.text = "loading info..."
        subTv.textSize = 12f
        subTv.setTextColor(Color.parseColor("#B3FFFFFF"))

        titleLayout.addView(titleTv)
        titleLayout.addView(subTv)
        titleLayout.setOnClickListener {
            val intent = Intent(this, GroupInfoActivity::class.java)
            intent.putExtra("groupId", groupId)
            startActivity(intent)
        }

        val menuBtn = TextView(this)
        menuBtn.text = "⋮"
        menuBtn.textSize = 24f
        menuBtn.setTextColor(Color.WHITE)
        menuBtn.setPadding(dp(12), 0, dp(4), 0)
        menuBtn.setOnClickListener {
            val popup = PopupMenu(this, it)
            popup.menu.add("Group Info")
            popup.setOnMenuItemClickListener { menuItem ->
                when (menuItem.title) {
                    "Group Info" -> {
                        val intent = Intent(this, GroupInfoActivity::class.java)
                        intent.putExtra("groupId", groupId)
                        startActivity(intent)
                    }
                }
                true
            }
            popup.show()
        }

        header.addView(backBtn)
        header.addView(titleLayout)
        header.addView(menuBtn)

        val headerParams = RelativeLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        headerParams.addRule(RelativeLayout.ALIGN_PARENT_TOP)
        root.addView(header, headerParams)

        // 2. Message Input Area (Bottom)
        val bottomBar = LinearLayout(this)
        bottomBar.id = View.generateViewId()
        bottomBar.orientation = LinearLayout.HORIZONTAL
        bottomBar.gravity = Gravity.CENTER_VERTICAL
        // Increased padding to lift the input bar slightly
        bottomBar.setPadding(dp(8), dp(8), dp(8), dp(16))

        val inputWrapper = LinearLayout(this)
        inputWrapper.orientation = LinearLayout.HORIZONTAL
        inputWrapper.gravity = Gravity.CENTER_VERTICAL
        val inputBg = GradientDrawable()
        inputBg.setColor(Color.WHITE)
        inputBg.cornerRadius = dp(28).toFloat()
        inputWrapper.background = inputBg
        inputWrapper.setPadding(dp(16), 0, dp(16), 0)
        inputWrapper.elevation = dp(2).toFloat()
        
        val shareBtn = TextView(this)
        shareBtn.text = "📎"
        shareBtn.textSize = 20f
        shareBtn.setPadding(0, 0, dp(12), 0)
        shareBtn.setOnClickListener { openFilePicker() }

        val meetBtn = TextView(this)
        meetBtn.text = "📹"
        meetBtn.textSize = 20f
        meetBtn.setPadding(0, 0, dp(8), 0)
        meetBtn.setOnClickListener { showMeetingDialog() }

        messageInput = EditText(this)
        messageInput.hint = "Message"
        messageInput.background = null
        messageInput.textSize = 16f
        messageInput.setPadding(dp(4), dp(12), dp(4), dp(12))
        val messageParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        
        inputWrapper.addView(shareBtn)
        inputWrapper.addView(meetBtn)
        inputWrapper.addView(messageInput, messageParams)

        val sendBtn = View(this)
        val sendBg = GradientDrawable()
        sendBg.setColor(Color.parseColor("#075E54"))
        sendBg.shape = GradientDrawable.OVAL
        sendBtn.background = sendBg
        
        val sendIcon = SendIconView(this)
        val sendBtnWrapper = FrameLayout(this)
        sendBtnWrapper.elevation = dp(3).toFloat() // Added elevation to send button
        sendBtnWrapper.addView(sendBtn, FrameLayout.LayoutParams(dp(50), dp(50)))
        val iconParams = FrameLayout.LayoutParams(dp(26), dp(26))
        iconParams.gravity = Gravity.CENTER
        sendBtnWrapper.addView(sendIcon, iconParams)
        
        sendBtnWrapper.setOnClickListener { sendMessage() }

        val inputBarParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        inputBarParams.setMargins(dp(2), 0, dp(4), 0)
        bottomBar.addView(inputWrapper, inputBarParams)

        bottomBar.addView(sendBtnWrapper)

        val bottomParams = RelativeLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        bottomParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
        root.addView(bottomBar, bottomParams)

        // 3. Chat Area (Middle)
        scrollView = ScrollView(this)
        chatContainer = LinearLayout(this)
        chatContainer.orientation = LinearLayout.VERTICAL
        chatContainer.setPadding(dp(12), dp(16), dp(12), dp(16))
        scrollView.addView(chatContainer)

        val scrollParams = RelativeLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        scrollParams.addRule(RelativeLayout.BELOW, header.id)
        scrollParams.addRule(RelativeLayout.ABOVE, bottomBar.id)
        root.addView(scrollView, scrollParams)

        setContentView(root)
    }

    private fun addChatBubble(msgId: String, text: String, senderEmail: String, time: String, isMe: Boolean, fileName: String = "", fileType: String = "", fileUri: String = "", seenBy: List<String> = emptyList()) {
        val bubbleWrapper = LinearLayout(this)
        bubbleWrapper.orientation = LinearLayout.VERTICAL
        bubbleWrapper.gravity = if (isMe) Gravity.END else Gravity.START
        bubbleWrapper.setPadding(0, 0, 0, dp(8))

        val bubble = LinearLayout(this)
        bubble.orientation = LinearLayout.VERTICAL
        bubble.setPadding(dp(12), dp(8), dp(12), dp(8))
        
        val bg = GradientDrawable()
        bg.setColor(if (isMe) Color.parseColor("#DCF8C6") else Color.WHITE)
        bg.cornerRadius = dp(12).toFloat()
        bubble.background = bg
        bubble.elevation = dp(1).toFloat()

        if (!isMe) {
            val nameTv = TextView(this)
            FirebaseHistoryManager.getUserNameGlobally(senderEmail) { name ->
                runOnUiThread { nameTv.text = name }
            }
            nameTv.textSize = 12f
            nameTv.typeface = Typeface.DEFAULT_BOLD
            nameTv.setTextColor(Color.parseColor("#075E54"))
            bubble.addView(nameTv)
        }

        if (fileName.isNotEmpty()) {
            val isMeeting = fileType == "meeting"
            val fileBox = LinearLayout(this)
            fileBox.orientation = LinearLayout.HORIZONTAL
            fileBox.gravity = Gravity.CENTER_VERTICAL
            fileBox.setPadding(dp(12), dp(12), dp(12), dp(12))
            val fileBg = GradientDrawable()
            fileBg.setColor(if (isMeeting) Color.parseColor("#EEF2FF") else Color.parseColor("#F1F5F9"))
            fileBg.cornerRadius = dp(12).toFloat()
            if (isMeeting) fileBg.setStroke(dp(1), Color.parseColor("#6366F1"))
            fileBox.background = fileBg

            val fileIcon = TextView(this)
            fileIcon.text = if (isMeeting) "📹" else (if (fileType.contains("image")) "🖼️" else "📄")
            fileIcon.textSize = 22f
            fileBox.addView(fileIcon)

            val textLayout = LinearLayout(this)
            textLayout.orientation = LinearLayout.VERTICAL
            textLayout.setPadding(dp(12), 0, 0, 0)

            val fileNameTv = TextView(this)
            fileNameTv.text = if (isMeeting) "$fileName Meeting" else fileName
            fileNameTv.textSize = 14f
            fileNameTv.typeface = Typeface.DEFAULT_BOLD
            fileNameTv.setTextColor(if (isMeeting) Color.parseColor("#4338CA") else Color.parseColor("#2563EB"))
            textLayout.addView(fileNameTv)

            if (isMeeting) {
                val joinTv = TextView(this)
                joinTv.text = "Click to Join"
                joinTv.textSize = 12f
                joinTv.setTextColor(Color.parseColor("#6366F1"))
                textLayout.addView(joinTv)
            }

            fileBox.addView(textLayout)
            bubble.addView(fileBox)
            fileBox.setOnClickListener { 
                if (isMeeting) openMeeting(fileUri) else openFile(fileUri, fileType) 
            }
        }

        if (text.isNotEmpty()) {
            val msgTv = TextView(this)
            msgTv.text = text
            msgTv.textSize = 15f
            msgTv.setTextColor(Color.BLACK)
            if (fileName.isNotEmpty()) msgTv.setPadding(0, dp(8), 0, 0)
            
            // Enable auto-linking for URLs, emails, and phone numbers
            android.text.util.Linkify.addLinks(msgTv, android.text.util.Linkify.WEB_URLS or android.text.util.Linkify.EMAIL_ADDRESSES)
            msgTv.setLinkTextColor(Color.parseColor("#2563EB"))

            bubble.addView(msgTv)
        }

        val timeLayout = LinearLayout(this)
        timeLayout.orientation = LinearLayout.HORIZONTAL
        timeLayout.gravity = Gravity.END
        timeLayout.setPadding(0, dp(2), 0, 0)

        val timeTv = TextView(this)
        timeTv.text = time
        timeTv.textSize = 10f
        timeTv.setTextColor(Color.GRAY)
        timeLayout.addView(timeTv)

        if (isMe) {
            val statusTv = TextView(this)
            statusTv.textSize = 11f
            statusTv.setPadding(dp(4), 0, 0, 0)
            if (seenBy.size > 1) {
                statusTv.text = "✓✓"
                statusTv.setTextColor(Color.parseColor("#34B7F1")) // Seen blue
            } else {
                statusTv.text = "✓"
                statusTv.setTextColor(Color.GRAY)
            }
            timeLayout.addView(statusTv)
        }

        bubble.addView(timeLayout)

        val bubbleParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        val margin = dp(40)
        if (isMe) bubbleParams.setMargins(margin, 0, 0, 0) else bubbleParams.setMargins(0, 0, margin, 0)
        
        bubbleWrapper.addView(bubble, bubbleParams)
        chatContainer.addView(bubbleWrapper)

        bubble.setOnLongClickListener {
            if (isMe) {
                showUnsendDialog(msgId)
            }
            true
        }
    }

    private fun showUnsendDialog(msgId: String) {
        if (msgId.isEmpty()) {
            toast("Cannot unsend old messages sent before this update.")
            return
        }
        android.app.AlertDialog.Builder(this)
            .setMessage("Do you want to unsend this message?")
            .setPositiveButton("Unsend") { _, _ ->
                FirebaseHistoryManager.deleteMessage(groupId, msgId) { success ->
                    if (!success) toast("Failed to unsend")
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun showMeetingDialog() {
        val dialogView = LinearLayout(this)
        dialogView.orientation = LinearLayout.VERTICAL
        dialogView.setPadding(dp(24), dp(20), dp(24), dp(24))

        val title = TextView(this)
        title.text = "Share Meeting Link"
        title.textSize = 18f
        title.typeface = Typeface.DEFAULT_BOLD
        title.setPadding(0, 0, 0, dp(16))
        dialogView.addView(title)

        val linkInput = EditText(this)
        linkInput.hint = "Paste Google Meet, Zoom, or Jitsi link"
        linkInput.setPadding(dp(12), dp(12), dp(12), dp(12))
        val bg = GradientDrawable()
        bg.setColor(Color.parseColor("#F3F4F6"))
        bg.cornerRadius = dp(8).toFloat()
        linkInput.background = bg
        dialogView.addView(linkInput)

        val helperText = TextView(this)
        helperText.text = "Example: meet.google.com/abc-defg-hij"
        helperText.textSize = 12f
        helperText.setTextColor(Color.GRAY)
        helperText.setPadding(dp(4), dp(8), 0, dp(20))
        dialogView.addView(helperText)

        val alertDialog = android.app.AlertDialog.Builder(this)
            .setView(dialogView)
            .setPositiveButton("Share", null)
            .setNegativeButton("Cancel", null)
            .create()

        alertDialog.show()

        alertDialog.getButton(android.app.AlertDialog.BUTTON_POSITIVE).setOnClickListener {
            val url = linkInput.text.toString().trim()
            if (url.isEmpty()) {
                toast("Please enter a link")
                return@setOnClickListener
            }
            if (!url.startsWith("http")) {
                toast("Please enter a valid URL")
                return@setOnClickListener
            }

            val platform = when {
                url.contains("zoom") -> "Zoom"
                url.contains("meet.google") -> "Google Meet"
                url.contains("jitsi") -> "Jitsi"
                else -> "Live"
            }

            val email = AppStorage.getCurrentUser(this)
            FirebaseHistoryManager.saveMeetingLink(groupId, email, url, platform)
            alertDialog.dismiss()
        }
    }

    private fun openMeeting(url: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            startActivity(intent)
        } catch (e: Exception) {
            toast("Could not open meeting link")
        }
    }

    private fun openFile(urlStr: String, type: String) {
        try {
            val uri = Uri.parse(urlStr)
            
            // If it's a remote URL (like Firebase or Catbox), prefer opening in browser
            // to avoid "connect to a network" errors in external apps that expect local files
            if (urlStr.startsWith("http")) {
                val browserIntent = Intent(Intent.ACTION_VIEW, uri)
                startActivity(browserIntent)
                return
            }
            
            // For Office documents (PPTX, DOCX, XLSX), use Google Docs Viewer for reliable viewing
            val isOfficeDoc = type.contains("officedocument") || 
                             type.contains("ms-powerpoint") || 
                             type.contains("msword") || 
                             type.contains("ms-excel") ||
                             urlStr.endsWith(".pptx") || urlStr.endsWith(".docx")
            
            if (isOfficeDoc) {
                val viewerUrl = "https://docs.google.com/viewer?url=" + Uri.encode(urlStr)
                val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(viewerUrl))
                startActivity(browserIntent)
                return
            }

            val intent = Intent(Intent.ACTION_VIEW)
            intent.setDataAndType(uri, type)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
            } else {
                val browserIntent = Intent(Intent.ACTION_VIEW, uri)
                startActivity(browserIntent)
            }
        } catch (e: Exception) {
            toast("Could not open file. Make sure you have a viewer app installed.")
        }
    }

    private fun openFilePicker() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
        intent.addCategory(Intent.CATEGORY_OPENABLE)
        intent.type = "*/*"
        startActivityForResult(intent, PICK_FILE_REQUEST)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_FILE_REQUEST && resultCode == RESULT_OK && data != null) {
            val uri = data.data ?: return
            
            // Take persistable permission
            val takeFlags: Int = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            try {
                contentResolver.takePersistableUriPermission(uri, takeFlags)
            } catch (e: Exception) {
                // Some providers don't support persistable permissions
            }

            handleFileSelection(uri)
        }
    }

    private fun handleFileSelection(uri: Uri) {
        var fileName = "File"
        val fileType = contentResolver.getType(uri) ?: "application/octet-stream"
        
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (cursor.moveToFirst()) {
                fileName = cursor.getString(nameIndex)
            }
        }

        val email = AppStorage.getCurrentUser(this)
        
        toast("Uploading file (Free Cloud)...")
        FirebaseHistoryManager.uploadFileFree(this, groupId, email, uri, fileName, fileType) { success ->
            runOnUiThread {
                if (success) toast("File Shared with Group!")
                else toast("Upload failed. Try again.")
            }
        }
    }

    private fun sendMessage() {
        val msg = messageInput.text.toString().trim()
        if (msg.isEmpty()) return
        
        val email = AppStorage.getCurrentUser(this)
        
        FirebaseHistoryManager.saveMessage(groupId, email, msg)
        messageInput.setText("")
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
    private fun toast(m: String) = Toast.makeText(this, m, Toast.LENGTH_SHORT).show()

    private fun getGroupTeachersArray(group: org.json.JSONObject): org.json.JSONArray {
        val teachers = group.optJSONArray("teachers") ?: org.json.JSONArray()
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

    inner class SendIconView(context: Context) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            style = Paint.Style.FILL
        }
        override fun onDraw(canvas: Canvas) {
            val w = width.toFloat()
            val h = height.toFloat()
            val path = Path()
            path.moveTo(w * 0.1f, h * 0.1f)
            path.lineTo(w * 0.9f, h * 0.5f)
            path.lineTo(w * 0.1f, h * 0.9f)
            path.lineTo(w * 0.3f, h * 0.5f)
            path.close()
            canvas.drawPath(path, paint)
        }
    }
}