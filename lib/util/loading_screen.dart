import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ping_app/auth/repo/app_lifecycle_service.dart';
import 'package:ping_app/auth/repo/ping_auth_state.dart';
import 'package:ping_app/auth/view/create_account_view.dart';
import 'package:ping_app/dashboard/dashboard_view.dart';
import 'package:ping_app/dashboard/member_dashboard.dart';
import 'package:ping_app/member/repo/member_state.dart';
import 'package:ping_app/notification/repo/notification_service.dart';
import 'package:ping_app/util/fcm_repo.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/screen_manager/constants.dart';
import 'package:ping_app/view/admin/admin_provider.dart';
import 'package:ping_app/view/admin/admin_view.dart';
import 'package:ping_app/view/subscription/subscription_provider.dart';
import 'package:provider/provider.dart';

class LoadingScreen extends StatefulWidget {
  final dynamic error;
  final String message;

  const LoadingScreen({
    super.key,
    required this.message,
    this.error,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  int count = 1;
  late SubscriptionProvider subsProvider;

  @override
  void initState() {
    updateCounter();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      subsProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      await initLoadingScreen();
    });
    super.initState();
  }

  Future<void> initLoadingScreen() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final memberState = Provider.of<MemberState>(context, listen: false);

    await adminProvider.getAdmin();
    debugPrint("type: ${adminProvider.type}");
    if (adminProvider.type == "admin") {
      debugPrint("===============adminProvider.type == admin");
      replace(const AdminView());
    } else if (adminProvider.type == "user") {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      NotificationService.instance.setNotificationListener(context, firebaseUser!.uid, 1);
      FcmRepo.instance.updateTeamLeadFcmToken(firebaseUser.uid);
      AppLifecycleService().initialize(
        isMember: false,
        userId: firebaseUser.uid,
      );
      debugPrint("===============firebaseUser == null || pingUser == null && adminProvider.type == null---------");
      replace(const DashboardView());
    } else {
      await memberState.loadMemberIdFromPrefs();
      final member = memberState.member;
      if (member != null) {
        final memberState = Provider.of<MemberState>(context, listen: false);
        final member = memberState.member;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService.instance.setNotificationListener(
            context,
            member!.id,
            -1,
          );
          FcmRepo.instance.updateMemberFcmToken(member.id);
          AppLifecycleService().initialize(isMember: true, userId: member.id);
        });
        debugPrint("---------if--------------member != null");
        replace(const MemberDashboard());
      } else {
        debugPrint("---------else--------------member != null");
        replace(const CreateAccountView());
      }
      debugPrint("--------------------loading screen else--------------------------");
    }
  }

  void updateCounter() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => count++);
        updateCounter();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(children: [
        Center(
          child: Image.asset("assets/images/logo.png", width: mobileWidth),
        ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.error != null
                  ? getErrorMessage(context, widget.error)
                  : count < 6
                      ? tweenAnimationBuilder()
                      : getLoader(),
              const SizedBox(height: 8),
              Text(widget.message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ]),
    ));
  }

  Widget tweenAnimationBuilder() {
    return TweenAnimationBuilder(
      duration: const Duration(seconds: 1),
      tween: Tween<double>(begin: count - 1, end: count + 0.0),
      builder: (context, double value, child) {
        return CircularProgressIndicator(
          value: value / 5,
          color: Colors.white,
          backgroundColor: Colors.grey.withOpacity(0.1),
        );
      },
    );
  }
}
