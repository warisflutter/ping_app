import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.wear.compose.material.*
import androidx.navigation.NavHostController
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.compose.ui.platform.LocalContext
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import android.Manifest
import com.team.pingapp.ping_app.AudioRecordingViewModel
import com.team.pingapp.ping_app.WearViewModelFactory

@Composable
fun AudioRecordingScreen(
    navController: NavHostController,
    memberId: String?
) {
    val context = LocalContext.current
    val viewModel: AudioRecordingViewModel = viewModel(
        factory = remember { WearViewModelFactory(context) }
    )
    val isRecording by viewModel.isRecording.collectAsState()
    val permissionGranted by viewModel.permissionGranted.collectAsState()

    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted: Boolean ->
        if (isGranted) {
            viewModel.checkPermission()
        }
    }

    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center
    ) {
        if (!permissionGranted) {
            Button(
                onClick = { permissionLauncher.launch(Manifest.permission.RECORD_AUDIO) },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Request Mic Permission")
            }
        } else {
            Button(
                onClick = {
                    if (isRecording) {
                        viewModel.stopRecording()
                        memberId?.let { viewModel.sendAudio(it) }
//                        navController.popBackStack()
                    } else {
                        viewModel.startRecording()
                    }
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(if (isRecording) "Stop & Send" else "Start Recording")
            }
        }
    }
}