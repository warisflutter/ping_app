import 'dart:async' as async;


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:ping_app/member/repo/member_repo.dart';
import 'package:ping_app/notification/repo/notification_service.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLifecycleService with WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  String? _userId;
  bool? _isMember;

  factory AppLifecycleService() {
    return _instance;
  }

  AppLifecycleService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  void initialize({required bool isMember, required String userId}) {
    _userId = userId;
    _isMember = isMember;
    setUserOnline();
  }

  void reset() {
    setUserOffline();
    _userId = null;
    _isMember = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    PingLog.pingLog("AppLifecycleState: $state");

    if (_userId == null) {
      return;
    }
    service.invoke("activeInBackground", {"state": state.name});

    if (state == AppLifecycleState.resumed) {
      setUserOnline();
    }
  }

  void setUserOnline() async {
    final userId = _userId;
    final isMember = _isMember;
    if (userId == null || isMember == null) {
      return;
    }

    if (isMember) {
      MemberRepo.instance.updateOnlineStatus(userId, true);
    } else {
      AuthRepo.instance.updateOnlineStatus(userId, true);
    }
  }

  void setUserOffline() {
    final userId = _userId;
    final isMember = _isMember;
    if (userId == null || isMember == null) {
      return;
    }

    if (isMember) {
      MemberRepo.instance.updateOnlineStatus(userId, false);
    } else {
      AuthRepo.instance.updateOnlineStatus(userId, false);
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint("app life cycle dispose service call");
    setUserOffline();
  }
}

final service = FlutterBackgroundService();

Future<void> initializeService() async {
  debugPrint("Trying to start background service");
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
      isForegroundMode: true,
      autoStart: true,
      autoStartOnBoot: true,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      autoStart: true,
    ),
  );
  service.startService();
  service.invoke("activeInBackground", {"state": "resume"});
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  service.on("activeInBackground").listen((event) async {
    debugPrint("state: ${event?["state"]}");
    async.Timer.periodic(const Duration(seconds: 2), (timer) async {
      debugPrint("This is my service active In Background ${event?["state"]}");
    });
    if (event?["state"] == AppLifecycleState.detached.name) {
      await Firebase.initializeApp();
      final fcmToken = await FirebaseMessaging.instance.getToken() ?? "";
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString("memberId") ?? "";
      PingLog.pingLog("member id $id");
      if (id.isEmpty) {
        String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
        final users = FirebaseFirestore.instance.collection("users");
        users.doc(uid).update({"isOnline": false});
        sendNotificationToTeamLead(fcmToken);
      } else {
        FirebaseFirestore.instance.collection("members").doc(id).update({"isOnline": false});
        sendNotificationToTeamLead(fcmToken);
      }
    }
  });
}

void sendNotificationToTeamLead(String token) async {

  final locale = window.locale;
  final languageCode = locale.languageCode;
  final messages = {
    'en': "Important: Ping App won’t work after you close it.",
    'de': "Wichtig: Die Ping-App funktioniert nicht mehr, nachdem Sie sie geschlossen haben.",
    'fr': "Important : L'application Ping ne fonctionnera plus après sa fermeture.",
    'it': "Importante: L'app Ping non funzionerà dopo averla chiusa.",
    'es': "Importante: La aplicación Ping no funcionará después de cerrarla.",
  };
  final notificationBody = messages[languageCode] ?? messages['en'];
  final notificationService = FirebaseNotificationService();
  notificationService.sendNotification(
    title: "Ping App",
    body: "$notificationBody",
    token: token,
    fromId: "",
    toId: "",
    id: "",
    type: "Not Open",
    messageData: "",
  );
}
