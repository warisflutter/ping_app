import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:ping_app/file_path.dart';
import 'package:ping_app/member/model/member_model.dart';
import 'package:ping_app/notification/model/ping_notification_model.dart';
import 'package:ping_app/notification/repo/notification_repo.dart';
import 'package:ping_app/notification/view/notification_response_dialog.dart';
import 'package:ping_app/services/firebase_service.dart';
import 'package:vibration/vibration.dart';

class FirebaseNotificationService {
  FirebaseNotificationService() {
    requestPermission();
  }

  void _showNotificationAndDeliver(BuildContext context, PingNotificationModel notification,
      {bool playSound = false}) async {
    await showDialog(
      context: navigatorKey.currentState!.context,
      builder: (context) {
        if (playSound) {
          playAudio();
          if(!kIsWeb){
            startVibration();
          }
        }
        return NotificationResponseDialog(notification: notification);
      },
    );

    NotificationRepo.instance.markNotificationDelivered(notification.id);
  }

  late AudioPlayer player = AudioPlayer();

  Future<void> playAudio() async {
    player = AudioPlayer();
    try {
      await player.setSource(AssetSource("sound/beep_sound.mp3"));
      await player.resume();
    } catch (e) {
      debugPrint("Failed to play audio");
    }
  }

  Future<void> startVibration() async {
    if (await Vibration.hasCustomVibrationsSupport()) {
      Vibration.vibrate(duration: 3000);
    } else {
      Vibration.vibrate();
      await Future.delayed(const Duration(milliseconds: 500));
      Vibration.vibrate();
    }
  }

