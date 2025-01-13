import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/repo/app_lifecycle_service.dart';
import 'package:ping_app/dashboard/dashboard_mode.dart';
import 'package:ping_app/dashboard/dashboard_view.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/member/view/member_list_view.dart';
import 'package:ping_app/notification/view/notification_view.dart';

class MemberDashboard extends StatelessWidget {
  const MemberDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        onPopInvoked(context);
      },
      child: Scaffold(
        body: FutureBuilder(
          future: context.isAndroidWearOS(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == false) {
              return SafeArea(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const Expanded(
                        child: TabBarView(
                          children: [
                            MemberListView(mode: DashboardMode.member),
                            NotificationView(mode: DashboardMode.member),
                          ],
                        ),
                      ),
                      TabBar(
                        indicator: const BoxDecoration(),
                        dividerHeight: 0,
                        tabs: [
                          Tab(
                            text: 't_team'.tr(),
                            icon: const Icon(Icons.group),
                          ),
                          Tab(
                            text: 't_notifications'.tr(),
                            icon: const Icon(Icons.notifications),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
