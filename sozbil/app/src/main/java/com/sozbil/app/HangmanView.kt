package com.sozbil.app

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.util.AttributeSet
import android.view.View
import kotlin.math.min

class HangmanView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null
) : View(context, attrs) {

    var wrongGuesses: Int = 0
        set(value) {
            field = value.coerceIn(0, 6)
            invalidate()
        }

    // --- VISUAL STYLE ONLY (no logic changes) ---

    // Warm "wood" gallows
    private val gallowsPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        color = 0xFF8B5A2B.toInt() // wood brown
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
    }

    // Light "rope" color
    private val ropePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        color = 0xFFD2B48C.toInt() // rope beige
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
    }

    // Character body (neutral; turns red in danger mode)
    private val bodyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        color = 0xFF333333.toInt() // soft dark gray
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        val w = width.toFloat().coerceAtLeast(1f)
        val h = height.toFloat().coerceAtLeast(1f)

        /**
         * Hangman is vertical, so we bias sizing to height to avoid weird tablet proportions.
         * - d is the effective drawing size (a square area we draw inside).
         * - Clamp so it stays visually consistent across devices.
         */
        val dRaw = min(w * 0.90f, h * 0.92f)          // prefer height slightly
        val dMin = min(w, h) * 0.70f                   // don't become too tiny
        val dMax = min(w, h) * 0.98f                   // don't exceed view bounds
        val d = dRaw.coerceIn(dMin, dMax)

        // Center the square drawing area
        val left = (w - d) / 2f
        val top = (h - d) / 2f

        // Stroke widths scaled but clamped (prevents thick lines on tablets)
        // Visual tweak: slightly softer than before
        val baseStroke = (d * 0.026f).coerceIn(4f, 9f)
        val thinStroke = (d * 0.018f).coerceIn(3f, 7f)

        gallowsPaint.strokeWidth = baseStroke
        ropePaint.strokeWidth = thinStroke
        bodyPaint.strokeWidth = thinStroke

        // Gallows geometry (all based on d)
        val baseY = top + d * 0.90f
        val poleX = left + d * 0.22f
        val topY = top + d * 0.12f
        val beamX = left + d * 0.72f
        val ropeTopY = top + d * 0.20f
        val ropeLen = d * 0.10f
        val ropeBottomY = ropeTopY + ropeLen


        // Base + pole + beam + rope
        canvas.drawLine(left + d * 0.08f, baseY, left + d * 0.78f, baseY, gallowsPaint)
        canvas.drawLine(poleX, baseY, poleX, topY, gallowsPaint)
        canvas.drawLine(poleX, topY, beamX, topY, gallowsPaint)
        canvas.drawLine(beamX, topY, beamX, ropeBottomY, ropePaint)

        /**
         * Person proportions:
         * Make the head based on rope length / body space instead of just d,
         * so it cannot become "huge head" on tablets with constrained height.
         */
        val availableBodySpace = (baseY - ropeBottomY).coerceAtLeast(1f)
        val headR = (availableBodySpace * 0.10f).coerceIn(d * 0.045f, d * 0.070f)

        val headCx = beamX
        val headCy = ropeBottomY + headR

        // Body sizes relative to available vertical space (more stable)
        val bodyLen = (availableBodySpace * 0.28f).coerceIn(d * 0.18f, d * 0.28f)
        val shoulderY = headCy + headR + d * 0.03f
        val hipY = headCy + headR + bodyLen

        val armLen = (d * 0.12f).coerceIn(d * 0.09f, d * 0.14f)
        val legLen = (availableBodySpace * 0.18f).coerceIn(d * 0.12f, d * 0.18f)

        // Danger mode color when close to losing (visual only)
        bodyPaint.color = if (wrongGuesses >= 5) 0xFFE53935.toInt() else 0xFF333333.toInt()

        // Draw person by steps (UNCHANGED logic)
        if (wrongGuesses >= 1) {
            canvas.drawCircle(headCx, headCy, headR, bodyPaint)
        }
        if (wrongGuesses >= 2) {
            canvas.drawLine(headCx, headCy + headR, headCx, hipY, bodyPaint)
        }
        if (wrongGuesses >= 3) {
            canvas.drawLine(headCx, shoulderY, headCx - armLen, shoulderY + d * 0.06f, bodyPaint)
        }
        if (wrongGuesses >= 4) {
            canvas.drawLine(headCx, shoulderY, headCx + armLen, shoulderY + d * 0.06f, bodyPaint)
        }
        if (wrongGuesses >= 5) {
            canvas.drawLine(headCx, hipY, headCx - armLen * 0.9f, hipY + legLen, bodyPaint)
        }
        if (wrongGuesses >= 6) {
            canvas.drawLine(headCx, hipY, headCx + armLen * 0.9f, hipY + legLen, bodyPaint)
        }
    }
}
