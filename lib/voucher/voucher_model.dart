import 'package:ping_app/auth/model/ping_user_model.dart';

class VoucherModel {
  final String voucherId;
  final String userId;
  final String createdAt;
  final String status;
  final PingUserModel pingUserModel;
  VoucherModel({
    required this.voucherId,
    required this.userId,
    required this.createdAt,
    required this.pingUserModel,
    required this.status,
  });
}
