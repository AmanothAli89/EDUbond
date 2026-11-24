package com.example.peermatrix

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialException
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.firebase.auth.EmailAuthProvider
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseAuthUserCollisionException
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : Activity() {

    private lateinit var auth: FirebaseAuth
    private lateinit var db: FirebaseFirestore
    private lateinit var credentialManager: CredentialManager

    private enum class Page { LOGIN, FORGOT_PASSWORD, ADMIN_LOGIN, SET_PASSWORD, APP_PASSWORD, ABOUT_US }
    private var currentPage = Page.LOGIN

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        auth = FirebaseAuth.getInstance()
        db = FirebaseFirestore.getInstance()
        credentialManager = CredentialManager.create(this)

        // Seed default quizzes to cloud if not already there
        FirebaseHistoryManager.seedDefaultQuizzesToCloud()

        val action = intent.getStringExtra("action")
        if (action == "forgot_password") {
            showForgotPasswordPage()
            return
        }

        val currentUser = auth.currentUser
        val localUserEmail = AppStorage.getCurrentUser(this)
        val introDone = intent.getBooleanExtra("introDone", false)
        val fromLogout = intent.getBooleanExtra("fromLogout", false)

        if (currentUser != null && !currentUser.email.isNullOrEmpty() && localUserEmail.isNotEmpty()) {
            goToUserHome()
        } else {
            if (currentUser != null && localUserEmail.isEmpty()) {
                auth.signOut()
                AppStorage.logout(this)
            }
            if (!introDone && !fromLogout) {
                startActivity(Intent(this, AnimatedLoginActivity::class.java))
                finish()
            } else {
                showUserLoginPage()
            }
        }
    }

    override fun onBackPressed() {
        when (currentPage) {
            Page.LOGIN -> super.onBackPressed()
            Page.FORGOT_PASSWORD, Page.ADMIN_LOGIN, Page.ABOUT_US -> showUserLoginPage()
            Page.SET_PASSWORD, Page.APP_PASSWORD -> {
                auth.signOut()
                AppStorage.logout(this)
                showUserLoginPage()
            }
        }
    }

    private fun showUserLoginPage() {
        currentPage = Page.LOGIN
        val layout = loginPageRoot()
        layout.addView(brandHeader())
        layout.addView(sectionLabel("User Login"))

        val emailInput = iconInput(layout, R.drawable.ic_mail, "Enter your Gmail", false)
        val passwordInput = passwordInputWithEye(layout)

        val loginButton = modernButton("Login", "#0057D8")
        val forgotPasswordButton = textButton("Forgot Password?")
        val googleContinueButton = modernButton("Continue with Google", "#006B57")
        val adminLoginButton = modernButton("Login as Admin", "#4B008C")
        val aboutUsButton = textButton("About Us")

        layout.addView(loginButton)
        layout.addView(forgotPasswordButton)
        layout.addView(googleContinueButton)
        layout.addView(adminLoginButton)
        layout.addView(aboutUsButton)

        loginButton.setOnClickListener {
            val email = emailInput.text.toString().trim()
            val password = passwordInput.text.toString().trim()
            if (email.isEmpty() || password.isEmpty()) {
                toast("Please enter your Gmail and password.")
                return@setOnClickListener
            }
            auth.signInWithEmailAndPassword(email, password)
                .addOnSuccessListener { result ->
                    val user = result.user ?: return@addOnSuccessListener
                    val userEmail = user.email ?: email
                    AppStorage.setCurrentUser(this, userEmail)
                    saveLoginInfoAfterPasswordLogin(user)
                    toast("Login successful.")
                    goToUserHome()
                }
                .addOnFailureListener { error -> toast("Login failed: ${error.message}") }
        }

        forgotPasswordButton.setOnClickListener { showForgotPasswordPage() }
        googleContinueButton.setOnClickListener { signInWithGoogle(fromCreateNewAccount = true) }
        adminLoginButton.setOnClickListener { showAdminLoginPage() }
        aboutUsButton.setOnClickListener { showAboutUsPage() }
    }

    private fun showForgotPasswordPage() {
        currentPage = Page.FORGOT_PASSWORD
        val layout = loginPageRoot()
        layout.addView(sectionLabel("Forgot Password"))

        val info = TextView(this)
        info.text = "Enter the Gmail account you used before. A password reset email will be sent to that address."
        info.setTextColor(Color.parseColor("#475569"))
        info.setPadding(0, 0, 0, authDp(20))
        layout.addView(info)

        val emailInput = iconInput(layout, R.drawable.ic_mail, "Enter your Gmail", false)
        val sendResetButton = modernButton("Send Reset Email", "#0061FF")
        val backButton = modernButton("Back to Login", "#F1F5F9")
        backButton.setTextColor(Color.parseColor("#475569"))

        layout.addView(sendResetButton)
        layout.addView(backButton)

        sendResetButton.setOnClickListener {
            val email = emailInput.text.toString().trim()
            if (email.isEmpty() || !email.contains("@")) {
                toast("Please enter a valid Gmail address.")
                return@setOnClickListener
            }
            auth.sendPasswordResetEmail(email)
                .addOnSuccessListener {
                    toast("Password reset email sent. Please check your Gmail inbox or spam folder.")
                    showUserLoginPage()
                }
                .addOnFailureListener { error -> toast("Password reset failed: ${error.message}") }
        }
        backButton.setOnClickListener { showUserLoginPage() }
    }

    private fun showAdminLoginPage() {
        currentPage = Page.ADMIN_LOGIN
        val card = adminLoginPageRoot()
        card.addView(adminTitle("Admin Login"))

        val adminIdInput = adminInputWithIcon(card, "Admin ID", AdminUserIconView(this))
        val passwordInput = adminPasswordInputWithEye(card)

        val adminLoginButton = adminGradientButton("Login as Admin", "#6A1B9A", "#8E24AA")
        val backButton = adminSolidButton("Back", "#9CA3AF")

        card.addView(adminLoginButton)
        card.addView(backButton)

        adminLoginButton.setOnClickListener {
            val adminId = adminIdInput.text.toString().trim()
            val password = passwordInput.text.toString().trim()
            
            if (adminId.isEmpty() || password.isEmpty()) {
                toast("Please enter credentials")
                return@setOnClickListener
            }

            FirebaseHistoryManager.checkAdminLogin(adminId, password) { success ->
                runOnUiThread {
                    if (success) {
                        // অ্যাডমিন লগইন সফল হলে আগের ইউজার সেশন ক্লিয়ার করে দেওয়া হবে
                        auth.signOut()
                        AppStorage.logout(this@MainActivity)

                        toast("Admin login successful.")
                        startActivity(Intent(this@MainActivity, AdminActivity::class.java))
                    } else {
                        toast("Wrong Admin ID or password.")
                    }
                }
            }
        }
        backButton.setOnClickListener { showUserLoginPage() }
    }

    private fun showSetPasswordPage(uid: String, email: String, username: String, photoUrl: String) {
        currentPage = Page.SET_PASSWORD
        val layout = setPasswordPageRoot()
        layout.addView(setPasswordHeader())
        layout.addView(setPasswordInfoCard("Verified Gmail: $email", "You can use this password later to log in with your Gmail and app password."))

        val passwordInput = labeledPasswordInputWithEye(layout, "New App Password", "Enter new app password")
        val confirmPasswordInput = labeledPasswordInputWithEye(layout, "Confirm App Password", "Enter confirm app password")
        val savePasswordButton = setPasswordMainButton("Save Password & Continue", "#238A4B")
        val cancelButton = setPasswordMainButton("Cancel and Logout", "#DC2F3A")

        layout.addView(savePasswordButton)
        layout.addView(cancelButton)

        savePasswordButton.setOnClickListener {
            val password = passwordInput.text.toString().trim()
            val confirmPassword = confirmPasswordInput.text.toString().trim()
            if (password.length < 6) {
                toast("Password must be at least 6 characters.")
                return@setOnClickListener
            }
            if (password != confirmPassword) {
                toast("Passwords do not match.")
                return@setOnClickListener
            }

            val currentUser = auth.currentUser ?: return@setOnClickListener
            val emailCredential = EmailAuthProvider.getCredential(email, password)
            currentUser.linkWithCredential(emailCredential)
                .addOnSuccessListener {
                    saveUserToFirestore(uid, username, email, "google+password", photoUrl, true, true)
                    AppStorage.setCurrentUser(this, email)
                    toast("Password set successfully.")
                    goToUserHome()
                }
                .addOnFailureListener { error ->
                    if (error.message?.contains("already") == true) {
                        goToUserHome()
                    } else {
                        toast("Password setup failed: ${error.message}")
                    }
                }
        }
        cancelButton.setOnClickListener {
            auth.signOut()
            AppStorage.logout(this)
            showUserLoginPage()
        }
    }

    private fun signInWithGoogle(fromCreateNewAccount: Boolean) {
        val googleOption = GetSignInWithGoogleOption.Builder(getString(R.string.default_web_client_id)).build()
        val request = GetCredentialRequest.Builder().addCredentialOption(googleOption).build()

        CoroutineScope(Dispatchers.Main).launch {
            try {
                val result = credentialManager.getCredential(this@MainActivity, request)
                val credential = result.credential
                if (credential is CustomCredential && credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
                    val googleCredential = GoogleIdTokenCredential.createFrom(credential.data)
                    firebaseAuthWithGoogle(googleCredential.idToken, googleCredential.id, fromCreateNewAccount)
                }
            } catch (e: Exception) {
                toast("Google login failed: ${e.message}")
            }
        }
    }

    private fun firebaseAuthWithGoogle(idToken: String, selectedEmail: String, fromCreateNewAccount: Boolean) {
        val credential = GoogleAuthProvider.getCredential(idToken, null)
        auth.signInWithCredential(credential)
            .addOnSuccessListener { result ->
                val user = result.user ?: return@addOnSuccessListener
                checkPasswordStatusAfterGoogleLogin(user.uid, user.email ?: "", user.displayName ?: "", user.photoUrl?.toString() ?: "", fromCreateNewAccount)
            }
            .addOnFailureListener { error ->
                if (fromCreateNewAccount && error is FirebaseAuthUserCollisionException) {
                    showAppPasswordAfterGooglePage(selectedEmail, "", "", "", "Account exists. Enter app password.")
                } else {
                    toast("Authentication failed: ${error.message}")
                }
            }
    }

    private fun checkPasswordStatusAfterGoogleLogin(uid: String, email: String, username: String, photoUrl: String, fromCreateNewAccount: Boolean) {
        val user = auth.currentUser ?: return
        user.reload().addOnSuccessListener {
            db.collection("users").document(uid).get().addOnSuccessListener { doc ->
                if (doc.getBoolean("passwordSet") == true) {
                    showAppPasswordAfterGooglePage(email, username, uid, photoUrl)
                } else {
                    showSetPasswordPage(uid, email, username, photoUrl)
                }
            }.addOnFailureListener { showSetPasswordPage(uid, email, username, photoUrl) }
        }
    }

    private fun showAppPasswordAfterGooglePage(email: String, username: String, uid: String, photoUrl: String, topMsg: String? = null) {
        currentPage = Page.APP_PASSWORD
        val layout = appPasswordPageRoot()
        layout.addView(enterPasswordHeader())
        layout.addView(infoCard("Verified Gmail: $email", topMsg ?: "Enter your app password to continue."))

        val passwordInput = appPasswordInputWithEye(layout)
        val loginButton = modernButtonWithIcon("Login", "#2F80ED", "lock")
        val backButton = modernLightButtonWithIcon("Back", "back")

        layout.addView(loginButton)
        layout.addView(backButton)

        loginButton.setOnClickListener {
            val pass = passwordInput.text.toString().trim()
            auth.signInWithEmailAndPassword(email, pass).addOnSuccessListener {
                AppStorage.setCurrentUser(this, email)
                saveUserToFirestore(uid, username, email, "google+password", photoUrl, true, true)
                goToUserHome()
            }.addOnFailureListener { toast("Wrong password.") }
        }
        backButton.setOnClickListener {
            auth.signOut()
            showUserLoginPage()
        }
    }

    private fun saveLoginInfoAfterPasswordLogin(user: FirebaseUser) {
        saveUserToFirestore(user.uid, user.displayName ?: user.email ?: "", user.email ?: "", "google+password", user.photoUrl?.toString() ?: "", true, true)
    }

    private fun saveUserToFirestore(uid: String, username: String, email: String, provider: String, photoUrl: String, googleVerified: Boolean, passwordSet: Boolean) {
        val data = hashMapOf("uid" to uid, "username" to username, "email" to email, "photoUrl" to photoUrl, "role" to "user", "loginProvider" to provider, "googleVerified" to googleVerified, "passwordSet" to passwordSet, "updatedAt" to FieldValue.serverTimestamp())
        db.collection("users").document(uid).set(data, SetOptions.merge())
    }

    private fun showAboutUsPage() {
        currentPage = Page.ABOUT_US
        val layout = loginPageRoot()
        layout.addView(sectionLabel("Developer Information"))

        val profileContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(0, authDp(10), 0, authDp(20))
        }

        val profileImage = ImageView(this).apply {
            val size = authDp(140)
            layoutParams = LinearLayout.LayoutParams(size, size).apply {
                bottomMargin = authDp(16)
            }
            // If the user adds developer_pic to drawables, it will show up.
            // Otherwise it falls back to a default icon.
            val resId = resources.getIdentifier("developer_pic", "drawable", packageName)
            if (resId != 0) {
                setImageResource(resId)
            } else {
                setImageResource(R.drawable.ic_logo_edu)
            }
            scaleType = ImageView.ScaleType.CENTER_CROP
            
            val shape = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.LTGRAY)
            }
            background = shape
            elevation = authDp(4).toFloat()
            clipToOutline = true
        }
        profileContainer.addView(profileImage)

        val nameText = TextView(this).apply {
            text = "Md. Lemon Islam Bappy"
            textSize = 22f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.parseColor("#1E1B4B"))
            gravity = Gravity.CENTER
        }
        profileContainer.addView(nameText)

        val degreeText = TextView(this).apply {
            text = "B.Sc. in Computer Science and Engineering (CSE)\nBangladesh Army University of Science and Technology (BAUST)"
            textSize = 15f
            setTextColor(Color.parseColor("#475569"))
            gravity = Gravity.CENTER
            setPadding(0, authDp(6), 0, authDp(20))
        }
        profileContainer.addView(degreeText)

        val infoTable = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.START
        }

        fun addInfoRow(icon: String, value: String, url: String? = null, isEmail: Boolean = false) {
            val row = LinearLayout(this)
            row.orientation = LinearLayout.HORIZONTAL
            row.setPadding(0, authDp(12), 0, authDp(12))
            row.gravity = Gravity.CENTER_VERTICAL
            
            if (url != null) {
                row.setOnClickListener {
                    val intent = if (isEmail) {
                        Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:$url"))
                    } else {
                        Intent(Intent.ACTION_VIEW, Uri.parse(url))
                    }
                    try {
                        startActivity(intent)
                    } catch (e: Exception) {
                        toast("Could not open link")
                    }
                }
            }
            
            val iconView = TextView(this)
            iconView.text = icon
            iconView.textSize = 24f
            iconView.setPadding(0, 0, authDp(16), 0)
            
            val valueView = TextView(this)
            valueView.text = value
            valueView.textSize = 17f
            if (url != null) {
                valueView.setTextColor(Color.parseColor("#0057D8"))
                valueView.paintFlags = valueView.paintFlags or android.graphics.Paint.UNDERLINE_TEXT_FLAG
            } else {
                valueView.setTextColor(Color.parseColor("#334155"))
            }

            row.addView(iconView)
            row.addView(valueView)
            infoTable.addView(row)
        }

        addInfoRow("📩", "Email: mdlemonislambappy@gmail.com", "mdlemonislambappy@gmail.com", true)
        addInfoRow("💼", "LinkedIn: md-lemon-islam-bappy", "https://www.linkedin.com/in/md-lemon-islam-bappy-4116a61b8/")
        addInfoRow("💻", "GitHub: bappy-81", "https://github.com/bappy-81")

        profileContainer.addView(infoTable)
        layout.addView(profileContainer)

        val backButton = modernButton("Back to Login", "#4B008C")
        layout.addView(backButton)
        backButton.setOnClickListener { showUserLoginPage() }
    }

    private fun goToUserHome() {
        startActivity(Intent(this, UserHomeActivity::class.java).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK })
        finish()
    }

    private fun toast(text: String) = Toast.makeText(this, text, Toast.LENGTH_SHORT).show()
}
