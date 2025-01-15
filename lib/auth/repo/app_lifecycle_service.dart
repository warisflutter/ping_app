import 'dart:async';
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
    service.invoke(state.name);
    if (_userId == null) {
      return;
    }
    if (state == AppLifecycleState.detached) {
      setUserOffline(state: state.name);
    } else {
      PingLog.pingLog("AppLifecycleState resume");
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

  void setUserOffline({String state = 'Sata'}) {
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
  service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
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
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  service.on(AppLifecycleState.detached.name).listen((event) async {
    debugPrint("app is successfully detached in ${DateTime.now().second}");
    debugPrint("service is successfully detached in ${DateTime.now().second}");
    await Future.delayed(const Duration(seconds: 3));
    service.stopSelf();
  });

  service.on(AppLifecycleState.inactive.name).listen((event) {
    debugPrint("app is successfully inactive in ${DateTime.now().second}");
    // service.stopSelf();
  });

  service.on(AppLifecycleState.paused.name).listen((event) {
    debugPrint("app is successfully paused in ${DateTime.now().second}");
    // service.stopSelf();
  });

  service.on(AppLifecycleState.resumed.name).listen((event) {
    debugPrint("app is successfully resumed in ${DateTime.now().second}");
    // service.stopSelf();
  });

  service.on(AppLifecycleState.hidden.name).listen((event) {
    debugPrint("app is successfully hidden in ${DateTime.now().second}");
    // service.stopSelf();
  });

  service.on("start").listen((event) {
    debugPrint("service is successfully started in ${DateTime.now().second}");
  });

  Timer.periodic(const Duration(minutes: 1), (timer) {
    debugPrint("service is successfully running in ${DateTime.now().second}");
  });
}
