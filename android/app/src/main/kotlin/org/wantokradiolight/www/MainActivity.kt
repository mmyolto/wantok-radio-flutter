package org.wantokradiolight.www

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceActivity

// AudioServiceActivity shares the Flutter engine with the background
// playback service so the radio keeps playing when the app is closed.
class MainActivity : AudioServiceActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createDevotionalChannel()
    }

    /** Channel for the 5:00 am and 9:00 pm devotionals (id must match the Cloud Function). */
    private fun createDevotionalChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            "devotionals",
            "Daily devotionals",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Morning (5:00 am) and evening (9:00 pm) devotionals from the Radio Chaplain"
        }
        manager.createNotificationChannel(channel)
    }
}
