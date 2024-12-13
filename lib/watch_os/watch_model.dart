class WatchOSAuthData {
  final String userId;
  final String teamLeadId;

  WatchOSAuthData({required this.userId, required this.teamLeadId});

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'teamLeadId': teamLeadId,
      };

  factory WatchOSAuthData.fromJson(Map<String, dynamic> json) =>
      WatchOSAuthData(
        userId: json['userId'],
        teamLeadId: json['teamLeadId'],
      );
}

// lib/models/watchos_team_member.dart
class WatchOSTeamMember {
  final String id;
  final String name;
  final String status;
  final String nextTicSec;

  WatchOSTeamMember({
    required this.id,
    required this.name,
    required this.status,
    required this.nextTicSec,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status,
        'nextTicSec': nextTicSec,
      };

  factory WatchOSTeamMember.fromJson(Map<String, dynamic> json) =>
      WatchOSTeamMember(
        id: json['id'],
        name: json['name'],
        status: json['status'],
        nextTicSec: json['nextTicSec'],
      );
}

// lib/models/watchos_message_template.dart
class WatchOSMessageTemplate {
  final String id;
  final String message;

  WatchOSMessageTemplate({required this.id, required this.message});

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
      };

  factory WatchOSMessageTemplate.fromJson(Map<String, dynamic> json) =>
      WatchOSMessageTemplate(
        id: json['id'],
        message: json['message'],
      );
}

// lib/models/watchos_notification.dart
enum WatchOSNotificationType { ping, message, audio }

class WatchOSNotification {
  final String id;
  final WatchOSNotificationType type;
  final String userName;
  final String? content;

  WatchOSNotification({
    required this.id,
    required this.type,
    required this.userName,
    this.content,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toString().split('.').last,
        'userName': userName,
        'content': content,
      };

  factory WatchOSNotification.fromJson(Map<String, dynamic> json) =>
      WatchOSNotification(
        id: json['id'],
        type: WatchOSNotificationType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type'],
        ),
        userName: json['userName'],
        content: json['content'],
      );
}
