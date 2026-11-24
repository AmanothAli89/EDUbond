package com.example.peermatrix

import android.app.Activity
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.text.InputType
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.*

fun Activity.authDp(value: Int): Int {
    return (value * resources.displayMetrics.density).toInt()
}

fun Activity.authToast(text: String) {
    Toast.makeText(this, text, Toast.LENGTH_SHORT).show()
}

fun Activity.topBackButton(onClick: () -> Unit): View {
    val container = LinearLayout(this)
    container.orientation = LinearLayout.HORIZONTAL
    container.gravity = Gravity.START
    val back = TextView(this)
    back.text = "‹"
    back.textSize = 34f
    back.gravity = Gravity.CENTER
    back.typeface = Typeface.DEFAULT_BOLD
    back.setTextColor(Color.parseColor("#334155"))
    val bg = GradientDrawable()
    bg.setColor(Color.parseColor("#FFFFFF"))
    bg.cornerRadius = authDp(28).toFloat()
    back.background = bg
    back.elevation = authDp(4).toFloat()
    val params = LinearLayout.LayoutParams(authDp(56), authDp(56))
    params.setMargins(0, 0, 0, authDp(28))
    back.layoutParams = params
    back.setOnClickListener { onClick() }
    container.addView(back)
    return container
}

fun Activity.setPasswordBackButton(onClick: () -> Unit): View {
    val container = LinearLayout(this)
    container.orientation = LinearLayout.HORIZONTAL
    container.gravity = Gravity.START
    val back = TextView(this)
    back.text = "‹"
    back.textSize = 34f
    back.gravity = Gravity.CENTER
    back.typeface = Typeface.DEFAULT_BOLD
    back.setTextColor(Color.parseColor("#334155"))
    val bg = GradientDrawable()
    bg.setColor(Color.WHITE)
    bg.cornerRadius = authDp(28).toFloat()
    back.background = bg
    back.elevation = authDp(5).toFloat()
    val params = LinearLayout.LayoutParams(authDp(56), authDp(56))
    params.setMargins(0, 0, 0, authDp(36))
    back.layoutParams = params
    back.setOnClickListener { onClick() }
    container.addView(back)
    return container
}

fun Activity.loginPageRoot(): LinearLayout {
    val scrollView = ScrollView(this)
    scrollView.isFillViewport = true
    val scrollBackground = GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM, intArrayOf(Color.parseColor("#CFE8FF"), Color.parseColor("#EDE7FF"), Color.parseColor("#F8FBFF")))
    scrollView.background = scrollBackground
    window.statusBarColor = Color.parseColor("#CFE8FF")
    window.navigationBarColor = Color.parseColor("#F8FBFF")
    val outerRoot = LinearLayout(this)
    outerRoot.orientation = LinearLayout.VERTICAL
    outerRoot.gravity = Gravity.CENTER
    outerRoot.setPadding(authDp(18), authDp(36), authDp(18), authDp(36))
    val outerBackground = GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM, intArrayOf(Color.parseColor("#CFE8FF"), Color.parseColor("#EDE7FF"), Color.parseColor("#F8FBFF")))
    outerRoot.background = outerBackground
    val card = LinearLayout(this)
    card.orientation = LinearLayout.VERTICAL
    card.gravity = Gravity.CENTER_HORIZONTAL
    card.setPadding(authDp(22), authDp(30), authDp(22), authDp(30))
    card.elevation = authDp(10).toFloat()
    val cardBackground = GradientDrawable()
    cardBackground.setColor(Color.parseColor("#F2FFFFFF"))
    cardBackground.cornerRadius = authDp(28).toFloat()
    cardBackground.setStroke(authDp(1), Color.parseColor("#AAB7C8"))
    card.background = cardBackground
    val cardParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    cardParams.setMargins(0, authDp(8), 0, authDp(8))
    card.layoutParams = cardParams
    outerRoot.addView(card)
    scrollView.addView(outerRoot, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
    setContentView(scrollView)
    return card
}

