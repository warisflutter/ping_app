import 'package:flutter/material.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:ping_app/member/repo/member_repo.dart';

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
    _setUserOnline();
  }

  void reset() {
    _setUserOffline();
    _userId = null;
    _isMember = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("AppLifecycleState: $state");
    if (_userId == null) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _setUserOnline();
        break;
      case AppLifecycleState.detached:
        _setUserOffline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _setUserOffline();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _setUserOnline() {
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

  void _setUserOffline() {
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
    print("app life cycle service call");
    _setUserOffline();
  }
}
