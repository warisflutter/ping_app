package com.team.pingapp.ping_app

import android.content.Context
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileInputStream
import kotlinx.coroutines.tasks.await
import androidx.core.content.ContextCompat
import android.Manifest
import android.util.Base64
import org.json.JSONObject

class AudioRecordingViewModel(private val context: Context) : ViewModel() {
    private var mediaRecorder: MediaRecorder? = null
    private var audioFile: File? = null

    private val _isRecording = MutableStateFlow(false)
    val isRecording = _isRecording.asStateFlow()

    private val _permissionGranted = MutableStateFlow(false)
    val permissionGranted = _permissionGranted.asStateFlow()

    init {
        checkPermission()
    }

    fun checkPermission() {
        _permissionGranted.value = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    fun startRecording() {
        if (!_permissionGranted.value) {
            Log.e("AudioRecordingViewModel", "Recording permission not granted")
            return
        }
        viewModelScope.launch {
            try {
                audioFile = File(context.cacheDir, "audio_message.3gp")
                mediaRecorder = MediaRecorder().apply {
                    setAudioSource(MediaRecorder.AudioSource.MIC)
                    setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
                    setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
                    setOutputFile(audioFile?.absolutePath)
                    prepare()
                    start()
                }
                _isRecording.value = true
            } catch (e: Exception) {
                Log.e("AudioRecordingViewModel", "Error starting recording", e)
            }
        }
    }

    fun stopRecording() {
        viewModelScope.launch {
            try {
                mediaRecorder?.apply {
                    stop()
                    release()
                }
                mediaRecorder = null
                _isRecording.value = false
            } catch (e: Exception) {
                // Handle error
            }
        }
    }

    fun sendAudioOne(memberId: String) {
        viewModelScope.launch {
            try {
                val audioData = audioFile?.let { FileInputStream(it).readBytes() } ?: return@launch
                val messageClient = Wearable.getMessageClient(context)
                val nodes = Wearable.getNodeClient(context).connectedNodes.await()
                nodes.forEach { node ->
                    messageClient.sendMessage(node.id, "/send_audio", audioData).await()
                }
                // Clean up the audio file
                audioFile?.delete()
            } catch (e: Exception) {
                // Handle error
            }
        }
    }

    fun sendAudio(memberId: String) {
        viewModelScope.launch {
            try {
                val audioData = audioFile?.let { FileInputStream(it).readBytes() } ?: return@launch

                // Convert audio data to Base64 string
                val base64Audio = Base64.encodeToString(audioData, Base64.DEFAULT)

                // Create a JSON object with userId and audioData
                val jsonMessage = JSONObject().apply {
                    put("userId", memberId)
                    put("audioData", base64Audio)
                }

                val messageClient = Wearable.getMessageClient(context)
                val nodes = Wearable.getNodeClient(context).connectedNodes.await()
                nodes.forEach { node ->
                    messageClient.sendMessage(node.id, "/send_audio", jsonMessage.toString().toByteArray()).await()
                }

                // Clean up the audio file
                audioFile?.delete()
            } catch (e: Exception) {
                // Handle error
                Log.e("WearOS", "Error sending audio: ${e.message}")
            }
        }
    }
}