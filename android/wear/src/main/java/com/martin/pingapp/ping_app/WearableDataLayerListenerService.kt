package com.martin.pingapp.ping_app

import android.app.PendingIntent
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONArray
import org.json.JSONObject

class WearableDataLayerListenerService : WearableListenerService() {

    override fun onCreate() {
        super.onCreate()
        Log.d("WearWatchConnectivity:", "Watch: Data Layer Created");
    }

    companion object {
        private val _teamMembers = MutableStateFlow<List<TeamMember>>(emptyList())
        val teamMembers = _teamMembers.asStateFlow()

        private val _messageTemplates = MutableStateFlow<List<String>>(emptyList())
        val messageTemplates = _messageTemplates.asStateFlow()

        private val _authData = MutableStateFlow<AuthData?>(null)
        val authData = _authData.asStateFlow()
    }


    override fun onMessageReceived(messageEvent: MessageEvent) {
        Log.d("WearWatchConnectivity:", "Watch: Message Received ${messageEvent.path}");
        when (messageEvent.path) {
            "/test_message" -> {
                Log.d("WearWatchConnectivity:", "Test Message Received");
            }

            "/auth_data" -> handleAuthData(messageEvent.data)
            "/team_members" -> handleTeamMembers(messageEvent.data)
            "/message_templates" -> handleMessageTemplates(messageEvent.data)
            "/notificationFb" -> handleNotification(messageEvent.data)
            "/error" -> handleError(messageEvent.data)
        }
    }

    private fun handleNotification(notificationData: ByteArray) {
        val jsonString = String(notificationData)
        Log.d("WearWatchConnectivity:", "Handling Notification ${jsonString}");
        val json = JSONObject(jsonString)
        val notificationId = json.optString("notificationId");
        val fromId = json.optString("fromId");
        val toId = json.optString("toId");
        val type = json.getString("type")
        val content = json.getString("message")
        val data = json.getString("data")
        val response = json.getString("response")

        val intent = Intent(this, NotificationActivity::class.java).apply {
            putExtra("id", notificationId)
            putExtra("type", type)
            putExtra("userName", "Ping App")
            putExtra("content", content)
            putExtra("data", data)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("WearWatchConnectivity:", "Watch: Data Layer Service Started")
        return super.onStartCommand(intent, flags, startId)
    }


    private fun handleAuthData(data: ByteArray) {
        val jsonString = String(data)
        val json = JSONObject(jsonString)
        _authData.value = AuthData(
            userId = json.getString("userId"),
            teamLeadId = json.getString("teamLeadId")
        )
    }

    private fun handleTeamMembers(data: ByteArray) {
        Log.d("WearWatchConnectivity", "Raw data: ${data.contentToString()}");
        val jsonString = String(data)
        val jsonArray = JSONArray(jsonString)
        val members = mutableListOf<TeamMember>()
        for (i in 0 until jsonArray.length()) {
            val memberJson = jsonArray.getJSONObject(i)
            members.add(
                TeamMember(
                    id = memberJson.getString("id"),
                    name = memberJson.getString("name")
                )
            )
        }
        _teamMembers.value = members
    }

    private fun handleMessageTemplates(data: ByteArray) {
        val jsonString = String(data)
        val jsonArray = JSONArray(jsonString)
        val templates = mutableListOf<String>()
        for (i in 0 until jsonArray.length()) {
            val templateJson = jsonArray.getJSONObject(i)
            templates.add(templateJson.getString("message"))
        }
        _messageTemplates.value = templates
    }




    private fun handleError(data: ByteArray) {
        val jsonString = String(data)
        val json = JSONObject(jsonString)
        val errorType = json.getString("type")
        val errorMessage = json.getString("message")
        Log.e("WearWatchConnectivity", "Received error: $errorType - $errorMessage")
        // Handle the error appropriately (e.g., update UI, show notification)
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("WearWatchConnectivity:", "Watch: Data Layer Service Destroyed")
    }

}

data class AuthData(val userId: String, val teamLeadId: String)
data class TeamMember(val id: String, val name: String)