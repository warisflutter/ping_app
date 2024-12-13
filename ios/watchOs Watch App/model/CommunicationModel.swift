import Foundation

// User model
struct User: Codable, Identifiable {
    let id: String
    let name: String
    let isTeamLead: Bool
}

// Team Member model
struct TeamMember: Codable, Identifiable {
    let id: String
    let name: String
    let nextTicSec: String
    enum Status: String, Codable {
        case grey, green, red, black, transparent
    }
    var status: Status
}

// Message Template model
struct MessageTemplate: Codable, Identifiable {
    let id: String
    let message: String
}

// Ping model
struct Ping: Codable {
    let userId: String
}

// Text Message model
struct TextMessage: Codable {
    let userId: String
    let message: String
}

// Voice Note model
struct VoiceNote: Codable {
    let userId: String
    let audioData: Data
}

// Notification model
enum NotificationType: String, Codable {
    case ping, message, audiomessage
}

struct Notification: Codable, Identifiable, Equatable {
    let id: String
    let type: NotificationType
    let userName: String
    let content: String
    let data: String
    
    static func == (lhs: Notification, rhs: Notification) -> Bool {
        return lhs.id == rhs.id &&
               lhs.type == rhs.type &&
               lhs.userName == rhs.userName &&
               lhs.content == rhs.content &&
               lhs.data == rhs.data
    }
    
    var title: String {
            switch type {
            case .ping:
                return "Ping"
            case .message:
                return "Message"
            case .audiomessage:
                return "Audio"
            }
        }
}
// Ping Response model
struct PingResponse: Codable {
    let notificationId: String
    let response: Bool
}

// Auth Data model
struct AuthData: Codable {
    let userId: String
    let teamLeadId: String
}
