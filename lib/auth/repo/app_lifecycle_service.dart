import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:ping_app/file_path.dart';

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
    log("This is userId => $_userId");

    if (state == AppLifecycleState.detached) {
      setUserOffline(state: state.name);
    } else {
      PingLog.pingLog("AppLifecycleState resume");
      setUserOnline();
    }
  }

  void setUserOnline() async {
    // final prefs = await SharedPreferences.getInstance();
    // String id = prefs.getString("memberId") ?? "";
    // PingLog.pingLog("id: $id");
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

  void setUserOffline({String state = 'Sata'}) {
    final userId = _userId;
    final isMember = _isMember;
    if (userId == null || isMember == null) {
      return;
    }

    if (isMember) {
      MemberRepo.instance.updateOnlineStatus(userId, false, state: state);
    } else {
      AuthRepo.instance.updateOnlineStatus(userId, false, state: state);
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    print("app life cycle dispose service call");
    setUserOffline();
  }
}
