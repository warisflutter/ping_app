import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ping_app/member/model/member_model.dart';
import 'package:ping_app/member/repo/member_state.dart';
import 'package:ping_app/notification/model/ping_notification_model.dart';
import 'package:ping_app/notification/repo/notification_repo.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:ping_app/view/settings/repo/setting_repo.dart';
import 'package:ping_app/watch_os/watch_model.dart';
import 'package:ping_app/member/repo/member_repo.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WatchConnectivity {
  static final instance = WatchConnectivity._();

  final debugKey = "FlutterWatchConnectivity:";
  final platform = const MethodChannel('com.martin.pingApp/test');

  String meId = "all";
  String teamLeadId = "all";

  StreamSubscription? _notificationSubscription;

  WatchConnectivity._() {
    _setupListeners();
    _setupMessageTemplateListener();
  }

  void _setupListeners() {
    try {
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user == null) {
          meId = "all";
          teamLeadId = "all";
        } else {
          meId = user.uid;
          teamLeadId = user.uid;
          sendMemberListToWatch();
          debugPrint("TeamLead: cancelling ${user.uid}");
          if (_notificationSubscription != null) {
            await _notificationSubscription!.cancel();
          }
          debugPrint("TeamLead: Team lead sending members");
          _notificationSubscription = NotificationRepo.instance.getNotificationsFromMe(user.uid).listen((notification) {
            debugPrint("TeamLead: Sent");
            sendMemberListToWatch();
          });
        }
      });

      // Listen for member state changes
      MemberState.instance.addListener(() {
        sendMemberListToWatch();
      });

      MemberState.instance.onMemberChanged = (MemberModel? member) async {
        if (member != null) {
          meId = member.id;
          teamLeadId = member.teamLeadId;
        }
        debugPrint("TeamLead: 1 cancelling");
        if (_notificationSubscription != null) {
          await _notificationSubscription!.cancel();
        }
        debugPrint("TeamLead: 1Member sending members");
        _notificationSubscription = NotificationRepo.instance.getNotificationsFromMe(meId).listen((notification) {
          debugPrint("TeamLead: 1 Sent");
          sendMemberListToWatch();
        });
      };

      // Listen for member changes (add/delete/block)
      MemberRepo.instance.memberChanges.listen((_) {
        sendMemberListToWatch();
      });

    } catch (e) {
      //
    }

  }

  void _setupMessageTemplateListener() {
    SettingRepo.instance.getMessages(teamLeadId).listen((messages) {
      _handleRequestMessageTemplates();
    });
  }

  void setupMethodChannel() {
    debugPrint("$debugKey Setting up method channel");
    try {
      platform.setMethodCallHandler((call) async {
        debugPrint("$debugKey Received something");
        PingLog.pingLog("--- call method: ${call.method} ---");
        switch (call.method) {
          case 'requestAuthData':
            await _handleRequestAuthData();
            break;
          case 'requestTeamMembers':
            await sendMemberListToWatch();
            break;
          case 'requestMessageTemplates':
            await _handleRequestMessageTemplates();
            break;
          case 'receivePing':
            await _handleReceivedPing(call.arguments['userId']);
            break;
          case 'receiveTextMessage':
            _handleReceivedTextMessage(call.arguments['userId'], call.arguments['message']);
            break;
          case 'receiveVoiceNote':
            _handleReceivedVoiceNote(call.arguments['userId'], call.arguments['audioData']);
            break;
          case 'receivePingResponse':
            _handleReceivedPingResponse(call.arguments['notificationId'], call.arguments['response']);
            break;
        }
      });
    } catch (e, s) {
      PingLog.pingLog("error in the setupMethodChannel: $e $s");
    }
  }

  Future<void> _handleRequestAuthData() async {
    WatchOSAuthData authData = await _fetchAuthData();
    await platform.invokeMethod('sendAuthData', authData.toJson());
  }

  Future<void> sendMemberListToWatch() async {
    try {
      List<WatchOSTeamMember> members = await _fetchTeamMembers();
      await platform.invokeMethod('memberList', {'members': members.map((m) => m.toJson()).toList()});
      debugPrint("$debugKey Sent Members");
    } catch (e) {
      debugPrint('$debugKey Error fetching team members: $e');
      await platform.invokeMethod('memberList', {'error': e.toString()});
    }
  }

  Future<void> _handleRequestMessageTemplates() async {
    try {
      List<WatchOSMessageTemplate> templates = await _fetchMessageTemplates();
      if (templates.isNotEmpty) {
        await platform.invokeMethod('sendMessageTemplates', {'templates': templates.map((t) => t.toJson()).toList()});
      }
    } catch (e) {
      PingLog.pingLog('_handleRequestMessageTemplates failed: $e');
    }
  }

  Future<void> _handleReceivedPing(String userId) async {
    debugPrint('$debugKey Received ping from user: $userId $meId');
    try {
      await NotificationRepo.instance.sendWatchNotification(
        fromId: meId,
        toId: userId,
        title: 't_ping'.tr(),
        type: NotificationType.ping,
      );
    } catch (e) {
      debugPrint("$debugKey Error $e");
    }
    sendMemberListToWatch();
    // Implement your ping handling logic here
  }

  void _handleReceivedTextMessage(String userId, String message) async {
    debugPrint('$debugKey Received text message from user: $userId, message: $message');
    await NotificationRepo.instance.sendWatchNotification(
      fromId: meId,
      toId: userId,
      title: message,
      type: NotificationType.message,
      data: message,
    );
    // Implement your text message handling logic here
    // For example, you could update the UI or store the message in your app's state
  }

  void _handleReceivedVoiceNote(String userId, Uint8List audioData) async {
    debugPrint(
      '$debugKey Received voice note from user: $userId, audio data length: ${audioData.length}',
    );
    final url = await NotificationRepo.instance.uploadDataAndGetUrl(userId, audioData);
    await NotificationRepo.instance.sendWatchNotification(
      fromId: meId,
      toId: userId,
      title: 't_youHaveAudioMessage'.tr(),
      type: NotificationType.audioMessage,
      data: url,
    );
    // Implement your voice note handling logic here
  }

  void _handleReceivedPingResponse(String notificationId, bool response) {
    debugPrint('$debugKey Received ping response for notification: $notificationId, response: $response');
    NotificationRepo.instance.respondToNotification(notificationId, response);
  }

  // These methods would be implemented to fetch data from your app's state or storage
  Future<WatchOSAuthData> _fetchAuthData() async {
    // Return dummy auth data
    return WatchOSAuthData(
      userId: 'user123',
      teamLeadId: 'lead456',
    );
  }

  Future<List<WatchOSTeamMember>> _fetchTeamMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getString("memberId");

    if (memberId != null) {
      // Member login
      final memberModel = await MemberRepo.instance.getMemberById("rytjcqtfVWYZEml72U18");
      final teamLead = await AuthRepo.instance.getUserById(memberModel.teamLeadId);

      if (teamLead == null) {
        throw Exception('t_teamLeadNotFound'.tr());
      }

      final membersStream = MemberRepo.instance.getMembers(
        ofTeamLead: teamLead,
        ifMemberId: memberId,
      );

      final members = await membersStream.first;

      // Create a list with the team lead first, then the other members
      final recentTeamLeadNotification =
          await NotificationRepo.instance.getMostRecentNotification(teamLead.userId).first;
      List<WatchOSTeamMember> watchMembers = [
        WatchOSTeamMember(
          id: teamLead.userId,
          name: teamLead.fullName,
          status: _getColorStatus(teamLead.userId, recentTeamLeadNotification),
          nextTicSec: (recentTeamLeadNotification?.nextTick()?.inSeconds ?? -1).toString(),
        )
      ];

      for (var member in members.where((member) => !member.isBlocked)) {
        final notification = await NotificationRepo.instance.getMostRecentNotification(member.id).first;
        watchMembers.add(WatchOSTeamMember(
          id: member.id,
          name: member.name,
          status: _getColorStatus(member.id, notification),
          nextTicSec: (notification?.nextTick()?.inSeconds ?? -1).toString(),
        ));
      }

      return watchMembers;
    } else {
      // Team lead login
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('t_noUserLoggedIn'.tr());
      }

      final currentUser = await AuthRepo.instance.getUserById(currentUserId);
      if (currentUser == null) {
        throw Exception('t_currentUserNotFound'.tr());
      }

      final membersStream = MemberRepo.instance.getMembers(
        ofTeamLead: currentUser,
        ifMemberId: null,
      );

      final members = await membersStream.first;

      List<WatchOSTeamMember> watchMembers = [];
      for (var member in members.where((member) => !member.isBlocked)) {
        final notification = await NotificationRepo.instance.getMostRecentNotification(member.id).first;
        watchMembers.add(WatchOSTeamMember(
          id: member.id,
          name: member.name,
          status: _getColorStatus(member.id, notification),
          nextTicSec: (notification?.nextTick()?.inSeconds ?? -1).toString(),
        ));
      }

      return watchMembers;
    }
  }

  String _getColorStatus(String memberId, PingNotificationModel? notification) {
    if (notification == null) {
      return "transparent";
    }
    if (notification.type != NotificationType.ping || notification.is30SecAgo) {
      return 'transparent';
    }

    final expiryTime = (notification.sentAt ?? DateTime.now()).add(PingNotificationModel.durationExpire);
    if (expiryTime.isAfter(DateTime.now())) {
      if (notification.response != null) {
        return notification.response! ? 'green' : 'red';
      } else if (notification.deliveredAt != null || notification.sentAt != null) {
        return 'grey';
      }
    } else {
      final blackOutTime = expiryTime.add(PingNotificationModel.durationBlackOut);
      if (blackOutTime.isAfter(DateTime.now())) {
        if (notification.response != null) {
          return notification.response! ? 'green' : 'red';
        } else {
          return 'black';
        }
      }
    }

    return 'transparent';
  }

  Future<List<WatchOSMessageTemplate>> _fetchMessageTemplates() async {
    final messages = await SettingRepo.instance.getMessages(teamLeadId).first;
    return messages.asMap().entries.map((entry) {
      return WatchOSMessageTemplate(
        id: 'template${entry.key}',
        message: entry.value,
      );
    }).toList();
  }

  // Methods to send data to the watch
  Future<void> sendNotificationToNative(PingNotificationModel notification) async {
    debugPrint("$debugKey Sending notification to native");
    try {
      await platform.invokeMethod('sendNotificationToNative', <String, dynamic>{
        'notificationId': notification.id,
        'type': notification.type.toString().split('.').last.toString(),
        'message': notification.message,
        'data': notification.data ?? "",
        'fromId': notification.fromId,
        'toId': notification.toId,
        'response': notification.response,
      });
    } on PlatformException catch (e) {
      debugPrint("$debugKey Failed to send notification to native: '${e.message}'.");
    }
  }
}
