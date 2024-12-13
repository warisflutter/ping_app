package com.martin.pingapp.ping_app

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Bundle
import android.util.Base64
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.IconButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.Icon
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import com.google.android.gms.wearable.Wearable
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class NotificationActivity : ComponentActivity() {
    private var mediaPlayer: MediaPlayer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val notificationType = intent.getStringExtra("type") ?: ""
        val userName = intent.getStringExtra("userName") ?: ""
        val content = intent.getStringExtra("content") ?: ""
        val data = intent.getStringExtra("data")
        val notificationId = intent.getStringExtra("id") ?: ""

        setContent {
            MaterialTheme {
                NotificationScreen(
                    type = notificationType,
                    userName = userName,
                    content = content,
                    audioUrl = data,
                    onClose = { finish() },
                    onPlayPause = { isPlaying ->
                        if (isPlaying) {
                            mediaPlayer?.start()
                        } else {
                            mediaPlayer?.pause()
                        }
                    },
                    onPingResponse = { response ->
                        sendPingResponse(notificationId, response)
                        finish()
                    }
                )
            }
        }

        if (notificationType == "audioMessage" && data != null) {
            try {
                setupAudioPlayback(data)
            } catch (e: Exception) {
                Log.e("NotificationActivity", "Error setting up audio playback", e)
                // Handle the error, maybe show a toast or update the UI
            }
        }
    }

    fun sendPingResponse(notificationId: String, response: Boolean) {
        val message = JSONObject().apply {
            put("type", "pingResponse")
            put("notificationId", notificationId)
            put("response", response)
        }.toString().toByteArray()

        Wearable.getMessageClient(this).sendMessage("*", "/ping_response", message)
            .addOnSuccessListener {
                Log.d("WearOS", "Ping response sent successfully")
            }
            .addOnFailureListener { e ->
                Log.e("WearOS", "Error sending ping response", e)
            }
    }

    private fun setupAudioPlayback(audioUrl: String) {
        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .build()
                )
                setDataSource(audioUrl)
                prepareAsync()
                setOnPreparedListener { mp ->
                    // The media is ready to be played
                    // You might want to enable the play button here if it's initially disabled
                }
                setOnErrorListener { mp, what, extra ->
                    Log.e("AudioPlayback", "Error during playback: $what, $extra")
                    true
                }
            }
        } catch (e: IOException) {
            Log.e("AudioPlayback", "Error setting up MediaPlayer", e)
            // Handle the error, maybe show a toast or update the UI
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        mediaPlayer?.release()
        mediaPlayer = null
    }
}

@Composable
fun NotificationScreen(
    type: String,
    userName: String,
    content: String,
    audioUrl: String?,
    onClose: () -> Unit,
    onPlayPause: (Boolean) -> Unit,
    onPingResponse: (Boolean) -> Unit
) {
    var isPlaying by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = userName,
            style = MaterialTheme.typography.title3,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        Text(
            text = content,
            style = MaterialTheme.typography.body1,
            modifier = Modifier.padding(bottom = 16.dp)
        )

        when (type) {
            "message" -> {
                Button(onClick = onClose) {
                    Text("Close")
                }
            }

            "audiomessage" -> {
                // ... (audio controls, same as before)
            }

            "ping" -> {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Button(onClick = { onPingResponse(true) }) {
                        Text("Yes")
                    }
                    Button(onClick = { onPingResponse(false) }) {
                        Text("No")
                    }
                }
            }
        }
    }
}