  Future<String> getAccessToken() async {
    Map<String, String> serviceAccountJson = {
      "type": "service_account",
      "project_id": "ping-5657e",
      "private_key_id": "3e6c7873a3b65af94b2203f6627b9d3247d88ecc",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCbDbDPjjK6X+FZ\nsjPV3VX3A3j/ZthG/elZ50Elj00TTLr/1erEbRskiPHPfBBW4yIbOFDB/AwB8fQA\n5BSn7b4YzSPINKD/fS4c5zPfsW7Fd2n35zInxABpu8wZKCejzRq7rLjJtVaBgzRd\nwk8AAue8P28pWHJV5yBJsH9PBfHBxsBSdUBsZwZ3zKPbJqsvW2cuw+wWKzw04khs\n37HPushCgDBoPnZ4NV09jZh3Fj1SxX86Cmje1PPDFuf3ahd8lkwYCyok5NLd3ZVd\nrJGjusXKBQoJPTCa/mqbFcFR200jATnsyVa4icy+n46qc0yQHIGDeQpTscEH5J8o\nC0bGOPyjAgMBAAECggEAJUJedRnaFdA5gkjgzOkhobiLaHBJ05FrdEeub3ymjFc5\nboX0otwHFDn2RaIt+PsetITNXzgWmJcQR/CHCC2Iq0QMb6057PsjTB3A6OWl1TzT\nUZeUhVrDsKTIsFjmYaXFYUjppMr3LSset9McEcgg8KsbpsdSvlLKfvqzNQWcKTCe\nPczjLofkS+0LIwcZnPR+uyvpxcNBSnBJeA8QtBWDVKOR2NdPmWBIOIkOXrKl1tYZ\nUvK+jmrn5FDXtMThD2ZD20B3EGwzNqO8ChsGBA6wlesQWuesm/2uRdY/+6CUfT5w\nSoE3H6B8UoXl5obiJd2v+B/3r0syzngrIvDbpUg2eQKBgQDKckl+7E3pvAkO5Jzb\ncHT0oqb7lHSfT3Ija9cYl6Zhh/twH5VJYBPCrIuJ2MjokjLslcpUavrfsrkjYKlk\n/Fdx7ucRyZOVvOlZwQUGeDx+fN2PpPZzCa3BNqkbSGI7e3YABi5P61qSi8GhKY3U\ng6/+yZYaEaqBzPE+XcgzlZhjmQKBgQDEEfF2wC8sfO5O+Ugau0Pr+StA3Owum4f1\n23/BXBDd+gGPqj+OkULcaZFRicd5cwbQO6UbnEerBGX+LBc8fVBx0wvrBZsX8E9s\nY6Mg11wIsQaSjlhaZe653fEw3HGx+B+lh40ka+8f4YEkexrTKBoAFWXfJQ4ECozg\nkJZoT0eHmwKBgEilHCR0bTzrYaC7fmHsB7vlReBPFE46du2o++VyPZ0P67T/UFWl\nKVIZEnVjmiyCkc19rr3+KYnuGytLu11mg4Z5wOcMG26G/IFdlw0MRkDpU6QBAQKk\nvXnwwFvu7HkFw4Ectq+s97JQfinzvFY+7v+RnNA7+KBdR1Am3PlNvAI5AoGAUsaQ\nfmXchJeptEWhn0d4AWOMUzHxtCuNVsp4QRWxOUWW6yQg+PtyksMuypG0WR2qvrav\nmdx8lUKiHJBYrvzovWUwHuSa+ZxGq6fU8sR44mJ6N91Ih8GI64c7kDlA9rWeBrAX\nckzvAzKc5t3iEUtYzrg57d8i76nUl+ny1c7CkAkCgYEAoMMlI7A+7irFqM5ObtZP\nWbazc/sKJMCP7XOK+wIpeN2iAGKvLdzxydr3RBhUiIXYBfNDOU2OX5gEA5Op/j1T\nw9tjKFEFlyaK1dRYzNICeG7WQ6KDf+dV2Ytlh6iv/m8+lzz6PaPLkbfwAWLC4zvz\nwZhUjqAChRcos4//qCthjWw=\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-fbsvc@ping-5657e.iam.gserviceaccount.com",
      "client_id": "114541638195834457984",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40ping-5657e.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };
    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];
    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );
    auth.AccessCredentials credentials = await auth.obtainAccessCredentialsViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
      client,
    );
    client.close();
    return credentials.accessToken.data;
  }

  Future<bool> sendNotification({
    required String title,
    required String body,
    required List<FcmEntity> tokens,
    required String fromId,
    required String toId,
    required String id,
    required String type,
    required String messageData,
  }) async {
    try {
      String serverTokenKey = await getAccessToken();
      String endPoint = "https://fcm.googleapis.com/v1/projects/ping-5657e/messages:send";

      for (var token in tokens) {
        Map<String, dynamic> message = {
          "message": {
            "token": token.token,
            if(token.device != 'Web')
            "notification": {
              "title": title, "body": body},
            "data": {
              "id": id,
              "title": title,
              "body": body,
              "fromId": fromId,
              "toId": toId,
              "type": type,
              "message": messageData,
              "click_action": "https://ping-5657e.web.app/?showDialog=true"
                  "&type=$type"
                  "&body=$body"
                  "&message=${Uri.encodeComponent(messageData)}"
                  "&id=$id"
                  "&fromId=$fromId"
                  "&toId=$toId"
            },
            "android": {
              "priority": "high",
            },
          }
        };

        http.Response response = await http.post(
          Uri.parse(endPoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $serverTokenKey',
          },
          body: jsonEncode(message),
        );

        debugPrint('Response body: ${response.body}');

        if (response.statusCode != 200) {
          log('Failed to send notification. Status code: ${response.statusCode}');
          Map<String, dynamic> responseData = jsonDecode(response.body);
          if (responseData["error"]?["status"] == "NOT_FOUND" ||
              responseData["error"]?["details"]?.any((d) => d["errorCode"] == "UNREGISTERED") == true) {
            debugPrint("❌ Token Expired: ${token.token} | Device: ${token.device}");
            bool isMember = false;
            final user = await FirebaseFirestore.instance.doc('members/$toId').get();
            if (user.exists) {
              isMember = true;
            } else {
              isMember = false;
            }
            await removeToken(
              fcmToken: token.token,
              uid: toId,
              collectionName: (isMember) ? "members" : "users",
            );
          }
        }
      }
      return true;
    } catch (e, s) {
      log('Error sending notification: $e $s');
      return false;
    }
  }

  Future<void> handleMessage(
    RemoteMessage message, {
    bool playSound = false,
  }) async {
    PingLog.pingLog("This is my type: ${message.data["type"]}");
    if (message.data["type"] == "Not Open") {
    } else {
      BuildContext context = navigatorKey.currentState!.context;
      final notification = PingNotificationModel(
        data: message.data["message"],
        id: message.data["id"],
        type: NotificationType.values[int.parse(message.data["type"])],
        toId: message.data["toId"],
        fromId: message.data["fromId"],
        message: message.data['body'] ?? message.data['message'] ?? ''
      );
      _showNotificationAndDeliver(context, notification, playSound: playSound);
    }
  }

  Future<void> requestPermission() async {
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
  }

  Future<void> updateMemberFcmToken(String memberId) async {
    String? token = await getDeviceToken();
    if (token != null) {
      await MemberRepo.instance.updateFcmToken(memberId, token);
    }
  }

  Future<void> updateTeamLeadFcmToken(String teamLeadId) async {
    String? token = await getDeviceToken();
    if (token != null) {
      await AuthRepo.instance.updateFcmToken(teamLeadId, token);
    }
  }

  Future<void> removeToken({
    required String fcmToken,
    required String uid,
    required String collectionName,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection(collectionName).doc(uid);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        List<FcmEntity> existingTokens = [];
        // if (docSnapshot.data() != null && docSnapshot.data()!.containsKey("fcm")) {
        //   existingTokens = List.from(docSnapshot.get("fcm"));
        // }
        if (docSnapshot.data() != null &&
            docSnapshot.data()!.containsKey(PingUserModel.keyFcmToken)) {
          List<dynamic> rawList = docSnapshot.get(PingUserModel.keyFcmToken);
          existingTokens = rawList
              .map((item) => FcmEntity.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }

        // Remove the FCM token from the list
        existingTokens.removeWhere((token) {
          bool data = (token.token == fcmToken);
          debugPrint("Remove the FCM token from the list1 ${token.token}");
          debugPrint("Remove the FCM token from the list2 $fcmToken");
          debugPrint("Remove the FCM token from the list $data");
          return data;
        });

        await docRef.update({
          "isOnline": false,
          "fcm": existingTokens.map((e) => e.toJson()).toList(),
        });
        // 🔍 **Check if the token is removed**
        final updatedDoc = await docRef.get();
        // List<dynamic> updatedTokens = updatedDoc.data()?["fcm"] ?? [];
        // if (!updatedTokens.contains(fcmToken)) {
        //   debugPrint("✅ Token removed successfully!");
        // } else {
        //   debugPrint("❌ Token still exists!");
        // }
        List<dynamic> updatedTokens = updatedDoc.data()?["fcm"] ?? [];

        bool tokenStillExists = updatedTokens.any((item) {
          final map = Map<String, dynamic>.from(item);
          return map['token'] == fcmToken;
        });

        if (!tokenStillExists) {
          debugPrint("✅ Token removed successfully!");
        } else {
          debugPrint("❌ Token still exists!");
        }
      }
    } catch (e) {
      debugPrint("remove token: $e");
    }
  }

  Future<String?> getDeviceToken({int maxRetires = 3}) async {
    try {
      String? token;
      if (kIsWeb) {
        // get the device fcm token
        token = await FirebaseMessaging.instance.getToken(
          vapidKey: FirebaseService().vapidKey,
        );
        if (kDebugMode) {
          print("for web device token: $token");
        }
      } else {
        // get the device fcm token
        token = await FirebaseMessaging.instance.getToken();
        if (kDebugMode) {
          print("for android device token: $token");
        }
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print("failed to get device token");
      }
      if (maxRetires > 0) {
        if (kDebugMode) {
          print("try after 10 sec");
        }
        await Future.delayed(const Duration(seconds: 10));
        return getDeviceToken(maxRetires: maxRetires - 1);
      } else {
        return null;
      }
    }
  }

  // void checkNotificationPayloadForWeb() {
  //   final uri = Uri.base;
  //
  //   if (uri.queryParameters['showDialog'] == 'true') {
  //     final type = uri.queryParameters['type'];
  //     final message = uri.queryParameters['message'];
  //     final id = uri.queryParameters['id'] ?? '';
  //     final fromId = uri.queryParameters['fromId'] ?? '';
  //     final toId = uri.queryParameters['toId'] ?? '';
  //
  //     final notification = PingNotificationModel(
  //       data: message,
  //       id: id,
  //       type: NotificationType.values[int.parse(type!)],
  //       toId: toId,
  //       fromId: fromId,
  //       message: message ?? '',
  //     );
  //
  //     // Make sure navigatorKey is already set and context is available
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       final context = navigatorKey.currentState!.context;
  //       _showNotificationAndDeliver(context, notification);
  //       html.window.history.replaceState(null, 'Ping', Uri.base.path);
  //     });
  //   }
  // }


}