fun Activity.adminLoginPageRoot(): LinearLayout {
    val scrollView = ScrollView(this)
    scrollView.isFillViewport = true
    val background = GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM, intArrayOf(Color.parseColor("#F8FBFF"), Color.parseColor("#EEF6FF"), Color.parseColor("#F8F7FF")))
    scrollView.background = background
    window.statusBarColor = Color.parseColor("#F8FBFF")
    window.navigationBarColor = Color.parseColor("#F8F7FF")
    val root = LinearLayout(this)
    root.orientation = LinearLayout.VERTICAL
    root.gravity = Gravity.CENTER_HORIZONTAL
    root.setPadding(authDp(24), authDp(55), authDp(24), authDp(40))
    root.background = background
    root.addView(adminBrandHeader())
    val card = LinearLayout(this)
    card.orientation = LinearLayout.VERTICAL
    card.setPadding(authDp(28), authDp(36), authDp(28), authDp(34))
    card.elevation = authDp(8).toFloat()
    val cardBackground = GradientDrawable()
    cardBackground.setColor(Color.parseColor("#F5FFFFFF"))
    cardBackground.cornerRadius = authDp(32).toFloat()
    cardBackground.setStroke(authDp(1), Color.parseColor("#EEF2F7"))
    card.background = cardBackground
    val cardParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    cardParams.setMargins(0, authDp(46), 0, 0)
    card.layoutParams = cardParams
    root.addView(card)
    scrollView.addView(root, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
    setContentView(scrollView)
    return card
}

fun Activity.appPasswordPageRoot(): LinearLayout {
    val scrollView = ScrollView(this)
    scrollView.isFillViewport = true
    val background = GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM, intArrayOf(Color.parseColor("#F8FBFF"), Color.parseColor("#EEF6FF"), Color.parseColor("#F8F7FF")))
    scrollView.background = background
    window.statusBarColor = Color.parseColor("#F8FBFF")
    window.navigationBarColor = Color.parseColor("#F8F7FF")
    val root = LinearLayout(this)
    root.orientation = LinearLayout.VERTICAL
    root.setPadding(authDp(24), authDp(30), authDp(24), authDp(36))
    root.background = background
    scrollView.addView(root, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
    setContentView(scrollView)
    return root
}

fun Activity.setPasswordPageRoot(): LinearLayout {
    val scrollView = ScrollView(this)
    scrollView.isFillViewport = true
    val background = GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM, intArrayOf(Color.parseColor("#F8FBFF"), Color.parseColor("#F1F8FF"), Color.parseColor("#F9F7FF")))
    scrollView.background = background
    window.statusBarColor = Color.parseColor("#F8FBFF")
    window.navigationBarColor = Color.parseColor("#F9F7FF")
    val root = LinearLayout(this)
    root.orientation = LinearLayout.VERTICAL
    root.setPadding(authDp(24), authDp(30), authDp(24), authDp(36))
    root.background = background
    scrollView.addView(root, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
    setContentView(scrollView)
    return root
}

fun Activity.brandHeader(): LinearLayout {
    val header = LinearLayout(this)
    header.orientation = LinearLayout.VERTICAL
    header.gravity = Gravity.CENTER_HORIZONTAL
    val logoRow = LinearLayout(this)
    logoRow.orientation = LinearLayout.HORIZONTAL
    logoRow.gravity = Gravity.CENTER
    val logoIcon = TextView(this)
    logoIcon.text = "📖"
    logoIcon.textSize = 42f
    logoIcon.gravity = Gravity.CENTER
    val title = TextView(this)
    title.text = "EduBond"
    title.textSize = 36f
    title.typeface = Typeface.DEFAULT_BOLD
    title.setTextColor(Color.parseColor("#1E1B4B"))
    title.setPadding(authDp(8), 0, 0, 0)
    logoRow.addView(logoIcon)
    logoRow.addView(title)
    val subtitle = TextView(this)
    subtitle.text = "Digital Platform for Academic Peers"
    subtitle.textSize = 16f
    subtitle.setTextColor(Color.parseColor("#111827"))
    subtitle.gravity = Gravity.CENTER
    subtitle.setPadding(0, authDp(6), 0, authDp(34))
    header.addView(logoRow)
    header.addView(subtitle)
    return header
}

