import android.util.Log
import com.team.pingapp.ping_app.MemberActionViewModel

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.wear.compose.material.*
import androidx.navigation.NavHostController
import androidx.lifecycle.viewmodel.compose.viewModel
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.Wearable
import com.team.pingapp.ping_app.MessageTemplatesViewModel
import com.team.pingapp.ping_app.WearViewModelFactory

@Composable
fun MessageTemplatesScreen(
    navController: NavHostController,
    memberId: String?
) {
    val viewModel: MessageTemplatesViewModel = viewModel(
        factory = WearViewModelFactory(LocalContext.current)
    )

    val templates by viewModel.messageTemplates.collectAsState()

    ScalingLazyColumn {
        items(templates) { template ->
            Chip(
                onClick = {
                    Log.d("MessageTemplatesViewModel", "Sending message to member: $memberId")
                    memberId?.let { id ->
                        viewModel.sendMessage(id, template)
                    }
                    navController.popBackStack()
                },
                label = { Text(template) },
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}
