import SwiftUI

struct ActionView: View {
    @StateObject private var watchSessionDelegate = WatchSessionDelegate.shared
    @Environment(\.presentationMode) var presentationMode
    let selectedMember: TeamMember
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    NavigationLink(destination: MessageTemplatesView(selectedMember: selectedMember)) {
                        VStack {
                            Image(systemName: "message.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: AudioRecordingView(selectedMember: selectedMember)) {
                        VStack {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(height: geometry.size.height / 2)
                
                Button(action: {
                    watchSessionDelegate.sendPing(to: selectedMember.id)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    VStack {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .frame(height: geometry.size.height / 2)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
