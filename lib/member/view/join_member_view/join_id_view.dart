import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/repo/app_lifecycle_service.dart';
import 'package:ping_app/dashboard/member_dashboard.dart';
import 'package:ping_app/member/repo/member_state.dart';
import 'package:ping_app/notification/repo/notification_service.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:provider/provider.dart';

class JoinIdView extends StatefulWidget {
  const JoinIdView({super.key});

  @override
  State<JoinIdView> createState() => _JoinIdViewState();
}

class _JoinIdViewState extends State<JoinIdView> {
  final memberIdController = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('t_joinById'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: memberIdController,
              decoration: InputDecoration(
                labelText: 't_memberId'.tr(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => actionJoinByQr(memberIdController.text),
              child: Text('t_join'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void actionJoinByQr(String? memberId) async {
    if (memberId == null || memberId.isEmpty) {
      snack('t_pleaseEnterMemberId'.tr());
      return;
    }
    final memberState = context.read<MemberState>();
    setState(() => loading = true);
    try {
      await memberState.setMemberId(memberId);
      final member = memberState.member;
      AppLifecycleService().reset();
      // NotificationService.instance.setNotificationListener(
      //   context,
      //   member!.id,
      //   -1,
      // );
      AppLifecycleService().initialize(isMember: true, userId: member!.id);
      replaceAll(const MemberDashboard());
    } catch (e) {
      setState(() => loading = false);
      snack(e);
    }
  }
}
