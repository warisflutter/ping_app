import UIKit
import Flutter
import WatchConnectivity
import flutter_background_service_ios
import FirebaseFirestore
import FirebaseAuth

@main
@objc class AppDelegate: FlutterAppDelegate, WCSessionDelegate {
    
    private var flutterChannel: FlutterMethodChannel?
    private var audioChunks: [Int: Data] = [:]
    private var totalChunksExpected: Int = 0
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        setupFlutterChannel()
        activateWatchSession()
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func applicationWillTerminate(_ application: UIApplication) {
        print("App is terminated")
        updateTerminationStatus(isOnline: false)

    }

    func updateTerminationStatus(isOnline: Bool) {
        print(isOnline)
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User mnot found")
            return
        }
        print(userId)
        let usersRef = Firestore.firestore().collection("users").document(userId)
        print(usersRef)
        usersRef.updateData([
            "isOnline": isOnline,
            "lastActive": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error updating termination status: \(error.localizedDescription)")
            } else {
                print("Termination status updated successfully")
            }
        }
    }
    
    //--------------------Platform Channel--------------------//
    let CHANNEL = "com.martin.pingApp/test"
    
    func setupFlutterChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            fatalError("rootViewController is not type FlutterViewController")
        }
        flutterChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)
        
        flutterChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            print("Session: Received \(call.method)")
            switch call.method {
            case "reflector":
                if let args = call.arguments as? [String: Any], let message = args["message"] as? String {
                    print("Flutter Says: \(message)")
                    result("Hey yourself")
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected a message", details: nil))
                }
            case "memberList":
                if let args = call.arguments as? [String: Any] {
                    if let members = args["members"] as? [[String: String]] {
                        self?.sendNamesToWatch(names: members)
                        result("Received \(members.count) members")
                    } else if let errorMessage = args["error"] as? String {
                        self?.sendErrorToWatch(errorType: "memberListError", message: errorMessage)
                        result("Error fetching members: \(errorMessage)")
                    } else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected a list of members or an error message", details: nil))
                    }
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected arguments", details: nil))
                }
            case "sendAuthData":
                if let args = call.arguments as? [String: Any],
                   let userId = args["userId"] as? String,
                   let teamLeadId = args["teamLeadId"] as? String {
                    self?.sendAuthDataToWatch(userId: userId, teamLeadId: teamLeadId)
                    result("Auth data sent to watch")
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected userId and teamLeadId", details: nil))
                }
            case "sendMessageTemplates":
                if let args = call.arguments as? [String: Any],
                   let templates = args["templates"] as? [[String: String]] {
                    self?.sendMessageTemplatesToWatch(templates: templates)
                    result("Message templates sent to watch")
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected an array of message templates", details: nil))
                }
            case "sendNotificationToNative":
                print("Session: Received Notification")
                if let args = call.arguments as? [String: Any] {
                    self?.sendNotificationToWatch(notificationData: args)
                    result("Notification data sent to watch")
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid notification data", details: nil))
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    //--------------------Watch Connectivity--------------------//
    
    func activateWatchSession() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("Session: Watch Connectivity is supported and session activated.")
        } else {
            print("Session: Watch Connectivity is not supported.")
        }
    }
    
    func sendNotificationToWatch(notificationData: [String: Any]) {
        print(notificationData);
        if WCSession.default.isReachable {
            print("Session: Sending Notification To Watch");
            
            let message: [String: Any] = ["type": "notification", "data": notificationData]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Session: Error sending notification to watch: \(error.localizedDescription)")
            }
        } else {
            print("Session: Watch is not reachable")
        }
    }
    
    func sendNamesToWatch(names: [[String: String]]) {
        if WCSession.default.isReachable {
            let message: [String: Any] = ["type": "teamMembers", "data": names]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending message: \(error.localizedDescription)")
            }
        } else {
            print("Session: Watch is not reachable")
        }
    }
    
    func sendAuthDataToWatch(userId: String, teamLeadId: String) {
        if WCSession.default.isReachable {
            let authData = ["userId": userId, "teamLeadId": teamLeadId]
            let message: [String: Any] =  ["type": "authData", "data": authData]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending auth data: \(error.localizedDescription)")
            }
        } else {
            print("Session: Watch is not reachable")
        }
    }
    
    func sendMessageTemplatesToWatch(templates: [[String: String]]) {
        if WCSession.default.isReachable {
            let message: [String: Any] = ["type": "messageTemplates", "data": templates]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending message templates: \(error.localizedDescription)")
            }
        } else {
            print("Session: Watch is not reachable")
        }
    }
    
    func sendErrorToWatch(errorType: String, message: String) {
        if WCSession.default.isReachable {
            let errorMessage: [String: Any] = ["type": errorType, "message": message]
            WCSession.default.sendMessage(errorMessage, replyHandler: nil) { error in
                print("Error sending error message to watch: \(error.localizedDescription)")
            }
        } else {
            print("Session: Watch is not reachable")
        }
    }
    
    func handleAudioChunk(userId: String, chunkIndex: Int, totalChunks: Int, audioChunk: Data) {
        audioChunks[chunkIndex] = audioChunk
        totalChunksExpected = totalChunks
        
        if audioChunks.count == totalChunksExpected {
            let sortedChunks = audioChunks.sorted { $0.key < $1.key }
            let completeAudioData = Data(sortedChunks.flatMap { $0.value })
            
            flutterChannel?.invokeMethod("receiveVoiceNote", arguments: [
                "userId": userId,
                "audioData": FlutterStandardTypedData(bytes: completeAudioData)
            ])
            
            // Clear the stored chunks
            audioChunks.removeAll()
            totalChunksExpected = 0
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Session: message received from watch \(message)")
        if let request = message["request"] as? String {
            switch request {
            case "authData":
                flutterChannel?.invokeMethod("requestAuthData", arguments: nil)
            case "teamMembers":
                flutterChannel?.invokeMethod("requestTeamMembers", arguments: nil)
            case "messageTemplates":
                flutterChannel?.invokeMethod("requestMessageTemplates", arguments: nil)
            default:
                print("Unknown request from watch: \(request)")
            }
        } else if let type = message["type"] as? String {
            switch type {
            case "ping":
                if let userId = message["userId"] as? String {
                    flutterChannel?.invokeMethod("receivePing", arguments: ["userId": userId])
                }
            case "textMessage":
                if let userId = message["userId"] as? String, let messageText = message["message"] as? String {
                    flutterChannel?.invokeMethod("receiveTextMessage", arguments: ["userId": userId, "message": messageText])
                }
            case "voiceNote":
                if let userId = message["userId"] as? String,
                   let audioData = message["audioData"] as? Data {
                    flutterChannel?.invokeMethod("receiveVoiceNote", arguments: [
                        "userId": userId,
                        "audioData": FlutterStandardTypedData(bytes: audioData)
                    ])
                }
            case "voiceNoteChunk":
                if let userId = message["userId"] as? String,
                   let chunkIndex = message["chunkIndex"] as? Int,
                   let totalChunks = message["totalChunks"] as? Int,
                   let audioChunk = message["audioData"] as? Data {
                    handleAudioChunk(userId: userId, chunkIndex: chunkIndex, totalChunks: totalChunks, audioChunk: audioChunk)
                }
            case "pingResponse":
                    if let notificationId = message["notificationId"] as? String,
                       let response = message["response"] as? Bool {
                        flutterChannel?.invokeMethod("receivePingResponse", arguments: [
                            "notificationId": notificationId,
                            "response": response
                        ])
                    }
            default:
                print("Unknown message type from watch: \(type)")
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Session: Activation Error \(error.localizedDescription)")
        } else {
            print("Session: Activated with state \(activationState.rawValue)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session: Inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Session: Deactivate")
        WCSession.default.activate()
    }
}


