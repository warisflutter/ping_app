package com.martin.pingapp.ping_app

import android.util.Base64
import android.util.Log
import androidx.annotation.NonNull
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONArray
import org.json.JSONObject

class WearOSPlugin : FlutterPlugin, MethodCallHandler, MessageClient.OnMessageReceivedListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: android.content.Context
    private lateinit var messageClient: MessageClient
    private val audioChunks = mutableMapOf<String, MutableList<ByteArray>>()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d("AndroidWatchConnectivity:", "onAttachedToEngine");
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.martin.pingApp/test")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        messageClient = Wearable.getMessageClient(context)
        messageClient.addListener(this)
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        Log.d("AndroidWatchConnectivity:", "Message received from wear: ${messageEvent.path}")
        when (messageEvent.path) {
            "/ping_response" -> handlePingResponse(messageEvent.data)
            "/send_ping" -> handlePing(messageEvent.data)
            "/send_message" -> handleTextMessage(messageEvent.data)
            "/send_audio" -> handleVoiceNote(messageEvent.data)
            "/send_audio_chunk" -> handleVoiceNoteChunk(messageEvent.data)
            "/request_auth_data" -> channel.invokeMethod("requestAuthData", null)
            "/request_team_members" -> channel.invokeMethod("requestTeamMembers", null)
            "/request_message_templates" -> channel.invokeMethod("requestMessageTemplates", null)
            else -> Log.d("AndroidWatchConnectivity:", "Unknown message path: ${messageEvent.path}")
        }
    }

    private fun handlePingResponse(data: ByteArray) {
        try {
            val jsonObject = JSONObject(String(data))
            val notificationId = jsonObject.getString("notificationId")
            val response = jsonObject.getBoolean("response")

            // Forward the ping response to Flutter
            channel.invokeMethod("receivePingResponse", mapOf(
                "notificationId" to notificationId,
                "response" to response
            ))
        } catch (e: Exception) {
            Log.e("WearOSPlugin", "Error parsing ping response", e)
        }
    }

    private fun handlePing(data: ByteArray) {
        val userId = String(data)
        Log.d("AndroidWatchConnectivity:", "Received ping from user: $userId")
        channel.invokeMethod("receivePing", mapOf("userId" to userId))
    }

    private fun handleTextMessage(data: ByteArray) {
        Log.d("AndroidWatchConnectivity:", "Received text message: ${String(data)}")
        val message = String(data)
        val parts = message.split(":", limit = 2)
        if (parts.size == 2) {
            val userId = parts[0]
            val messageText = parts[1]
            Log.d("AndroidWatchConnectivity:", "Received text message from user: $userId, message: $messageText")
            channel.invokeMethod("receiveTextMessage", mapOf("userId" to userId, "message" to messageText))
        }
    }

    private fun handleVoiceNoteOld(data: ByteArray) {
        val message = JSONObject(String(data))
        val userId = message.getString("userId")
        val audioData = message.getString("audioData").toByteArray()
        Log.d("AndroidWatchConnectivity:", "Received voice note from user: $userId, audio data length: ${audioData.size}")
        channel.invokeMethod("receiveVoiceNote", mapOf("userId" to userId, "audioData" to audioData))
    }

    private fun handleVoiceNote(data: ByteArray) {
        try {
            val jsonString = String(data)
            val message = JSONObject(jsonString)
            val userId = message.getString("userId")
            val base64Audio = message.getString("audioData")

            // Decode Base64 string back to ByteArray
            val audioData = Base64.decode(base64Audio, Base64.DEFAULT)

            Log.d("AndroidWatchConnectivity", "Received voice note from user: $userId, audio data length: ${audioData.size}")

            // Forward to Flutter
            channel.invokeMethod("receiveVoiceNote", mapOf(
                "userId" to userId,
                "audioData" to audioData
            ))
        } catch (e: Exception) {
            Log.e("AndroidWatchConnectivity", "Error processing voice note: ${e.message}")
        }
    }

    private fun handleVoiceNoteChunk(data: ByteArray) {
        val message = JSONObject(String(data))
        val userId = message.getString("userId")
        val chunkIndex = message.getInt("chunkIndex")
        val totalChunks = message.getInt("totalChunks")
        val audioChunk = message.getString("audioData").toByteArray()

        if (!audioChunks.containsKey(userId)) {
            audioChunks[userId] = mutableListOf()
        }
        audioChunks[userId]?.add(audioChunk)

        if (audioChunks[userId]?.size == totalChunks) {
            val completeAudioData = audioChunks[userId]?.reduce { acc, bytes -> acc + bytes }
            if (completeAudioData != null) {
                Log.d("AndroidWatchConnectivity:", "Received complete voice note from user: $userId, audio data length: ${completeAudioData.size}")
                channel.invokeMethod("receiveVoiceNote", mapOf("userId" to userId, "audioData" to completeAudioData))
            }
            audioChunks.remove(userId)
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Log.d("AndroidWatchConnectivity:", "onMethodCall: ${call.method}")
        when (call.method) {
            "sendAuthData" -> sendAuthData(call.arguments as Map<String, Any>, result)
            "memberList" -> handleMemberList(call.arguments as Map<String, Any>, result)
            "sendMessageTemplates" -> handleMessageTemplates(
                call.arguments as Map<String, Any>,
                result
            )

            "sendNotificationToNative" -> sendNotification(
                call.arguments as Map<String, Any>,
                result
            )

            else -> result.notImplemented()
        }
    }


    private fun sendAuthData(authData: Map<String, Any>, result: Result) {
        Wearable.getMessageClient(context).sendMessage(
            "*", // Node ID (all nodes)
            "/auth_data",
            authData.toString().toByteArray()
        ).addOnCompleteListener { task ->
            if (task.isSuccessful) {
                result.success(null)
            } else {
                result.error("SEND_FAILED", "Failed to send auth data", null)
            }
        }
    }

    private fun handleMemberList(args: Map<String, Any>, result: Result) {
        if (args.containsKey("members")) {
            val members = args["members"] as List<Map<String, Any>>
            sendTeamMembers(members, result)
        } else if (args.containsKey("error")) {
            val errorMessage = args["error"] as String
            sendErrorToWear("memberListError", errorMessage)
            result.success("Error fetching members: $errorMessage")
        } else {
            result.error("INVALID_ARGUMENT", "Expected a list of members or an error message", null)
        }
    }

    private fun handleMessageTemplates(args: Map<String, Any>, result: Result) {
        if (args.containsKey("templates")) {
            val templates = args["templates"] as List<Map<String, Any>>
            sendMessageTemplates(templates, result)
        } else {
            result.error("INVALID_ARGUMENT", "Expected an array of message templates", null)
        }
    }


    private fun sendTeamMembers(members: List<Map<String, Any>>, result: Result) {
        val jsonString = JSONArray(members.map { map ->
            JSONObject(map)
        }).toString()
        Wearable.getMessageClient(context).sendMessage(
            "*", // Node ID (all nodes)
            "/team_members",
            jsonString.toByteArray()
        ).addOnCompleteListener { task ->
            if (task.isSuccessful) {
                result.success(null)
            } else {
                result.error("SEND_FAILED", "Failed to send team members", null)
            }
        }
    }

    private fun sendMessageTemplates(templates: List<Map<String, Any>>, result: Result) {
        val jsonString = JSONArray(templates.map { map ->
            JSONObject(map)
        }).toString()
        Log.d("AndroidWatchConnectivity", "Sending message templates: $jsonString")
        Wearable.getMessageClient(context).sendMessage(
            "*", // Node ID (all nodes)
            "/message_templates",
            jsonString.toByteArray()
        ).addOnCompleteListener { task ->
            if (task.isSuccessful) {
                result.success(null)
            } else {
                result.error("SEND_FAILED", "Failed to send message templates", null)
            }
        }
    }

    private fun sendNotification(notificationData: Map<String, Any>, result: Result) {
        val jsonString = JSONObject(notificationData).toString()
        Wearable.getMessageClient(context).sendMessage(
            "*", // Node ID (all nodes)
            "/notification",
            jsonString.toByteArray()
        ).addOnCompleteListener { task ->
            if (task.isSuccessful) {
                result.success(null)
            } else {
                result.error("SEND_FAILED", "Failed to send notification", null)
            }
        }
    }

    private fun sendErrorToWear(errorType: String, message: String) {
        val jsonString = JSONObject().apply {
            put("type", errorType)
            put("message", message)
        }.toString()
        Wearable.getMessageClient(context).sendMessage("*", "/error", jsonString.toByteArray())
            .addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    Log.d("AndroidWatchConnectivity", "Error sent to wear: $errorType")
                } else {
                    Log.e(
                        "AndroidWatchConnectivity",
                        "Failed to send error to wear: ${task.exception}"
                    )
                }
            }
    }


    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d("AndroidWatchConnectivity:", "onDetachedFromEngine");
        channel.setMethodCallHandler(null)
    }
}