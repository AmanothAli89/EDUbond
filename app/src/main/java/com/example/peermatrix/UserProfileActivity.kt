package com.example.peermatrix

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.text.InputType
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.*
import com.google.firebase.auth.EmailAuthProvider
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions

class UserProfileActivity : Activity() {

    private lateinit var auth: FirebaseAuth
    private lateinit var db: FirebaseFirestore

    private lateinit var contentArea: LinearLayout
    private var currentUserName = ""
    private var currentUserBio = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        auth = FirebaseAuth.getInstance()
        db = FirebaseFirestore.getInstance()

        val user = auth.currentUser
        if (user == null) {
            finish()
            return
        }

        setupBaseUI()
        loadProfileData()
    }

    private fun setupBaseUI() {
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
        backBtn.setOnClickListener { 
            // If in a sub-view, go back to main profile view, otherwise finish
            if (contentArea.tag == "view") finish() else showProfileView()
        }

        val title = TextView(this)
        title.text = "My Profile"
        title.textSize = 24f
        title.typeface = Typeface.DEFAULT_BOLD
        title.setTextColor(Color.parseColor("#1E1B4B"))

        header.addView(backBtn)
        header.addView(title)
        root.addView(header)

        contentArea = LinearLayout(this)
        contentArea.orientation = LinearLayout.VERTICAL
        root.addView(contentArea)

        scrollView.addView(root)
        setContentView(scrollView)
    }

    private fun loadProfileData() {
        val user = auth.currentUser ?: return
        db.collection("users").document(user.uid).get()
            .addOnSuccessListener { doc ->
                currentUserName = doc.getString("username") ?: "User"
                currentUserBio = doc.getString("biodata") ?: "No bio added yet."
                showProfileView()
            }
    }

    private fun showProfileView() {
        contentArea.removeAllViews()
        contentArea.tag = "view"

        val card = createCard()
        
        // Name Display
        val nameLabel = label("Display Name")
        val nameValue = TextView(this)
        nameValue.text = currentUserName
        nameValue.textSize = 18f
        nameValue.setTextColor(Color.parseColor("#1E1B4B"))
        nameValue.setPadding(0, 0, 0, dp(20))
        
        // Bio Display
        val bioLabel = label("Biodata")
        val bioValue = TextView(this)
        bioValue.text = currentUserBio
        bioValue.textSize = 15f
        bioValue.setTextColor(Color.parseColor("#475569"))
        bioValue.setPadding(0, 0, 0, dp(32))

        val editBtn = actionButton("Edit Profile", "#2563EB")
        editBtn.setOnClickListener { showEditProfileView() }

        val changePassBtn = actionButton("Change App Password", "#7C3AED")
        changePassBtn.setOnClickListener { showChangePasswordView() }

        card.addView(nameLabel)
        card.addView(nameValue)
        card.addView(bioLabel)
        card.addView(bioValue)
        card.addView(editBtn)
        card.addView(changePassBtn)

        contentArea.addView(card)
    }

    private fun showEditProfileView() {
        contentArea.removeAllViews()
        contentArea.tag = "edit"

        val card = createCard()
        
        val editTitle = titleLabel("Edit Profile Information")
        editTitle.setTextColor(Color.parseColor("#1E1B4B"))
        card.addView(editTitle)

        card.addView(label("New Display Name"))
        val nameInput = input(currentUserName)
        nameInput.setText(currentUserName)
        card.addView(nameInput)

        card.addView(label("Biodata / About Me"))
        val bioInput = multiLineInput("Tell others about yourself...")
        bioInput.setText(currentUserBio)
        card.addView(bioInput)

        val updateBtn = actionButton("Update Name & Bio", "#0D9466")
        updateBtn.setOnClickListener {
            val newName = nameInput.text.toString().trim()
            val newBio = bioInput.text.toString().trim()
            if (newName.isEmpty()) {
                toast("Name cannot be empty")
                return@setOnClickListener
            }
            updateProfile(newName, newBio)
        }

        val cancelBtn = textButton("Cancel")
        cancelBtn.setTextColor(Color.parseColor("#1D4ED8"))
        cancelBtn.setOnClickListener { showProfileView() }

        card.addView(updateBtn)
        card.addView(cancelBtn)
        contentArea.addView(card)
    }

    private fun showChangePasswordView() {
        contentArea.removeAllViews()
        contentArea.tag = "password"

        val card = createCard()
        card.addView(titleLabel("Update App Password"))

        card.addView(label("Current App Password"))
        val oldPassInput = passwordInput("Enter current password")
        card.addView(oldPassInput)

        card.addView(label("New App Password"))
        val newPassInput = passwordInput("Enter new password")
        card.addView(newPassInput)

        val updatePassBtn = actionButton("Update Password", "#7C3AED")
        updatePassBtn.setOnClickListener {
            val oldPass = oldPassInput.text.toString().trim()
            val newPass = newPassInput.text.toString().trim()
            
            if (oldPass.isEmpty() || newPass.isEmpty()) {
                toast("Please fill both fields")
                return@setOnClickListener
            }
            if (newPass.length < 6) {
                toast("New password must be at least 6 characters")
                return@setOnClickListener
            }
            performPasswordUpdate(oldPass, newPass)
        }

        val forgotPassBtn = textButton("Forgot Password?")
        forgotPassBtn.setOnClickListener {
            // Navigate to Forgot Password Flow in MainActivity
            val intent = Intent(this, MainActivity::class.java)
            intent.putExtra("action", "forgot_password")
            startActivity(intent)
        }

        val cancelBtn = textButton("Cancel")
        cancelBtn.setOnClickListener { showProfileView() }

        card.addView(updatePassBtn)
        card.addView(forgotPassBtn)
        card.addView(cancelBtn)
        contentArea.addView(card)
    }

    private fun updateProfile(newName: String, newBio: String) {
        val user = auth.currentUser ?: return
        val data = hashMapOf("username" to newName, "biodata" to newBio)

        db.collection("users").document(user.uid)
            .set(data, SetOptions.merge())
            .addOnSuccessListener {
                currentUserName = newName
                currentUserBio = newBio
                toast("Updated Successfully")
                showProfileView()
            }
            .addOnFailureListener { e -> toast("Update failed: ${e.message}") }
    }

    private fun performPasswordUpdate(oldPass: String, newPass: String) {
        val user = auth.currentUser ?: return
        val email = user.email ?: return

        val credential = EmailAuthProvider.getCredential(email, oldPass)
        user.reauthenticate(credential)
            .addOnSuccessListener {
                user.updatePassword(newPass)
                    .addOnSuccessListener {
                        toast("Password updated successfully!")
                        showProfileView()
                    }
                    .addOnFailureListener { e -> toast("Error: ${e.message}") }
            }
            .addOnFailureListener {
                toast("Current password does not match.")
            }
    }

    // UI Helpers
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
        card.layoutParams = params
        return card
    }

    private fun label(text: String): TextView {
        val tv = TextView(this)
        tv.text = text
        tv.textSize = 13f
        tv.typeface = Typeface.DEFAULT_BOLD
        tv.setTextColor(Color.parseColor("#64748B"))
        tv.setPadding(0, 0, 0, dp(6))
        return tv
    }

    private fun titleLabel(text: String): TextView {
        val tv = TextView(this)
        tv.text = text
        tv.textSize = 18f
        tv.typeface = Typeface.DEFAULT_BOLD
        tv.setTextColor(Color.parseColor("#1E1B4B"))
        tv.setPadding(0, 0, 0, dp(18))
        return tv
    }

    private fun input(hint: String): EditText {
        val et = EditText(this)
        et.hint = hint
        et.setPadding(dp(16), dp(12), dp(16), dp(12))
        val bg = GradientDrawable()
        bg.setColor(Color.parseColor("#F1F5F9"))
        bg.cornerRadius = dp(12).toFloat()
        et.background = bg
        val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        params.setMargins(0, 0, 0, dp(18))
        et.layoutParams = params
        return et
    }

    private fun multiLineInput(hint: String): EditText {
        val et = input(hint)
        et.gravity = Gravity.TOP
        et.inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE
        et.setLines(4)
        return et
    }

    private fun passwordInput(hint: String): EditText {
        val et = input(hint)
        et.inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
        return et
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
    private fun toast(m: String) = Toast.makeText(this, m, Toast.LENGTH_SHORT).show()
}