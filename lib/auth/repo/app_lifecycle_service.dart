import 'package:flutter/material.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:ping_app/member/repo/member_repo.dart';
import 'package:ping_app/member/repo/member_state.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:provider/provider.dart';
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    PingLog.pingLog("AppLifecycleState: $state");
    if (_userId == null) {
      return;
    }
    switch (state) {
      case AppLifecycleState.resumed:
        setUserOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        setUserOffline();
        break;
      case AppLifecycleState.detached:
        setUserOffline();
        break;
    }
  }

  void setUserOnline() async {
    final prefs = await SharedPreferences.getInstance();
    String id = prefs.getString("memberId") ?? "";
    PingLog.pingLog("id: $id");
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
    print("app life cycle dispose service call");
    setUserOffline();
  }
}
