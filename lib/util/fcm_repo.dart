import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:ping_app/member/repo/member_repo.dart';

class FcmRepo {
  static final instance = FcmRepo();

  Future<void> initialise() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // FirebaseMessaging.onMessage.listen(_foregroundMessageHandler);
    // FirebaseMessaging.onBackgroundMessage(null);
  }

  Future<void> updateMemberFcmToken(String memberId) async {
    String? token = await FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb
          ? "BDn_sSLC6I_v1As_3HGaoPdIhIZwrrDXmRFHk3S8P0o4aKdZsO1lTJVmhy97nyfjreVveDX8vZpj5zI8qoDT9lM"
          : null,
    );
    if (token != null) {
      await MemberRepo.instance.updateFcmToken(memberId, token);
    }
  }

  Future<void> updateTeamLeadFcmToken(String teamLeadId) async {
    String? token = await FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb
          ? "BDn_sSLC6I_v1As_3HGaoPdIhIZwrrDXmRFHk3S8P0o4aKdZsO1lTJVmhy97nyfjreVveDX8vZpj5zI8qoDT9lM"
          : null,
    );
    if (token != null) {
      await AuthRepo.instance.updateFcmToken(teamLeadId, token);
    }
  }
}

// void _foregroundMessageHandler(RemoteMessage message) {
//   _handleNotification(message);
// }

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   debugPrint("Handling from bg");
//   _handleNotification(message);
// }
//
// void _handleNotification(RemoteMessage message) {
//   final data = message.data;
//   final notData = jsonDecode(data['notificationData']);
//
//   if (notData != null) {
//     final String notId = notData['notificationId'];
//     final notification = PingNotificationModel.fromJson(notId, notData);
//     if (!notification.isDelivered) {
//       WatchConnectivity.instance.sendNotificationToNative(notification);
//     }
//   } else {
//     debugPrint("Notification data null");
//   }
// }