fun Activity.sectionLabel(text: String): TextView {
    val tv = TextView(this)
    tv.text = text
    tv.textSize = 22f
    tv.typeface = Typeface.DEFAULT_BOLD
    tv.setTextColor(Color.parseColor("#111827"))
    tv.gravity = Gravity.START
    val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    params.setMargins(0, 0, 0, authDp(18))
    tv.layoutParams = params
    return tv
}

fun Activity.adminBrandHeader(): View {
    val header = LinearLayout(this)
    header.orientation = LinearLayout.HORIZONTAL
    header.gravity = Gravity.CENTER_VERTICAL
    val logo = AdminShieldLogoView(this)
    val logoParams = LinearLayout.LayoutParams(authDp(92), authDp(92))
    logoParams.setMargins(0, 0, authDp(22), 0)
    logo.layoutParams = logoParams
    val textBox = LinearLayout(this)
    textBox.orientation = LinearLayout.VERTICAL
    val title = TextView(this)
    title.text = "EduBond"
    title.textSize = 34f
    title.typeface = Typeface.DEFAULT_BOLD
    title.setTextColor(Color.parseColor("#6A1B9A"))
    val subtitle = TextView(this)
    subtitle.text = "Digital Platform for Academic Peers"
    subtitle.textSize = 16f
    subtitle.setTextColor(Color.parseColor("#334155"))
    subtitle.setPadding(0, authDp(6), 0, 0)
    textBox.addView(title)
    textBox.addView(subtitle)
    header.addView(logo)
    header.addView(textBox)
    return header
}

fun Activity.adminTitle(text: String): TextView {
    val tv = TextView(this)
    tv.text = text
    tv.textSize = 29f
    tv.typeface = Typeface.DEFAULT_BOLD
    tv.setTextColor(Color.parseColor("#0F172A"))
    val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    params.setMargins(0, 0, 0, authDp(36))
    tv.layoutParams = params
    return tv
}

fun Activity.iconInput(parent: LinearLayout, iconResId: Int, hintText: String, isPassword: Boolean): EditText {
    val box = LinearLayout(this)
    box.orientation = LinearLayout.HORIZONTAL
    box.gravity = Gravity.CENTER_VERTICAL
    box.setPadding(authDp(16), 0, authDp(16), 0)
    val bg = GradientDrawable()
    bg.setColor(Color.parseColor("#EEF3FA"))
    bg.cornerRadius = authDp(18).toFloat()
    bg.setStroke(authDp(1), Color.parseColor("#CBD5E1"))
    box.background = bg
    box.elevation = authDp(3).toFloat()
    val boxParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, authDp(64))
    boxParams.setMargins(0, 0, 0, authDp(16))
    box.layoutParams = boxParams
    val icon = ImageView(this)
    icon.setImageResource(iconResId)
    icon.setColorFilter(Color.parseColor("#6B7280"))
    val iconParams = LinearLayout.LayoutParams(authDp(28), authDp(28))
    iconParams.setMargins(0, 0, authDp(10), 0)
    icon.layoutParams = iconParams
    val input = EditText(this)
    input.hint = hintText
    input.textSize = 18f
    input.setSingleLine(true)
    input.setTextColor(Color.parseColor("#111827"))
    input.setHintTextColor(Color.parseColor("#7A7F87"))
    input.setPadding(authDp(8), 0, authDp(8), 0)
    input.background = null
    input.inputType = if (isPassword) InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD else InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS
    val inputParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f)
    input.layoutParams = inputParams
    box.addView(icon)
    box.addView(input)
    parent.addView(box)
    return input
}

