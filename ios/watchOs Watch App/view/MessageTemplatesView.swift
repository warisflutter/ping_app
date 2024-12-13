import SwiftUI

struct MessageTemplatesView: View {
    @StateObject private var watchSessionDelegate = WatchSessionDelegate.shared
    let selectedMember: TeamMember
    @Environment(\.presentationMode) var presentationMode
    @State private var showingConfirmation = false
    @State private var sentMessage = ""

    var body: some View {
        List(watchSessionDelegate.messageTemplates) { template in
            Button(action: {
                sendMessage(template.message)
            }) {
                Text(template.message)
            }
        }
        .navigationTitle("Templates")
        .alert("Message Sent", isPresented: $showingConfirmation) {
            Button("OK") {
                showingConfirmation = false
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your message: \"\(sentMessage)\" has been sent.")
        }
    }

    private func sendMessage(_ message: String) {
        watchSessionDelegate.sendTextMessage(to: selectedMember.id, message: message)
        sentMessage = message
        showingConfirmation = true
    }
}
