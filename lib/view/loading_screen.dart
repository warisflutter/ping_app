import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/repo/app_lifecycle_service.dart';
import 'package:ping_app/auth/view/create_account_view.dart';
import 'package:ping_app/dashboard/dashboard_view.dart';
import 'package:ping_app/dashboard/member_dashboard.dart';
import 'package:ping_app/member/repo/member_state.dart';
import 'package:ping_app/services/api_service.dart';
import 'package:ping_app/services/notification_service.dart';
import 'package:ping_app/services/sp_service.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:ping_app/util/screen_manager/constants.dart';
import 'package:ping_app/view/admin/admin_provider.dart';
import 'package:ping_app/view/admin/admin_view.dart';
import 'package:ping_app/view/check_payment/check_payment_screen.dart';
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

  @override
  void initState() {
    updateCounter();
    initLoadingScreen();
    super.initState();
  }

  Future<void> initLoadingScreen() async {
    final res = await ApiService().checkPayment();
    if (res) {
      replace(const CheckPaymentScreen());
      return;
    }
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    AppLifecycleService().reset();
    await adminProvider.getAdmin();
    PingLog.pingLog("type: ${adminProvider.type}");
    String memberId = await SPService().getMemberId();
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (memberId.isEmpty && firebaseUser != null) {
      if (adminProvider.type == "user") {
        FirebaseNotificationService().updateTeamLeadFcmToken(firebaseUser.uid);
        AppLifecycleService().initialize(
          isMember: false,
          userId: firebaseUser.uid,
        );
        replace(const DashboardView());
      } else {
        replace(const AdminView());
      }
    } else {
      if (mounted) {
        final memberState = Provider.of<MemberState>(context, listen: false);
        bool isMember = await memberState.loadMemberIdFromPrefs();
        if (isMember) {
          final member = memberState.member;
          if (member != null) {
            final member = memberState.member;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              FirebaseNotificationService().updateMemberFcmToken(member!.id);
              AppLifecycleService().initialize(isMember: true, userId: member.id);
              replace(const MemberDashboard());
            });
            PingLog.pingLog("---------if--------------member != null");
          } else {
            PingLog.pingLog("---------else--------------member != null");
            replace(const CreateAccountView());
          }
        } else {
          replace(const CreateAccountView());
        }
      }
      PingLog.pingLog("--------------------loading screen else--------------------------");
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
      ),
    );
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
