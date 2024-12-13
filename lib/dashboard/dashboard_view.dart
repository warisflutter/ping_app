import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/dashboard/dashboard_mode.dart';
import 'package:ping_app/member/view/member_list_view.dart';
import 'package:ping_app/notification/view/notification_view.dart';
import 'package:ping_app/settings/view/setting_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  Tab(
                      text: 't_notifications'.tr(),
                      icon: const Icon(Icons.notifications)),
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
    );
  }
}
