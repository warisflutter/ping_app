import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ping_app/member/model/member_model.dart';

class PingUserModel {
  static const keyFullName = 'fullName';
  static const keyTeamName = 'teamName';
  static const keyIsDeleted = 'isDeleted';
  static const keyFcmToken = 'fcm';
  static const keyOnlineStatus = 'isOnline';
  static const keyLastSeen = 'lastSeen';
  static const keyInitials = 'initials';

  final String teamName;
  final String fullName;
  final String initials;
  final String email;
  final DateTime? _createdAt;
  final String? _userId;
  final List<FcmEntity> fcm;
  final bool isDeleted;
  final bool _isOnline;
  final DateTime lastSeen;
  final String type;
  final int dialogTimer;

  bool get isOnline => _isOnline && lastSeen.isAfter(DateTime.now().subtract(const Duration(minutes: 10)));

  PingUserModel({
    required this.teamName,
    required this.fullName,
    required this.email,
    required this.initials,
    required this.type,
  })  : _createdAt = DateTime.now(),
        _userId = null,
        _isOnline = false,
        lastSeen = DateTime(1800),
        fcm = [],
        isDeleted = false,
        dialogTimer = 5;

  DateTime get createdAt {
    if (_createdAt == null) {
      throw Exception('Attempt to access createdAt on local instance');
    }
    return _createdAt;
  }

  String get userId {
    if (_userId == null) {
      throw Exception('Attempt to access userId on local instance');
    }
    return _userId;
  }

  PingUserModel.fromJson(this._userId, Map<String, dynamic> json)
      : teamName = json[keyTeamName],
        fullName = json[keyFullName],
        fcm = (json[keyFcmToken] as List<dynamic>?)?.map((e) => FcmEntity.fromJson(e)).toList() ?? [],
        initials = json[keyInitials] ?? "",
        _isOnline = json[keyOnlineStatus] ?? false,
        lastSeen = (json['lastSeen'] as Timestamp?)?.toDate() ?? DateTime(1800),
        email = json['email'],
        isDeleted = json[keyIsDeleted] ?? false,
        type = json["type"],
        _createdAt = (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        dialogTimer = json['dialogTimer'] ?? 5
  ;

  Map<String, dynamic> toJson() {
    return {
      keyTeamName: teamName,
      keyFullName: fullName,
      'email': email,
      "type": type,
      keyInitials: initials,
      keyOnlineStatus: _isOnline,
      keyLastSeen: lastSeen,
      keyFcmToken: fcm,
      keyIsDeleted: isDeleted,
      'createdAt': _createdAt ?? FieldValue.serverTimestamp(),
      'dialogTimer': dialogTimer
    };
  }

  static PingUserModel empty() {
    return PingUserModel(
      type: "",
      initials: "",
      teamName: "",
      email: "",
      fullName: "",
    );
  }
}
