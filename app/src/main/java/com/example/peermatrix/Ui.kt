package com.example.peermatrix

import android.app.Activity
import android.content.Context
import android.text.InputType
import android.widget.*

object Ui {

    fun root(activity: Activity): LinearLayout {
        val scrollView = ScrollView(activity)

        val layout = LinearLayout(activity)
        layout.orientation = LinearLayout.VERTICAL
        layout.setPadding(dp(activity, 20), dp(activity, 25), dp(activity, 20), dp(activity, 25))

        scrollView.addView(layout)
        activity.setContentView(scrollView)

        return layout
    }

    fun title(context: Context, text: String): TextView {
        val tv = TextView(context)
        tv.text = text
        tv.textSize = 25f
        tv.setPadding(0, dp(context, 10), 0, dp(context, 16))
        return tv
    }

    fun subtitle(context: Context, text: String): TextView {
        val tv = TextView(context)
        tv.text = text
        tv.textSize = 16f
        tv.setPadding(0, dp(context, 6), 0, dp(context, 6))
        return tv
    }

    fun input(context: Context, hint: String, password: Boolean = false): EditText {
        val et = EditText(context)
        et.hint = hint
        et.textSize = 16f

        if (password) {
            et.inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
        }

        et.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            setMargins(0, dp(context, 6), 0, dp(context, 6))
        }

        return et
    }

    fun button(context: Context, text: String): Button {
        val btn = Button(context)
        btn.text = text
        btn.textSize = 15f

        btn.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            setMargins(0, dp(context, 6), 0, dp(context, 6))
        }

        return btn
    }

    fun card(context: Context): LinearLayout {
        val box = LinearLayout(context)
        box.orientation = LinearLayout.VERTICAL
        box.setPadding(dp(context, 14), dp(context, 12), dp(context, 14), dp(context, 12))
        box.setBackgroundResource(android.R.drawable.dialog_holo_light_frame)

        box.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            setMargins(0, dp(context, 8), 0, dp(context, 8))
        }

        return box
    }

    fun dp(context: Context, value: Int): Int {
        return (value * context.resources.displayMetrics.density).toInt()
    }
}