import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ping_app/dashboard/dashboard_mode.dart';
import 'package:ping_app/member/view/member_list_view.dart';
import 'package:ping_app/notification/view/notification_view.dart';
import 'package:ping_app/view/settings/view/setting_view.dart';
import 'package:ping_app/util/ping_log.dart';

import '../notification/repo/notification_service.dart';

Future<void> onPopInvoked(BuildContext context) async {
  final bool shouldPop = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.warning,
                color: Colors.red,
              ),
              const SizedBox(width: 5),
              Text('t_areYouSure'.tr()),
            ],
          ),
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

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    PingLog.pingLog("Dashboard initState");
    super.initState();
  }

  @override
  void dispose() {
    PingLog.pingLog("Dashboard dispose");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        await onPopInvoked(context);
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
