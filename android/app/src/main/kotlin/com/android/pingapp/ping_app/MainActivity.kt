package com.team.pingapp.ping_app

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.android.gms.tasks.Task

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("FlutterWatchConnectivity", "configureFlutterEngine")
        flutterEngine.plugins.add(WearOSPlugin()) // Assuming WearOSPlugin() is your custom plugin
    }

    override fun onDestroy() {
        super.onDestroy()
        println("App is terminated")
        updateTerminationStatus(false)
    }

    private fun updateTerminationStatus(isOnline: Boolean) {

        println("Called => updateTerminationStatus")
        print(isOnline)

        val user = FirebaseAuth.getInstance().currentUser
        if (user != null) {
            val userId = user.uid
            val usersRef = FirebaseFirestore.getInstance().collection("users").document(userId)

            usersRef.update(
                mapOf(
                    "isOnline" to isOnline,
                    "lastActive" to FieldValue.serverTimestamp()
                )
            ).addOnCompleteListener { task: Task<Void> ->
                if (task.isSuccessful) {
                    println("Termination status updated successfully")
                } else {
                    println("Error updating termination status: ${task.exception?.localizedMessage}")
                }
            }
        } else {
            println("User not found")
        }
    }
}
