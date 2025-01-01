import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:ping_app/notification/repo/notification_repo.dart';
import 'package:ping_app/member/repo/member_repo.dart';
import 'package:ping_app/notification/model/ping_notification_model.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';
import 'package:ping_app/member/model/member_model.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ActivityReportGenerator {
  final AuthRepo _authRepo = AuthRepo.instance;
  final NotificationRepo _notificationRepo = NotificationRepo.instance;
  final MemberRepo _memberRepo = MemberRepo.instance;

  // Add a stream controller for updates
  final _updateController = StreamController<String>.broadcast();

  Stream<String> get updates => _updateController.stream;

  Future<void> generateAndShareActivityReport(String teamLeadId) async {
    try {
      _updateController.add('t_startingReportGeneration'.tr());
      String filePath = await _generateActivityReport(teamLeadId);
      _updateController.add('t_reportGeneratedToShare'.tr());
      final file = XFile(filePath);
      await Share.shareXFiles([file], text: 't_activityReport'.tr());
      _updateController.add('t_reportSharedSuccessfully'.tr());
    } catch (e) {
      _updateController.add('Error: $e');
      print('${'t_errorGeneratingActivityReport'.tr()}: $e');
      rethrow;
    } finally {
      _updateController.close();
    }
  }

  Future<String> _generateActivityReport(String teamLeadId) async {
    PingUserModel? teamLead = await _authRepo.getUserById(teamLeadId);
    if (teamLead == null) {
      throw Exception('t_teamLeadNotFound'.tr());
    }

    _updateController.add('t_fetchingTeamMembers'.tr());
    List<MemberModel> members = await _memberRepo
        .getMembers(ofTeamLead: teamLead, ifMemberId: null)
        .first;
    members.insert(0, MemberModel.fromPingUserModel(teamLead));

    Map<String, dynamic> userMap = {teamLeadId: teamLead};
    for (var member in members) {
      userMap[member.id] = member;
    }

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['t_activityReport'.tr()];

    _addHeadersToSheet(sheetObject);

    _updateController.add('t_processingMemberData'.tr());
    await _processNotificationsForAllUsers(
        [teamLead, ...members], userMap, sheetObject);

    _updateController.add('t_savingReport'.tr());
    String filePath = await _saveExcelFile(excel);
    return filePath;
  }

  void _addHeadersToSheet(Sheet sheetObject) {
    sheetObject.appendRow([
      TextCellValue('Date'),
      TextCellValue('Time'),
      TextCellValue('From User'),
      TextCellValue('To User'),
      TextCellValue('Activity Type'),
      TextCellValue('Message'),
      TextCellValue('Data'),
      TextCellValue('Delivered'),
      TextCellValue('Response')
    ]);
  }

  Future<void> _processNotificationsForAllUsers(List<dynamic> users,
      Map<String, dynamic> userMap, Sheet sheetObject) async {
    int index = 1;
    for (var user in users) {
      _updateController
          .add('${index++}/${users.length} ${'t_processingData'.tr()}');
      String userId = user is PingUserModel ? user.userId : user.id;
      List<PingNotificationModel> notifications =
          await _notificationRepo.getNotifications(userId).first;
      notifications
          .addAll(await _notificationRepo.getNotificationsFromMe(userId).first);

      for (var notification in notifications) {
        final fromUser = await _getUserInfo(notification.fromId, userMap);
        final toUser = await _getUserInfo(notification.toId, userMap);

        sheetObject.appendRow([
          TextCellValue(
              notification.sentAt?.toLocal().toString().split(' ')[0] ?? 'N/A'),
          TextCellValue(
              notification.sentAt?.toLocal().toString().split(' ')[1] ?? 'N/A'),
          TextCellValue(fromUser.name),
          TextCellValue(toUser.name),
          TextCellValue(notification.type.title),
          TextCellValue(notification.message),
          TextCellValue(notification.type == NotificationType.audioMessage
              ? _getAudioDuration(notification.data)
              : notification.type == NotificationType.message
                  ? notification.data ?? "Null"
                  : 'N/A'),
          TextCellValue(notification.isDelivered ? 't_yes'.tr() : 't_no'.tr()),
          TextCellValue(
            notification.response == null
                ? notification.type == NotificationType.ping
                    ? 't_noResponse'.tr()
                    : "N/A"
                : (notification.response! ? 't_coming'.tr() : 't_notComing'.tr()),
          )
        ]);
      }
    }
  }

  Future<_UserInfo> _getUserInfo(
      String userId, Map<String, dynamic> userMap) async {
    // First, try to get the user from the map
    final user = userMap[userId];
    if (user != null) {
      if (user is PingUserModel) {
        return _UserInfo(user.fullName, true);
      }
      if (user is MemberModel) {
        return _UserInfo(user.name, false);
      }
    }

    // If not found in the map, search in the database
    final pingUser = await _authRepo.getUserById(userId);
    if (pingUser != null) {
      // Add to the map for future use
      userMap[userId] = pingUser;
      return _UserInfo(pingUser.fullName, true);
    }

    final member = await _memberRepo.getNullableMemberById(userId);
    if (member != null) {
      // Add to the map for future use
      userMap[userId] = member;
      return _UserInfo(member.name, false);
    }

    // If still not found, return unknown
    return _UserInfo('t_unknown'.tr(), false);
  }

  String _getAudioDuration(String? audioUrl) {
    return audioUrl ?? 't_unknown'.tr();
  }

  Future<String> _saveExcelFile(Excel excel) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    String fileName =
        'activity_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    File excelFile = File('$appDocPath/$fileName');
    await excelFile.writeAsBytes(excel.encode()!);
    return excelFile.path;
  }
}

class _UserInfo {
  final String name;
  final bool isTeamLead;

  _UserInfo(this.name, this.isTeamLead);
}
