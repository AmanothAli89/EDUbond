package com.example.peermatrix

import android.content.Context
import android.graphics.*
import android.graphics.drawable.GradientDrawable
import android.view.View

private fun dp(context: Context, value: Int): Int {
    return (value * context.resources.displayMetrics.density).toInt()
}

class EyeToggleView(context: Context) : View(context) {
    var isClosed: Boolean = true
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)

    init {
        isClickable = true
        isFocusable = true
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        paint.color = Color.parseColor("#334155")
        paint.strokeWidth = dp(context, 2).toFloat()
        paint.style = Paint.Style.STROKE
        paint.strokeCap = Paint.Cap.ROUND
        val padding = dp(context, 7).toFloat()
        val centerY = h / 2f
        val eyeRect = RectF(padding, centerY - dp(context, 9), w - padding, centerY + dp(context, 9))
        canvas.drawOval(eyeRect, paint)
        paint.style = Paint.Style.FILL
        canvas.drawCircle(w / 2f, centerY, dp(context, 4).toFloat(), paint)
        if (isClosed) {
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = dp(context, 2).toFloat()
            canvas.drawLine(padding + dp(context, 2), centerY + dp(context, 14), w - padding - dp(context, 2), centerY - dp(context, 14), paint)
        }
    }
}

class GreenLockBadgeView(context: Context) : View(context) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    init {
        val bg = GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM, intArrayOf(Color.parseColor("#DDF8DE"), Color.parseColor("#EFFFF1")))
        bg.cornerRadius = dp(context, 22).toFloat()
        background = bg
    }
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        val cx = w / 2f
        val cy = h / 2f
        paint.color = Color.parseColor("#197A43")
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = dp(context, 5).toFloat()
        paint.strokeCap = Paint.Cap.ROUND
        val shackle = RectF(cx - dp(context, 16), cy - dp(context, 24), cx + dp(context, 16), cy + dp(context, 10))
        canvas.drawArc(shackle, 200f, 140f, false, paint)
        paint.style = Paint.Style.FILL
        val body = RectF(cx - dp(context, 22), cy - dp(context, 4), cx + dp(context, 22), cy + dp(context, 24))
        canvas.drawRoundRect(body, dp(context, 6).toFloat(), dp(context, 6).toFloat(), paint)
        paint.color = Color.WHITE
        canvas.drawCircle(cx, cy + dp(context, 8), dp(context, 4).toFloat(), paint)
        paint.strokeWidth = dp(context, 3).toFloat()
        paint.style = Paint.Style.STROKE
        canvas.drawLine(cx, cy + dp(context, 11), cx, cy + dp(context, 17), paint)
    }
}

class SmallLockView(context: Context) : View(context) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        val cx = w / 2f
        val cy = h / 2f
        paint.color = Color.parseColor("#64748B")
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = dp(context, 3).toFloat()
        paint.strokeCap = Paint.Cap.ROUND
        val shackle = RectF(cx - dp(context, 10), cy - dp(context, 19), cx + dp(context, 10), cy + dp(context, 5))
        canvas.drawArc(shackle, 200f, 140f, false, paint)
        paint.style = Paint.Style.STROKE
        val body = RectF(cx - dp(context, 14), cy - dp(context, 3), cx + dp(context, 14), cy + dp(context, 18))
        canvas.drawRoundRect(body, dp(context, 4).toFloat(), dp(context, 4).toFloat(), paint)
    }
}

class LockBadgeView(context: Context) : View(context) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    init {
        val bg = GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM, intArrayOf(Color.parseColor("#4EA3FF"), Color.parseColor("#2F80ED")))
        bg.cornerRadius = dp(context, 18).toFloat()
        background = bg
    }
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        val cx = w / 2f
        val cy = h / 2f
        paint.color = Color.WHITE
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = dp(context, 4).toFloat()
        paint.strokeCap = Paint.Cap.ROUND
        val shackle = RectF(cx - dp(context, 13), cy - dp(context, 22), cx + dp(context, 13), cy + dp(context, 6))
        canvas.drawArc(shackle, 200f, 140f, false, paint)
        paint.style = Paint.Style.FILL
        val body = RectF(cx - dp(context, 19), cy - dp(context, 4), cx + dp(context, 19), cy + dp(context, 22))
        canvas.drawRoundRect(body, dp(context, 5).toFloat(), dp(context, 5).toFloat(), paint)
        paint.color = Color.parseColor("#2F80ED")
        canvas.drawCircle(cx, cy + dp(context, 7), dp(context, 3).toFloat(), paint)
        paint.strokeWidth = dp(context, 2).toFloat()
        paint.style = Paint.Style.STROKE
        canvas.drawLine(cx, cy + dp(context, 9), cx, cy + dp(context, 15), paint)
    }
}

class AdminShieldLogoView(context: Context) : View(context) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    init {
        val bg = GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM, intArrayOf(Color.parseColor("#F2E7FF"), Color.parseColor("#F7F0FF")))
        bg.cornerRadius = dp(context, 24).toFloat()
        background = bg
        elevation = dp(context, 4).toFloat()
    }
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        val cx = w / 2f
        paint.color = Color.parseColor("#6A1B9A")
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = dp(context, 4).toFloat()
        paint.strokeCap = Paint.Cap.ROUND
        paint.strokeJoin = Paint.Join.ROUND
        val shield = Path()
        shield.moveTo(cx, h * 0.24f)
        shield.lineTo(w * 0.72f, h * 0.34f)
        shield.lineTo(w * 0.72f, h * 0.55f)
        shield.quadTo(w * 0.72f, h * 0.72f, cx, h * 0.82f)
        shield.quadTo(w * 0.28f, h * 0.72f, w * 0.28f, h * 0.55f)
        shield.lineTo(w * 0.28f, h * 0.34f)
        shield.close()
        canvas.drawPath(shield, paint)
        paint.strokeWidth = dp(context, 5).toFloat()
        val check = Path()
        check.moveTo(w * 0.40f, h * 0.53f)
        check.lineTo(w * 0.48f, h * 0.62f)
        check.lineTo(w * 0.64f, h * 0.43f)
        canvas.drawPath(check, paint)
    }
}

class AdminUserIconView(context: Context) : View(context) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        val cx = w / 2f
        paint.color = Color.parseColor("#6B7280")
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = dp(context, 3).toFloat()
        paint.strokeCap = Paint.Cap.ROUND
        canvas.drawCircle(cx, h * 0.36f, dp(context, 7).toFloat(), paint)
        val body = RectF(cx - dp(context, 13), h * 0.55f, cx + dp(context, 13), h * 0.82f)
        canvas.drawRoundRect(body, dp(context, 8).toFloat(), dp(context, 8).toFloat(), paint)
    }
}

class AdminLockIconView(context: Context) : View(context) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        val cx = w / 2f
        val cy = h / 2f
        paint.color = Color.parseColor("#6B7280")
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = dp(context, 3).toFloat()
        paint.strokeCap = Paint.Cap.ROUND
        val shackle = RectF(cx - dp(context, 10), cy - dp(context, 18), cx + dp(context, 10), cy + dp(context, 5))
        canvas.drawArc(shackle, 200f, 140f, false, paint)
        val body = RectF(cx - dp(context, 14), cy - dp(context, 4), cx + dp(context, 14), cy + dp(context, 18))
        canvas.drawRoundRect(body, dp(context, 4).toFloat(), dp(context, 4).toFloat(), paint)
    }
}
