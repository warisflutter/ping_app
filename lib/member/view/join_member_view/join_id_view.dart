import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/dashboard/member_dashboard.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/util/ping_styles.dart';

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
      appBar: context.isWatch ? null : AppBar(title: Text('t_joinById'.tr())),
      body: Padding(
        padding: EdgeInsets.all(context.isWatch ? 10 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if(context.isWatch)
            Text('t_joinById'.tr(), style: PingStyles.watchStyle,),
            const SizedBox(height: 10,),
            TextField(
              controller: memberIdController,
              decoration: InputDecoration(
                labelText: 't_memberId'.tr(),
                labelStyle: context.isWatch ? PingStyles.watchStyle : null
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
      if(context.isWatch){
        dialog(false, context, 't_pleaseEnterMemberId'.tr());
      }
      else{
        snack('t_pleaseEnterMemberId'.tr());
      }
      return;
    }
    final memberState = context.read<MemberState>();
    setState(() => loading = true);
    try {
      await memberState.setMemberId(memberId);
      final member = memberState.member;
      AppLifecycleService().reset();
      AppLifecycleService().initialize(isMember: true, userId: member!.id);
      FirebaseNotificationService().updateMemberFcmToken(member.id);
      replaceAll(const MemberDashboard());
    } catch (e) {
      setState(() => loading = false);
      snack(e);
    }
  }
}
