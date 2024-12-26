import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:ping_app/dashboard/dashboard_mode.dart';
import 'package:ping_app/member/view/member_list_view.dart';
import 'package:ping_app/notification/view/notification_view.dart';
import 'package:ping_app/settings/view/setting_view.dart';
import 'package:ping_app/view/subscription/subscription_provider.dart';
import 'package:provider/provider.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onPopInvoked(BuildContext context) async {
    final bool shouldPop = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('t_areYouSure'.tr()),
            content: Text('t_closingThisWorkProperly'.tr()),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('t_no'.tr()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text('t_yes'.tr()),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldPop) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        _onPopInvoked(context);
      },
      child: Scaffold(
        key: const Key("dashboardView"),
        body: SafeArea(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const Expanded(
                  child: TabBarView(
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      MemberListView(mode: DashboardMode.teamLead),
                      NotificationView(mode: DashboardMode.teamLead),
                      SettingView(),
                    ],
                  ),
                ),
                TabBar(
                  indicator: const BoxDecoration(),
                  dividerHeight: 0,
                  tabs: [
                    Tab(text: 't_team'.tr(), icon: const Icon(Icons.group)),
                    Tab(text: 't_notifications'.tr(), icon: const Icon(Icons.notifications)),
                    Tab(
                      key: const Key("tabSettings"),
                      text: 't_settings'.tr(),
                      icon: const Icon(Icons.settings),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