fun Activity.passwordInputWithEye(parent: LinearLayout): EditText {
    val box = LinearLayout(this)
    box.orientation = LinearLayout.HORIZONTAL
    box.gravity = Gravity.CENTER_VERTICAL
    box.setPadding(authDp(16), 0, authDp(16), 0)
    val bg = GradientDrawable()
    bg.setColor(Color.parseColor("#EEF3FA"))
    bg.cornerRadius = authDp(18).toFloat()
    bg.setStroke(authDp(1), Color.parseColor("#CBD5E1"))
    box.background = bg
    box.elevation = authDp(3).toFloat()
    val boxParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, authDp(64))
    boxParams.setMargins(0, 0, 0, authDp(34))
    box.layoutParams = boxParams
    val lockIcon = TextView(this)
    lockIcon.text = "●"
    lockIcon.textSize = 20f
    lockIcon.gravity = Gravity.CENTER
    lockIcon.setTextColor(Color.parseColor("#6B7280"))
    val iconParams = LinearLayout.LayoutParams(authDp(38), ViewGroup.LayoutParams.MATCH_PARENT)
    lockIcon.layoutParams = iconParams
    val input = EditText(this)
    input.hint = "App Password"
    input.textSize = 18f
    input.setSingleLine(true)
    input.setTextColor(Color.parseColor("#111827"))
    input.setHintTextColor(Color.parseColor("#7A7F87"))
    input.setPadding(authDp(8), 0, authDp(8), 0)
    input.background = null
    input.inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
    val inputParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f)
    input.layoutParams = inputParams
    val eyeButton = EyeToggleView(this)
    eyeButton.isClosed = true
    val eyeParams = LinearLayout.LayoutParams(authDp(46), ViewGroup.LayoutParams.MATCH_PARENT)
    eyeButton.layoutParams = eyeParams
    var visible = false
    eyeButton.setOnClickListener {
        visible = !visible
        input.inputType = if (visible) InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD else InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
        eyeButton.isClosed = !visible
        eyeButton.invalidate()
        input.setSelection(input.text.length)
    }
    box.addView(lockIcon)
    box.addView(input)
    box.addView(eyeButton)
    parent.addView(box)
    return input
}

fun Activity.adminInputWithIcon(parent: LinearLayout, hintText: String, iconView: View): EditText {
    val box = LinearLayout(this)
    box.orientation = LinearLayout.HORIZONTAL
    box.gravity = Gravity.CENTER_VERTICAL
    box.setPadding(authDp(18), 0, authDp(18), 0)
    val bg = GradientDrawable()
    bg.setColor(Color.WHITE)
    bg.cornerRadius = authDp(18).toFloat()
    bg.setStroke(authDp(1), Color.parseColor("#D8DEE8"))
    box.background = bg
    box.elevation = authDp(2).toFloat()
    val boxParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, authDp(68))
    boxParams.setMargins(0, 0, 0, authDp(22))
    box.layoutParams = boxParams
    val iconParams = LinearLayout.LayoutParams(authDp(42), ViewGroup.LayoutParams.MATCH_PARENT)
    iconParams.setMargins(0, 0, authDp(12), 0)
    iconView.layoutParams = iconParams
    val input = EditText(this)
    input.hint = hintText
    input.textSize = 18f
    input.setSingleLine(true)
    input.setTextColor(Color.parseColor("#111827"))
    input.setHintTextColor(Color.parseColor("#7A7F87"))
    input.background = null
    input.setPadding(0, 0, 0, 0)
    input.inputType = InputType.TYPE_CLASS_TEXT
    val inputParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f)
    input.layoutParams = inputParams
    box.addView(iconView)
    box.addView(input)
    parent.addView(box)
    return input
}

