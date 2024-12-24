import 'package:flutter/material.dart';
import 'package:ping_app/auth/repo/ping_auth_state.dart';
import 'package:ping_app/auth/view/create_account_view.dart';
import 'package:ping_app/dashboard/dashboard_view.dart';
import 'package:ping_app/dashboard/member_dashboard.dart';
import 'package:ping_app/member/repo/member_state.dart';
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

  @override
  void initState() {
    updateCounter();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final subsProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      await subsProvider.fetchSubscriptionDetails();
      await subsProvider.showSubscriptions();
      await init();
    });
    super.initState();
  }

  Future<void> init() async {
    // final firebaseUser = Provider.of<PingAuthState>(context, listen: false).currentFirebaseUser;
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final state = Provider.of<PingAuthState>(context, listen: false);
    // final pingUser = state.currentPingUser;
    final memberState = Provider.of<MemberState>(context, listen: false);

    await adminProvider.getAdmin();
    debugPrint("type: ${adminProvider.type}");
    if (adminProvider.type == "admin") {
      debugPrint("===============adminProvider.type == admin");
      replace(const AdminView());
    } else if (adminProvider.type == "user") {
      debugPrint("===============firebaseUser == null || pingUser == null && adminProvider.type == null---------");
      replace(const DashboardView());
    } else {
      await memberState.loadMemberIdFromPrefs();
      final member = memberState.member;
      if (member != null) {
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
