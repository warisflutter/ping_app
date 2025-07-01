import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';

extension ColorSerialization on Color {
  /// Converts the color to a JSON-friendly string representation.
  String toJson() => '#${value.toRadixString(16).padLeft(8, '0')}';

  /// Creates a Color from a JSON string representation.
  static Color fromJson(String json) {
    if (json.startsWith('#')) {
      json = json.substring(1);
    }
    return Color(int.parse(json, radix: 16));
  }
}

class MemberModel {
  static const keyFcm = "fcm";
  static const keyIsBlocked = "isBlocked";
  static const keyTeamLeadId = "teamLeadId";
  static const keyMemberOnline = "isOnline";
  static const keyLastSeen = 'lastSeen';
  static const keyMemberName = "name";

  final String _id;
  final String teamLeadId;
  final String name;
  final String initials;
  final List<FcmEntity> fcm;
  final bool isBlocked;
  final bool _isOnline;
  final DateTime lastSeen;
  final Color? memberColor;

  MemberModel({
    required this.name,
    required this.initials,
    required this.teamLeadId,
    this.memberColor,
  })  : fcm = [],
        _id = "",
        _isOnline = false,
        lastSeen = DateTime(1800),
        isBlocked = false;

  MemberModel copyWith({
    String? initials,
    String? name,
    Color? memberColor,
  }) {
    return MemberModel._internal(
      name: name ?? this.name,
      initials: initials ?? this.initials,
      memberColor: memberColor ?? this.memberColor,
      teamLeadId: teamLeadId,
      fcm: fcm,
      id: _id,
      isOnline: _isOnline,
      lastSeen: lastSeen,
      isBlocked: isBlocked,
    );
  }

// Add this named constructor to your MemberModel class
  MemberModel._internal({
    required String id,
    required this.name,
    required this.initials,
    required this.teamLeadId,
    this.memberColor,
    required this.fcm,
    required bool isOnline,
    required this.lastSeen,
    required this.isBlocked,
  })  : _id = id,
        _isOnline = isOnline;

  bool get isOnline => _isOnline;
  // && lastSeen.isAfter(DateTime.now().subtract(const Duration(minutes: 10)));

  bool get isTeamLead => _id == teamLeadId;

  MemberModel.fromPingUserModel(PingUserModel user)
      : _id = user.userId,
        teamLeadId = user.userId,
        _isOnline = user.isOnline,
        initials = user.initials,
        lastSeen = user.lastSeen,
        memberColor = null,
        name = user.fullName,
        fcm = user.fcm,
        isBlocked = false;

  String get id {
    if (_id.isEmpty) {
      throw Exception('t_tryingToIsSet'.tr());
    }
    return _id;
  }

  MemberModel.fromJson(this._id, Map<String, dynamic> json)
      : name = json[keyMemberName],
        teamLeadId = json['teamLeadId'],
        initials = json['initials'] ?? "",
        memberColor = json['color'] == null ? null : ColorSerialization.fromJson(json['color']),
        _isOnline = json[keyMemberOnline] ?? false,
        lastSeen = (json[keyLastSeen] as Timestamp?)?.toDate() ?? DateTime(1800),
        isBlocked = json[keyIsBlocked],
        fcm = (json[keyFcm] as List<dynamic>?)?.map((e) => FcmEntity.fromJson(e)).toList() ?? [];

  Map<String, dynamic> toJson() => {
        keyMemberName: name,
        keyFcm: fcm,
        'initials': initials,
        keyMemberOnline: _isOnline,
        keyLastSeen: lastSeen,
        'color': memberColor?.toJson(),
        "teamLeadId": teamLeadId,
        keyIsBlocked: isBlocked,
      };
  @override
  String toString() {
    return 'MemberModel{id: $_id,'
        ' name: $name, initials: $initials, teamLeadId: $teamLeadId,'
        ' fcm: $fcm, isBlocked: $isBlocked, isOnline: $_isOnline, lastSeen: $lastSeen, '
        'memberColor: ${memberColor?.toString() ?? "null"}}';
  }
}

class FcmEntity{
  String token;
  String device;
  FcmEntity({required this.token, required this.device});

  factory FcmEntity.fromJson(Map<String, dynamic> json) => FcmEntity(token: json['token'], device: json['device']);

  Map<String, dynamic> toJson() => {
    'token': token,
    'device': device
  };



}