fun Activity.adminPasswordInputWithEye(parent: LinearLayout): EditText {
    val box = LinearLayout(this)
    box.orientation = LinearLayout.HORIZONTAL
    box.gravity = Gravity.CENTER_VERTICAL
    box.setPadding(authDp(18), 0, authDp(18), 0)
    val bg = GradientDrawable()
    bg.setColor(Color.WHITE)
    bg.cornerRadius = authDp(18).toFloat()
    bg.setStroke(authDp(1), Color.parseColor("#D8DEE8"))
    box.background = bg
    box.elevation = authDp(2).toFloat()
    val boxParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, authDp(68))
    boxParams.setMargins(0, 0, 0, authDp(96))
    box.layoutParams = boxParams
    val lockIcon = AdminLockIconView(this)
    val iconParams = LinearLayout.LayoutParams(authDp(42), ViewGroup.LayoutParams.MATCH_PARENT)
    iconParams.setMargins(0, 0, authDp(12), 0)
    lockIcon.layoutParams = iconParams
    val input = EditText(this)
    input.hint = "Admin Password"
    input.textSize = 18f
    input.setSingleLine(true)
    input.setTextColor(Color.parseColor("#111827"))
    input.setHintTextColor(Color.parseColor("#7A7F87"))
    input.background = null
    input.setPadding(0, 0, authDp(8), 0)
    input.inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
    val inputParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f)
    input.layoutParams = inputParams
    val eyeButton = EyeToggleView(this)
    eyeButton.isClosed = false
    val eyeParams = LinearLayout.LayoutParams(authDp(46), ViewGroup.LayoutParams.MATCH_PARENT)
    eyeButton.layoutParams = eyeParams
    var visible = false
    eyeButton.setOnClickListener {
        visible = !visible
        input.inputType = if (visible) InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD else InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
        eyeButton.isClosed = false
        eyeButton.invalidate()
        input.setSelection(input.text.length)
    }
    box.addView(lockIcon)
    box.addView(input)
    box.addView(eyeButton)
    parent.addView(box)
    return input
}

fun Activity.modernButton(text: String, colorCode: String): Button {
    val button = Button(this)
    button.text = text
    button.textSize = 18f
    button.typeface = Typeface.DEFAULT_BOLD
    button.setTextColor(Color.WHITE)
    button.isAllCaps = false
    button.elevation = authDp(6).toFloat()
    val bg = GradientDrawable()
    bg.setColor(Color.parseColor(colorCode))
    bg.cornerRadius = authDp(18).toFloat()
    button.background = bg
    val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, authDp(64))
    params.setMargins(0, authDp(8), 0, authDp(10))
    button.layoutParams = params
    return button
}

fun Activity.adminGradientButton(text: String, startColor: String, endColor: String): Button {
    val button = Button(this)
    button.text = text
    button.textSize = 18f
    button.typeface = Typeface.DEFAULT_BOLD
    button.setTextColor(Color.WHITE)
    button.isAllCaps = false
    button.elevation = authDp(6).toFloat()
    val bg = GradientDrawable(GradientDrawable.Orientation.LEFT_RIGHT, intArrayOf(Color.parseColor(startColor), Color.parseColor(endColor)))
    bg.cornerRadius = authDp(18).toFloat()
    button.background = bg
    val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, authDp(66))
    params.setMargins(0, 0, 0, authDp(20))
    button.layoutParams = params
    return button
}

fun Activity.adminSolidButton(text: String, colorCode: String): Button {
    val button = Button(this)
    button.text = text
    button.textSize = 18f
    button.typeface = Typeface.DEFAULT_BOLD
    button.setTextColor(Color.WHITE)
    button.isAllCaps = false
    button.elevation = authDp(5).toFloat()
    val bg = GradientDrawable()
    bg.setColor(Color.parseColor(colorCode))
    bg.cornerRadius = authDp(18).toFloat()
    button.background = bg
    val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, authDp(66))
    params.setMargins(0, authDp(4), 0, 0)
    button.layoutParams = params
    return button
}

fun Activity.textButton(text: String): Button {
    val button = Button(this)
    button.text = text
    button.textSize = 16f
    button.setTextColor(Color.parseColor("#1E3A8A"))
    button.setBackgroundColor(Color.TRANSPARENT)
    button.isAllCaps = false
    val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, authDp(50))
    params.setMargins(0, 0, 0, authDp(12))
    button.layoutParams = params
    return button
}

