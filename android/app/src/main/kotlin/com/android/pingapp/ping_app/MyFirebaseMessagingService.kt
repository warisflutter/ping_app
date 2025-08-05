package com.team.pingapp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import org.json.JSONObject
import com.google.android.gms.wearable.Wearable

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d("MyFirebaseMessagingService", "From: ${remoteMessage.from}")
        remoteMessage.data.isNotEmpty().let {
            val notificationData = remoteMessage.data["notificationData"]
            notificationData?.let {
                val jsonObject = JSONObject(it)
                sendNotificationToWearOS(jsonObject)
            }
        }

//        showNotification("Ping App", "Message");
    }

    private fun sendNotificationToWearOS(notificationData: JSONObject) {
        Log.d(
            "MyFirebaseMessagingService",
            "Sending notification to Wear OS ${notificationData.toString()}"
        )
        Wearable.getMessageClient(this).sendMessage(
            "*", // Node ID (all nodes)
            "/notificationFb",
            notificationData.toString().toByteArray()
        ).addOnCompleteListener { task ->
            if (task.isSuccessful) {
                // Notification sent successfully to Wear OS
                // You might want to log this or handle it in some way
            } else {
                // Failed to send notification to Wear OS
                // Handle the error
            }
        }
    }

    private fun showNotification(title: String?, message: String?) {
        val channelId = "MyFirebaseChannel"
        val notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setAutoCancel(true)

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // For Android Oreo and above, we need to create a notification channel
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Ping App",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            notificationManager.createNotificationChannel(channel)
        }

        notificationManager.notify(0, notificationBuilder.build())
    }

    override fun onNewToken(token: String) {
        Log.d("FCM", "New token: $token")
        // Here you can send the token to your server
    }
}