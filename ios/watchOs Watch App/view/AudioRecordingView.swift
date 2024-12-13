import SwiftUI
import AVFoundation

struct AudioRecordingView: View {
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var watchSessionDelegate = WatchSessionDelegate.shared
    let selectedMember: TeamMember
    
    var body: some View {
        VStack {
            if isRecording {
                Text("Recording...")
                    .font(.headline)
                Button(action: stopRecording) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                }
            } else {
                Button(action: startRecording) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                }
            }
        }
        .onDisappear {
            if isRecording {
                stopRecording()
            }
        }
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording.wav")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            
            isRecording = true
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        
        if let audioFileURL = audioRecorder?.url {
            do {
                let audioData = try Data(contentsOf: audioFileURL)
                watchSessionDelegate.sendAudioInChunks(to: selectedMember.id, audioData: audioData)
            } catch {
                print("Failed to read audio file: \(error)")
            }
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}