fun Activity.enterPasswordHeader(): View {
    val root = LinearLayout(this)
    root.orientation = LinearLayout.HORIZONTAL
    root.gravity = Gravity.CENTER_VERTICAL
    val iconBox = LockBadgeView(this)
    val iconParams = LinearLayout.LayoutParams(authDp(72), authDp(72))
    iconParams.setMargins(0, 0, authDp(18), 0)
    iconBox.layoutParams = iconParams
    val title = TextView(this)
    title.text = "Enter App Password"
    title.textSize = 27f
    title.typeface = Typeface.DEFAULT_BOLD
    title.setTextColor(Color.parseColor("#0F172A"))
    root.addView(iconBox)
    root.addView(title)
    val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    params.setMargins(0, 0, 0, authDp(28))
    root.layoutParams = params
    return root
}

fun Activity.infoCard(title: String, message: String): View {
    val card = LinearLayout(this)
    card.orientation = LinearLayout.HORIZONTAL
    card.setPadding(authDp(18), authDp(18), authDp(18), authDp(18))
    card.gravity = Gravity.TOP
    val bg = GradientDrawable()
    bg.setColor(Color.parseColor("#ECFDF5"))
    bg.cornerRadius = authDp(18).toFloat()
    card.background = bg
    card.elevation = authDp(3).toFloat()
    val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    params.setMargins(0, 0, 0, authDp(28))
    card.layoutParams = params
    val icon = TextView(this)
    icon.text = "✓"
    icon.textSize = 20f
    icon.gravity = Gravity.CENTER
    icon.typeface = Typeface.DEFAULT_BOLD
    icon.setTextColor(Color.WHITE)
    val iconBg = GradientDrawable()
    iconBg.setColor(Color.parseColor("#34D399"))
    iconBg.shape = GradientDrawable.OVAL
    icon.background = iconBg
    val iconParams = LinearLayout.LayoutParams(authDp(32), authDp(32))
    iconParams.setMargins(0, authDp(3), authDp(14), 0)
    icon.layoutParams = iconParams
    val textBox = LinearLayout(this)
    textBox.orientation = LinearLayout.VERTICAL
    textBox.layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
    val titleView = TextView(this)
    titleView.text = title
    titleView.textSize = 16f
    titleView.typeface = Typeface.DEFAULT_BOLD
    titleView.setTextColor(Color.parseColor("#0F172A"))
    val messageView = TextView(this)
    messageView.text = message
    messageView.textSize = 15.5f
    messageView.setTextColor(Color.parseColor("#334155"))
    messageView.setPadding(0, authDp(8), 0, 0)
    textBox.addView(titleView)
    textBox.addView(messageView)
    card.addView(icon)
    card.addView(textBox)
    return card
}

fun Activity.appPasswordInputWithEye(parent: LinearLayout): EditText {
    val box = LinearLayout(this)
    box.orientation = LinearLayout.HORIZONTAL
    box.gravity = Gravity.CENTER_VERTICAL
    box.setPadding(authDp(18), 0, authDp(18), 0)
    val bg = GradientDrawable()
    bg.setColor(Color.parseColor("#FFFFFF"))
    bg.cornerRadius = authDp(16).toFloat()
    bg.setStroke(authDp(1), Color.parseColor("#CBD5E1"))
    box.background = bg
    val boxParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, authDp(66))
    boxParams.setMargins(0, 0, 0, authDp(14))
    box.layoutParams = boxParams
    val input = EditText(this)
    input.hint = "App Password"
    input.textSize = 18f
    input.setSingleLine(true)
    input.setTextColor(Color.parseColor("#111827"))
    input.setHintTextColor(Color.parseColor("#9CA3AF"))
    input.setPadding(authDp(8), 0, authDp(8), 0)
    input.background = null
    input.inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
    val inputParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f)
    input.layoutParams = inputParams
    val eyeButton = EyeToggleView(this)
    eyeButton.isClosed = true
    val eyeParams = LinearLayout.LayoutParams(authDp(46), ViewGroup.LayoutParams.MATCH_PARENT)
    eyeButton.layoutParams = eyeParams
    var visible = false
    eyeButton.setOnClickListener {
        visible = !visible
        input.inputType = if (visible) InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD else InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
        eyeButton.isClosed = !visible
        eyeButton.invalidate()
        input.setSelection(input.text.length)
    }
    box.addView(input)
    box.addView(eyeButton)
    parent.addView(box)
    return input
}

