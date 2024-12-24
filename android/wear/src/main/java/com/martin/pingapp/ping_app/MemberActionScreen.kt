package com.team.pingapp.ping_app

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.*
import androidx.navigation.NavHostController
import androidx.lifecycle.viewmodel.compose.viewModel

@Composable
fun MemberActionScreen(
    navController: NavHostController,
    memberId: String?
) {
    val viewModel: MemberActionViewModel = viewModel(
        factory = WearViewModelFactory(LocalContext.current)
    )

    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center
    ) {
        Button(
            onClick = { navController.navigate("messageTemplates/$memberId") },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Send Message")
        }
        Spacer(modifier = Modifier.height(8.dp))
        Button(
            onClick = { navController.navigate("audioRecording/$memberId") },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Send Audio")
        }
        Spacer(modifier = Modifier.height(8.dp))
        Button(
            onClick = {
                memberId?.let { id ->
                    viewModel.sendPing(id)
                }
            },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Send Ping")
        }
    }
}