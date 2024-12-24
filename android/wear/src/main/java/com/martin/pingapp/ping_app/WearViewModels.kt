package com.team.pingapp.ping_app

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

import android.content.Context
import android.util.Log
import androidx.lifecycle.ViewModelProvider
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.tasks.await

class MemberListViewModel : ViewModel() {
    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error = _error.asStateFlow()

    val teamMembers = WearableDataLayerListenerService.teamMembers
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    init {
        loadTeamMembers()
    }

    private fun loadTeamMembers() {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                // Simulate network call
                delay(1000)
                // If loading fails, set error
                // _error.value = "Failed to load team members"
            } catch (e: Exception) {
                _error.value = e.message
            } finally {
                _isLoading.value = false
            }
        }
    }
}

class MessageTemplatesViewModel(private val context: Context) : ViewModel() {
    val messageTemplates = WearableDataLayerListenerService.messageTemplates
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    fun sendMessage(memberId: String, message: String) {
        Log.d("MessageTemplatesViewModel", "Sending message function $context")
        viewModelScope.launch {
            try{
                Log.d("MessageTemplatesViewModel", "Inside ViewModelScope")
                val messageClient = Wearable.getMessageClient(context)
                Log.d("MessageTemplatesViewModel", "After getting client")
                val nodes = Wearable.getNodeClient(context).connectedNodes.await()
                Log.d("MessageTemplatesViewModel", "node ${nodes.size}")
                nodes.forEach { node ->
                    Log.d("MessageTemplatesViewModel", "Sending message to node: ${node.id}")
                    messageClient.sendMessage(
                        node.id,
                        "/send_message",
                        "$memberId:$message".toByteArray()
                    ).await()
                }
            } catch (e: Exception) {
                Log.e("MessageTemplatesViewModel", "Error in sendMessage", e)
            }
        }
    }
}

class MemberActionViewModel(private val context: Context) : ViewModel() {
    fun sendPing(memberId: String) {
        viewModelScope.launch {
            val messageClient = Wearable.getMessageClient(context)
            val nodes = Wearable.getNodeClient(context).connectedNodes.await()
            nodes.forEach { node ->
                messageClient.sendMessage(
                    node.id,
                    "/send_ping",
                    memberId.toByteArray()
                ).await()
            }
        }
    }
}

class WearViewModelFactory(private val context: Context) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return when {
            modelClass.isAssignableFrom(MessageTemplatesViewModel::class.java) -> MessageTemplatesViewModel(context) as T
            modelClass.isAssignableFrom(AudioRecordingViewModel::class.java) -> AudioRecordingViewModel(context) as T
            modelClass.isAssignableFrom(MemberActionViewModel::class.java) -> MemberActionViewModel(context) as T
            else -> throw IllegalArgumentException("Unknown ViewModel class")
        }
    }
}