fun Activity.modernButtonWithIcon(text: String, colorCode: String, iconType: String): Button {
    val button = Button(this)
    button.text = text
    button.textSize = 18f
    button.typeface = Typeface.DEFAULT_BOLD
    button.setTextColor(Color.WHITE)
    button.isAllCaps = false
    button.elevation = authDp(4).toFloat()
    val bg = GradientDrawable()
    bg.setColor(Color.parseColor(colorCode))
    bg.cornerRadius = authDp(16).toFloat()
    button.background = bg
    val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, authDp(62))
    params.setMargins(0, authDp(12), 0, authDp(12))
    button.layoutParams = params
    return button
}

fun Activity.modernLightButtonWithIcon(text: String, iconType: String): Button {
    val button = Button(this)
    button.text = text
    button.textSize = 18f
    button.typeface = Typeface.DEFAULT_BOLD
    button.setTextColor(Color.parseColor("#1F2937"))
    button.isAllCaps = false
    button.elevation = authDp(2).toFloat()
    val bg = GradientDrawable()
    bg.setColor(Color.parseColor("#F1F5F9"))
    bg.cornerRadius = authDp(16).toFloat()
    button.background = bg
    val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, authDp(62))
    params.setMargins(0, authDp(4), 0, authDp(12))
    button.layoutParams = params
    return button
}

fun Activity.setPasswordHeader(): View {
    val root = LinearLayout(this)
    root.orientation = LinearLayout.HORIZONTAL
    root.gravity = Gravity.CENTER_VERTICAL
    val iconBox = GreenLockBadgeView(this)
    val iconParams = LinearLayout.LayoutParams(authDp(82), authDp(82))
    iconParams.setMargins(0, 0, authDp(22), 0)
    iconBox.layoutParams = iconParams
    val title = TextView(this)
    title.text = "Set App Password"
    title.textSize = 29f
    title.typeface = Typeface.DEFAULT_BOLD
    title.setTextColor(Color.parseColor("#0F172A"))
    root.addView(iconBox)
    root.addView(title)
    val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    params.setMargins(0, 0, 0, authDp(28))
    root.layoutParams = params
    return root
}

fun Activity.setPasswordInfoCard(title: String, message: String): View {
    val card = LinearLayout(this)
    card.orientation = LinearLayout.HORIZONTAL
    card.setPadding(authDp(18), authDp(18), authDp(18), authDp(18))
    card.gravity = Gravity.TOP
    val bg = GradientDrawable()
    bg.setColor(Color.parseColor("#F0FFF7"))
    bg.cornerRadius = authDp(18).toFloat()
    bg.setStroke(authDp(1), Color.parseColor("#BDEBD0"))
    card.background = bg
    card.elevation = authDp(3).toFloat()
    val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    params.setMargins(0, 0, 0, authDp(28))
    card.layoutParams = params
    val checkIcon = TextView(this)
    checkIcon.text = "✓"
    checkIcon.textSize = 20f
    checkIcon.gravity = Gravity.CENTER
    checkIcon.typeface = Typeface.DEFAULT_BOLD
    checkIcon.setTextColor(Color.WHITE)
    val iconBg = GradientDrawable()
    iconBg.setColor(Color.parseColor("#2FAE68"))
    iconBg.shape = GradientDrawable.OVAL
    checkIcon.background = iconBg
    val iconParams = LinearLayout.LayoutParams(authDp(34), authDp(34))
    iconParams.setMargins(0, authDp(3), authDp(14), 0)
    checkIcon.layoutParams = iconParams
    val textBox = LinearLayout(this)
    textBox.orientation = LinearLayout.VERTICAL
    textBox.layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
    val titleView = TextView(this)
    titleView.text = title
    titleView.textSize = 17f
    titleView.typeface = Typeface.DEFAULT_BOLD
    titleView.setTextColor(Color.parseColor("#238A4B"))
    val messageView = TextView(this)
    messageView.text = message
    messageView.textSize = 16f
    messageView.setTextColor(Color.parseColor("#1F2937"))
    messageView.setPadding(0, authDp(8), 0, 0)
    messageView.setLineSpacing(3f, 1.05f)
    textBox.addView(titleView)
    textBox.addView(messageView)
    card.addView(checkIcon)
    card.addView(textBox)
    return card
}

