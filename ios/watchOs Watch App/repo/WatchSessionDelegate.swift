import WatchConnectivity
import SwiftUI

class WatchSessionDelegate: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchSessionDelegate()
    
    @Published var authData: AuthData?
    @Published var teamMembers: [TeamMember] = []
    @Published var messageTemplates: [MessageTemplate] = []
    @Published var currentNotification: Notification?
    @Published var isLoading = false
    @Published var error: Error?
    private let chunkSize = 65000
    
    
    private var session: WCSession?
    private var pendingRequests: [() -> Void] = []
    private var waitTimer: Timer?
    
    private var reloadTimer: Timer?

    
    private override init() {
        super.init()
        setupSession()
    }
    
    // Updated reloadBasedOnNextTic method
    private func reloadBasedOnNextTic() {
        let smallestPositiveNextTic = teamMembers
            .compactMap { Int($0.nextTicSec) }  // Convert string to Int, filter out nil values
            .filter { $0 > 0 }
            .min()
        
        // Cancel any existing timer
        reloadTimer?.invalidate()
        
        // Only set up a new timer if there's a positive nextTicSec value
        if let nextTic = smallestPositiveNextTic {
            print("Asking for list again in \(nextTic)")
            reloadTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(nextTic), repeats: false) { [weak self] _ in
                self?.requestUserListFromiOSApp()
            }
        }
    }

    
    private func setupSession() {
        guard WCSession.isSupported() else {
            error = NSError(domain: "WatchConnectivity", code: 0, userInfo: [NSLocalizedDescriptionKey: "Watch Connectivity is not supported"])
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    // MARK: - Request Methods
    
    func requestAllData() {
        isLoading = true
        error = nil
        
        let requests = [
            requestAuthDataFromiOSApp,
            requestUserListFromiOSApp,
            requestMessageTemplatesFromiOSApp
        ]
        
        if isSessionReadyAndReachable() {
            requests.forEach { $0() }
        } else {
            pendingRequests.append(contentsOf: requests)
            checkAndExecutePendingRequests()
        }
    }
    
    func sendPingResponse(notificationId: String, response: Bool) {
        let message: [String: Any] = [
            "type": "pingResponse",
            "notificationId": notificationId,
            "response": response
        ]
        sendMessage(message)
    }
    
    private func requestAuthDataFromiOSApp() {
        sendMessage(["request": "authData"])
    }
    
    private func requestUserListFromiOSApp() {
        sendMessage(["request": "teamMembers"])
    }
    
    private func requestMessageTemplatesFromiOSApp() {
        sendMessage(["request": "messageTemplates"])
    }
    
    func sendPing(to userId: String) {
        let message: [String: Any] = ["type": "ping", "userId": userId]
        sendMessage(message)
    }
    
    func sendTextMessage(to userId: String, message: String) {
        let message: [String: Any] = ["type": "textMessage", "userId": userId, "message": message]
        sendMessage(message)
    }
    
    func sendAudio(to userId: String, audioData: Data) {
        let message: [String: Any] = [
            "type": "voiceNote",
            "userId": userId,
            "audioData": audioData
        ]
        sendMessage(message)
    }
    
    func sendAudioInChunks(to userId: String, audioData: Data) {
        let totalChunks = Int(ceil(Double(audioData.count) / Double(chunkSize)))
        
        for i in 0..<totalChunks {
            let start = i * chunkSize
            let end = min(start + chunkSize, audioData.count)
            let chunk = audioData.subdata(in: start..<end)
            
            let message: [String: Any] = [
                "type": "voiceNoteChunk",
                "userId": userId,
                "chunkIndex": i,
                "totalChunks": totalChunks,
                "audioData": chunk
            ]
            sendMessage(message)
        }
    }
    
    // MARK: - Message Handling
    
    private func sendMessage(_ message: [String: Any]) {
        guard let session = session, isSessionReadyAndReachable() else {
            pendingRequests.append({ [weak self] in
                self?.sendMessage(message)
            })
            checkAndExecutePendingRequests()
            return
        }
        
        session.sendMessage(message, replyHandler: nil) { [weak self] error in
            DispatchQueue.main.async {
                print("Error sending message: \(error.localizedDescription)")
                self?.error = error
                self?.isLoading = false
            }
        }
    }
    
    // MARK: - Pending Requests Handling
    
    private func checkAndExecutePendingRequests() {
        guard !pendingRequests.isEmpty else { return }
        
        if isSessionReadyAndReachable() {
            executePendingRequests()
        } else if waitTimer == nil {
            startWaitTimer()
        }
    }
    
    private func startWaitTimer() {
        waitTimer?.invalidate()
        waitTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.executePendingRequests()
        }
    }
    
    private func executePendingRequests() {
        waitTimer?.invalidate()
        waitTimer = nil
        
        for request in pendingRequests {
            request()
        }
        pendingRequests.removeAll()
    }
    
    private func isSessionReadyAndReachable() -> Bool {
        return session?.activationState == .activated && session?.isReachable == true
    }
    
    // MARK: - WCSessionDelegate Methods
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                print("Session activation failed with error: \(error.localizedDescription)")
                self?.error = error
            } else {
                print("Session activated with state: \(activationState.rawValue)")
                self?.checkAndExecutePendingRequests()
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            print("iOS app reachability changed. Is reachable: \(session.isReachable)")
            self?.checkAndExecutePendingRequests()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.handleReceivedMessage(message)
        }
    }
    
    // MARK: - Received Message Handling
    
    private func handleReceivedMessage(_ message: [String : Any]) {
        guard let dataType = message["type"] as? String else {
            print("Received message without a type")
            return
        }
        
        if dataType.hasSuffix("Error") {
            handleError(dataType: dataType, message: message["message"] as? String ?? "Unknown error")
        } else if let data = message["data"] {
            handleTypedData(dataType: dataType, data: data)
        } else {
            print("Received message with missing data for type: \(dataType)")
        }
        
        checkDataLoadingStatus()
    }
    
    private func handleError(dataType: String, message: String) {
        DispatchQueue.main.async {
            switch dataType {
            case "memberListError":
                self.error = NSError(domain: "MemberList", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                self.teamMembers = []  // Clear the team members list
            default:
                self.error = NSError(domain: "Unknown", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
            }
            self.isLoading = false
            print("Received error: \(dataType) - \(message)")
        }
    }
    
    private func handleTypedData(dataType: String, data: Any) {
        
        switch dataType {
        case "authData":
            if let authDict = data as? [String: String],
               let userId = authDict["userId"],
               let teamLeadId = authDict["teamLeadId"] {
                authData = AuthData(userId: userId, teamLeadId: teamLeadId)
                print("Received auth data for user: \(userId)")
            } else {
                print("Received incomplete auth data")
            }
            
        case "teamMembers":
            if let membersData = data as? [[String: Any]] {
                teamMembers = membersData.compactMap { memberDict in
                    guard let id = memberDict["id"] as? String,
                          let name = memberDict["name"] as? String,
                          let statusString = memberDict["status"] as? String,
                          let nextTicSec = memberDict["nextTicSec"] as? String,
                          let status = TeamMember.Status(rawValue: statusString) else {
                        return nil
                    }
                    return TeamMember(id: id, name: name,nextTicSec: nextTicSec, status: status)
                }
                print("Received \(teamMembers.count) team members")
                reloadBasedOnNextTic()
            } else {
                print("Received team members data in unexpected format")
            }
            
        case "messageTemplates":
            if let templates = data as? [[String: String]] {
                messageTemplates = templates.compactMap { template in
                    guard let id = template["id"], let message = template["message"] else { return nil }
                    return MessageTemplate(id: id, message: message)
                }
                print("Received \(messageTemplates.count) message templates")
            } else {
                print("Received message templates data in unexpected format")
            }
            
        case "notification":
            print("Session: Received Notification in Watch");
            if let notificationDict = data as? [String: Any],
               let id = notificationDict["id"] as? String,
               let typeString = notificationDict["type"] as? String,
               let userName = notificationDict["userName"] as? String,
               let content = notificationDict["content"] as? String,
               let data = notificationDict["data"] as? String,
               let type = NotificationType(rawValue: typeString.lowercased()) {
                let notification = Notification(
                    id: id,
                    type: type,
                    userName: userName,
                    content: content,
                    data: data
                )
                showNotification(notification)
            } else {
                print(data)
                print("Received incomplete notification data")
            }
            
        default:
            print("Received unknown data type: \(dataType)")
        }
        
    }
    
    private func checkDataLoadingStatus() {
        if (!teamMembers.isEmpty || error != nil) && !messageTemplates.isEmpty {
            isLoading = false
        }
    }
    
    private func showNotification(_ notification: Notification) {
        print("Showing Notification");
        currentNotification = notification
    }
    
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Implementation for iOS
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Implementation for iOS
    }
#endif
    
}
