import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';

// class VoucherModel {
//   final String voucherId;
//   final String userId;
//   final String createdAt;
//   final String status;
//   final String type;
//   final String code;
//   final bool isUsed;
//   final PingUserModel pingUserModel;
//   VoucherModel({
//     this.code = "",
//     this.isUsed = false,
//     required this.type,
//     required this.voucherId,
//     required this.userId,
//     required this.createdAt,
//     required this.pingUserModel,
//     required this.status,
//   });
// }

class VoucherModel {
  final String voucherId;
  final String code;
  final Timestamp createdAt;
  final String createdBy;
  final String? description;
  final Timestamp? expiresAt;
  final bool isUsed;
  final String status;
  final Timestamp? usedAt;
  final String? usedBy;
  final int value;

  VoucherModel(
      {this.voucherId = '',
      required this.code,
      required this.createdAt,
      required this.createdBy,
      this.description,
      this.expiresAt,
      this.isUsed = false,
      this.status = 'active',
      this.usedAt,
      this.usedBy,
      this.value = 0});

  factory VoucherModel.fromJson(Map<String, dynamic> json) => VoucherModel(
      voucherId: json['voucherId'],
      code: json['code'],
      createdAt: json['createdAt'],
      createdBy: json['createdBy'],
      description: json['description'] ?? '',
      expiresAt: json['expiresAt'],
      isUsed: json['isUsed'] ?? false,
      status: json['status'] ?? VoucherStatus.active.name,
      usedAt: json['usedAt'],
      usedBy: json['usedBy'],
      value: json['value'] ?? 0);

  Map<String, dynamic> toJson() => {
        'code': code,
        'createdAt': createdAt,
        'createdBy': createdBy,
        'description': description,
        'expiresAt': expiresAt,
        'isUsed': isUsed,
        'status': status,
        'usedAt': usedAt,
        'usedBy': usedBy,
        'value': value
      };
}

enum VoucherStatus { active, used, expired, disabled }
