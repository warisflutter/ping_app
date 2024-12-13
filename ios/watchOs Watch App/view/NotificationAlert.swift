//
//  NotificationAlert.swift
//  watchOs Watch App
//
//  Created by Kamran Bashir on 04/08/2024.
//

import SwiftUI
import AVFoundation


struct NotificationAlert: View {    let notification: Notification
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(notification.title)
                    .font(.title)
                    .multilineTextAlignment(.leading)
                Text(notification.content)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                switch notification.type {
                case .ping:
                    HStack(spacing: 32) {
                        CircularButton(
                            icon: "checkmark",
                            color: .green,
                            action: {
                                respondToNotification(id: notification.id, response: true)
                                isPresented = false
                            }
                        )
                        
                        CircularButton(
                            icon: "xmark",
                            color: .red,
                            action: {
                                
                                respondToNotification(id: notification.id, response: false)
                                isPresented = false
                            }
                        )
                    }
                    
                case .message:
                    Text(notification.data)
                        .font(.body)
                        .multilineTextAlignment(.center)
                    
                    
                case .audiomessage:
                    if let url = URL(string: notification.data) {
                        AudioPlayerView(url: url)
                    } else {
                        Text("Audio URL not available")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.9))
            .foregroundColor(.white)
            //            .navigationBarItems(leading: Button("Back") {
            //                isPresented = false
            //            })
            //            .navigationBarTitle("Notification", displayMode: .inline)
        }
    }
    
    private func respondToNotification(id: String, response: Bool) {
        WatchSessionDelegate.shared.sendPingResponse(notificationId: id, response: response)
    }
}

struct CircularButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.6))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AudioPlayerView: View {
    let url: URL
    @State private var isPlaying = false
    @State private var audioPlayer: AVPlayer?
    
    var body: some View {
        VStack {
            Button(action: {
                if isPlaying {
                    audioPlayer?.pause()
                } else {
                    if audioPlayer == nil {
                        audioPlayer = AVPlayer(url: url)
                    }
                    audioPlayer?.play()
                }
                isPlaying.toggle()
            }) {
                Image(systemName: isPlaying ? "pause.circle" : "play.circle")
                    .font(.system(size: 44))
            }
        }
        .onDisappear {
            audioPlayer?.pause()
            audioPlayer = nil
        }
    }
}
