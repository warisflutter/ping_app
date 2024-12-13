import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';

class PingAuthState extends ChangeNotifier {
  bool _loading = true;
  StreamSubscription<User?>? _firebaseUserStream;

  PingUserModel? _pingUser;
  User? _firebaseUser;

  PingUserModel? get currentPingUser => _pingUser;

  User? get currentFirebaseUser => _firebaseUser;

  bool get loading => _loading;

  PingAuthState({required Stream<User?> userStream}) {
    _loading = true;
    notifyListeners();
    _firebaseUserStream = userStream.listen((user) async {
      _loading = true;
      notifyListeners();
      if (user == null) {
        _pingUser = null;
        _firebaseUser = null;
      } else {
        _firebaseUser = user;
        _pingUser = await AuthRepo.instance.getUserById(user.uid);
      }

      _loading = false;
      notifyListeners();
    });
  }

  Future<void> reloadPingUser() async {
    final user = _firebaseUser;
    if (user == null) {
      throw Exception('t_userIsLoggedIn'.tr());
    }
    _pingUser = await AuthRepo.instance.getUserById(user.uid);
    notifyListeners();
  }

  @override
  void dispose() {
    _firebaseUserStream?.cancel();
    super.dispose();
  }
}
