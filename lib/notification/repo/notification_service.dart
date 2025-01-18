import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:ping_app/file_path.dart';
import 'package:ping_app/notification/model/ping_notification_model.dart';
import 'package:ping_app/notification/repo/notification_repo.dart';
import 'package:ping_app/notification/view/notification_response_dialog.dart';
import 'package:ping_app/util/navigator.dart';

class FirebaseNotificationService {
  void _showNotificationAndDeliver(
    BuildContext context,
    PingNotificationModel notification,
  ) async {
    await showDialog(
      context: navigatorKey.currentState!.context,
      builder: (context) {
        Future.delayed(const Duration(seconds: 30)).then((value) {
          safePop();
        });
        return NotificationResponseDialog(notification: notification);
      },
    );

    NotificationRepo.instance.markNotificationDelivered(notification.id);
  }

  Future<String> getAccessToken() async {
    Map<String, String> serviceAccountJson = {
      "type": "service_account",
      "project_id": "pingapp-94e13",
      "private_key_id": "c16b07386e4e3bfee1d966b0f1fc2711cc4d9013",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDe4nOL/UM6YaZs\nzLul6EsuvTkE4nf0B/wqjg86A5ZY+we2pzBXMIi8ryiorVaNWuCGBI/BPUrW/pxF\nmY8Ympi4ztWEwvOyENBuxgoUXdqEjY4N1biJrVU8rMk6eMjO8CwAVDIN73o9r7Vm\nUGTYnNEFBN51sydWYHptKx8TKQugj65BEjnLdaLkElH6baJLLQreSGzvqNrwtyai\naAPOvstK/dHIYAYPfZJ3JH82cEMQpzQePEO89SyDppZl6v4R7Vt/9g6n/nXx0hbf\nf0TQr/QwL8LURUYMYbnE7BqHRrCQoBney6OfufUGLZB2N1BZO9oAShneO7xvCwXX\n5W/RKcSjAgMBAAECggEAJ7EeMKTmjwQK1j9Tf4Uxtl4eRF9sSzoMzytDTOqMoMX7\npqx5cF2FTEzJKdjMnBm9+D/hteELbeQjwkVJdXE6l1bGMYFiUqip5cBA1UWtf4OR\n86bG2UXT8x02LMKLyEZ/H4Pe8hpeo5Oh81mHzAeJNaKbV0yTSc+enchbHVdm6a23\nm/d665NO7TsV2mn+jv5xMEjrdu33E32H9BqjynORuOhAZIJswG3YAF5cARlKniBD\nL04H4fkz5NEtBtZoLFed2sTdN30K0ndLMcP2zP1UcfCOng93yr8agU+U5DOYexR1\n1PO7ilOAdvKUT0Dk1sUNNNfpJFj/EsdHgxzsf8mpEQKBgQDqm/Oh+0rAx1TAdy2a\n011QRLT6QPJWvVy3lXZTN7//X4Kb9/DSBNWNjKT7v5Z+9mIFUPe/0UznBqdLtRJc\n9b4Qw4gwlWYxqAvGaVcwJS/+nMdCtU6G+Uk+H3NBiXATHhZ1D0tJwF9ZGFZ+ZZxT\n1BFP5cOMAf94ChLMuSyIB2wrmQKBgQDzNNVxeFX+8dBi9M84NQrLihwQFtl67yUZ\nzGCScxSNTsfBek0AWD+Ogf5EG1UiD89dW1WCtsr0ABl2mpKt504EpW0DKBAtT7dn\n+WkPlQOO2YLxBvzCfeBH3xIZ23S6Nf/JPCzsLPreYaHqyJE+0HLQmqTHzl6hLuSQ\nMTQkpCm3mwKBgQDNl2KWJVepvkQn8Yh2cBkK2VrbHwT/PCw++OxbGrTW/oS/VzSj\nZvcZdxGxR4CDvDfDvuONJcZFghAjCQeRjQxFNoRnRtTqWQAQnIl6OGxprEv1ylqJ\nb3VeykK/QMiFCE3XwVJRzBICSpCpbTPkRifxo0CMtceBExrMas16Wz7QqQKBgHSw\nIMi0h+4ub2FLPDEnoepOdXByxh3pp89c8+jQNkgmSElYOKG1tajWTfy3cH1LQJ72\nN2zj7zRq58y0FTRDCnfINymQi1JyMPk9/V5wjKh5TA4A4D0gz/8r1C97z+GYDwWq\nTZNzcVpJVbqkSKvur2fPCsijB1wmd5uHQBFkgm+JAoGBAM55ugk6XIdemkjt9JX9\nmF+JIq2P47gC2oWYBXCXg+BtskOLfsGVidLcaQumd9Exj+fYAoPc0tKnGQPiMpty\nmryKtqhNDdHtabIJWLS6S9p1Fs9HOI8gutVHBvb6e04cyfHvTO4XGo0txdA3fysu\nIIIZU8QUtRwZxN9nGnoROCrN\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-ydvcm@pingapp-94e13.iam.gserviceaccount.com",
      "client_id": "100676089515935679871",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-ydvcm%40pingapp-94e13.iam.gserviceaccount.com",
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
    required String token,
    required String fromId,
    required String toId,
    required String id,
    required String type,
    required String messageData,
  }) async {
    Completer<bool> completer = Completer<bool>();
    try {
      String serverTokenKey = await getAccessToken();
      String endPoint = "https://fcm.googleapis.com/v1/projects/pingapp-94e13/messages:send";
      Map<String, dynamic> message = {
        "message": {
          "token": token,
          "notification": {"title": title, "body": body},
          "data": {
            "id": id,
            "fromId": fromId,
            "toId": toId,
            "type": type,
            "message": messageData,
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
      debugPrint('body: ${response.body}');
      if (response.statusCode == 200) {
        log('Notification sent successfully');
        log(response.body);
        completer.complete(true);
      } else {
        completer.complete(false);
        log('Failed to send notification. Status code: ${response.statusCode}');
      }
    } catch (e, s) {
      completer.complete(false);
      log('Error sending notification: $e $s');
    }
    return completer.future;
  }

  Future<void> handleMessage(RemoteMessage message) async {
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
        message: message.notification?.body ?? "",
      );
      _showNotificationAndDeliver(context, notification);
    }
  }

  Future<String?> getDeviceToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    try {
      String? token = await messaging.getToken();
      return token;
    } catch (e) {
      PingLog.pingLog("Error retrieving FCM Token: $e");
      return null;
    }
  }
}