fun Activity.labeledPasswordInputWithEye(parent: LinearLayout, label: String, hint: String): EditText {
    val labelView = TextView(this)
    labelView.text = label
    labelView.textSize = 16f
    labelView.typeface = Typeface.DEFAULT_BOLD
    labelView.setTextColor(Color.parseColor("#64748B"))
    val labelParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    labelParams.setMargins(0, authDp(2), 0, authDp(4))
    labelView.layoutParams = labelParams
    parent.addView(labelView)
    val box = LinearLayout(this)
    box.orientation = LinearLayout.HORIZONTAL
    box.gravity = Gravity.CENTER_VERTICAL
    box.setPadding(authDp(18), 0, authDp(18), 0)
    val bg = GradientDrawable()
    bg.setColor(Color.WHITE)
    bg.cornerRadius = authDp(18).toFloat()
    bg.setStroke(authDp(1), Color.parseColor("#CBD5E1"))
    box.background = bg
    box.elevation = authDp(2).toFloat()
    val boxParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, authDp(70))
    boxParams.setMargins(0, 0, 0, authDp(24))
    box.layoutParams = boxParams
    val lockIcon = SmallLockView(this)
    val lockParams = LinearLayout.LayoutParams(authDp(38), ViewGroup.LayoutParams.MATCH_PARENT)
    lockParams.setMargins(0, 0, authDp(12), 0)
    lockIcon.layoutParams = lockParams
    val input = EditText(this)
    input.hint = hint
    input.textSize = 18f
    input.setSingleLine(true)
    input.setTextColor(Color.parseColor("#111827"))
    input.setHintTextColor(Color.parseColor("#9CA3AF"))
    input.setPadding(0, 0, authDp(8), 0)
    input.background = null
    input.inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
    val inputParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f)
    input.layoutParams = inputParams
    val eyeButton = EyeToggleView(this)
    eyeButton.isClosed = true
    val eyeParams = LinearLayout.LayoutParams(authDp(46), ViewGroup.LayoutParams.MATCH_PARENT)
    eyeButton.layoutParams = eyeParams
    var visible = false
    eyeButton.setOnClickListener {
        visible = !visible
        input.inputType = if (visible) InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD else InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
        eyeButton.isClosed = !visible
        eyeButton.invalidate()
        input.setSelection(input.text.length)
    }
    box.addView(lockIcon)
    box.addView(input)
    box.addView(eyeButton)
    parent.addView(box)
    return input
}

fun Activity.setPasswordMainButton(text: String, colorCode: String): Button {
    val button = Button(this)
    button.text = text
    button.textSize = 18f
    button.typeface = Typeface.DEFAULT_BOLD
    button.setTextColor(Color.WHITE)
    button.isAllCaps = false
    button.elevation = authDp(5).toFloat()
    val bg = GradientDrawable()
    bg.setColor(Color.parseColor(colorCode))
    bg.cornerRadius = authDp(18).toFloat()
    button.background = bg
    val params = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, authDp(66))
    params.setMargins(0, authDp(8), 0, authDp(16))
    button.layoutParams = params
    return button
}
