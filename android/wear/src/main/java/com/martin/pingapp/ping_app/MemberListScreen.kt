package com.team.pingapp.ping_app

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.wear.compose.material.*
import androidx.navigation.NavHostController
import androidx.lifecycle.viewmodel.compose.viewModel

@Composable
fun MemberListScreen(navController: NavHostController, viewModel: MemberListViewModel = viewModel()) {
    val members by viewModel.teamMembers.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val error by viewModel.error.collectAsState()

    when {
        isLoading -> {
            CircularProgressIndicator()
        }
        error != null -> {
            Text("Error: $error")
        }
        else -> {
            ScalingLazyColumn {
                item {
                    Text(
                        text = "Team Members",
                        style = MaterialTheme.typography.title1
                    )
                }
                items(members) { member ->
                    Chip(
                        onClick = { navController.navigate("memberAction/${member.id}") },
                        label = { Text(member.name) },
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
        }
    }
}