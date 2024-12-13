import SwiftUI

struct ContentView: View {
    @StateObject private var watchSessionDelegate = WatchSessionDelegate.shared

    // Define a 2-column grid layout
    let columns: [GridItem] = [
        GridItem(.flexible()), // First column
        GridItem(.flexible())  // Second column
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                if watchSessionDelegate.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if let error = watchSessionDelegate.error {
                    ErrorView(error: error, onReload: watchSessionDelegate.requestAllData)
                } else {
                    MemberListView(members: watchSessionDelegate.teamMembers)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            watchSessionDelegate.requestAllData()
        }
        .fullScreenCover(item: $watchSessionDelegate.currentNotification) { notification in
                    NotificationAlert(notification: notification, isPresented: Binding(
                        get: { watchSessionDelegate.currentNotification != nil },
                        set: { if !$0 { watchSessionDelegate.currentNotification = nil } }
                    ))
                }
    }
}

struct MemberListView: View {
    let members: [TeamMember]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(members) { member in
                    MemberListItem(member: member)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}


struct MemberListItem: View {
    let member: TeamMember
    
    var body: some View {
        NavigationLink(destination: ActionView(selectedMember: member)) {
            HStack {
                Text(member.name)
                    .lineLimit(1)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundColor(for: member.status))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func backgroundColor(for status: TeamMember.Status) -> Color {
           switch status {
           case .grey:
               return .gray
           case .green:
               return .green
           case .red:
               return .red
           case .black:
               return .black
           case .transparent:
               return .clear
           }
       }
}

struct ErrorView: View {
    let error: Error
    let onReload: () -> Void
    
    var body: some View {
        VStack {
            Text("Error: \(error.localizedDescription)")
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Reload", action: onReload)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
        }
    }
}
