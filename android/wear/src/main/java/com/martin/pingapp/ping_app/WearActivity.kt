package com.martin.pingapp.ping_app

import AudioRecordingScreen
import MessageTemplatesScreen
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import com.google.android.gms.wearable.Wearable

class WearActivity : ComponentActivity(){

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("WearWatchConnectivity", "WearActivity created")
        requestDataFromPhone()

        setContent {
            WearApp()
        }
    }
    private fun requestDataFromPhone() {
        Log.d("WearWatchConnectivity:", "Requesting data from phone")
        sendMessageToPhone("/request_auth_data", "")
        sendMessageToPhone("/request_team_members", "")
        sendMessageToPhone("/request_message_templates", "")
    }


    private fun sendMessageToPhone(path: String, message: String) {
        Wearable.getMessageClient(this).sendMessage("*", path, message.toByteArray())
            .addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    Log.d("WearWatchConnectivity", "Message sent to phone: $path")
                } else {
                    Log.e("WearWatchConnectivity", "Failed to send message to phone: ${task.exception}")
                }
            }
    }

}

@Composable
fun WearApp() {
    MaterialTheme {
        val navController = rememberSwipeDismissableNavController()
        Scaffold(
            modifier = Modifier.fillMaxSize(),
        ) {
            SwipeDismissableNavHost(
                navController = navController,
                startDestination = "memberList"
            ) {
                composable("memberList") {
                    MemberListScreen(navController)
                }
                composable("memberAction/{memberId}") { backStackEntry ->
                    val memberId = backStackEntry.arguments?.getString("memberId")
                    MemberActionScreen(navController, memberId)
                }
                composable("messageTemplates/{memberId}") { backStackEntry ->
                    val memberId = backStackEntry.arguments?.getString("memberId")
                    MessageTemplatesScreen(navController, memberId)
                }
                composable("audioRecording/{memberId}") { backStackEntry ->
                    val memberId = backStackEntry.arguments?.getString("memberId")
                    AudioRecordingScreen(navController, memberId)
                }
            }
        }
    }
}
