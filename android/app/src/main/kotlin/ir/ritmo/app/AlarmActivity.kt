package ir.ritmo.app

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class AlarmActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val km = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            km?.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }

        setContentView(R.layout.activity_alarm)

        val reminderId = intent.getStringExtra("reminderId") ?: ""
        val title = intent.getStringExtra("title") ?: getString(R.string.notif_vital_routine_title)
        val firstStep = intent.getStringExtra("firstPhysicalStep")

        val clockView = findViewById<TextView>(R.id.alarm_clock_text)
        val titleView = findViewById<TextView>(R.id.alarm_title_text)
        val firstStepContainer = findViewById<LinearLayout>(R.id.first_step_container)
        val firstStepText = findViewById<TextView>(R.id.first_step_text)
        val btnDone = findViewById<Button>(R.id.btn_alarm_done)
        val btnMinimal = findViewById<Button>(R.id.btn_alarm_minimal)
        val btnLater = findViewById<Button>(R.id.btn_alarm_later)

        val timeStr = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
        clockView.text = toPersianDigits(timeStr)
        titleView.text = title

        if (!firstStep.isNullOrEmpty()) {
            firstStepContainer.visibility = View.VISIBLE
            firstStepText.text = firstStep
        } else {
            firstStepContainer.visibility = View.GONE
        }

        btnDone.setOnClickListener {
            sendAction("DONE", reminderId)
            finish()
        }

        btnMinimal.setOnClickListener {
            sendAction("MINIMAL", reminderId)
            finish()
        }

        btnLater.setOnClickListener {
            sendAction("SNOOZE", reminderId)
            finish()
        }
    }

    private fun sendAction(actionType: String, reminderId: String) {
        val intent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = "com.ritmo.app.NOTIF_ACTION"
            putExtra("actionType", actionType)
            putExtra("reminderId", reminderId)
        }
        sendBroadcast(intent)
    }

    private fun toPersianDigits(input: String): String {
        val fa = charArrayOf('۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹')
        val sb = StringBuilder()
        for (ch in input.toCharArray()) {
            if (ch in '0'..'9') {
                sb.append(fa[ch - '0'])
            } else {
                sb.append(ch)
            }
        }
        return sb.toString()
    }
}
