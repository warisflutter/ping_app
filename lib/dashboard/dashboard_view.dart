import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ping_app/dashboard/dashboard_mode.dart';
import 'package:ping_app/dashboard/dashboard_provider.dart';
import 'package:ping_app/member/view/member_list_view.dart';
import 'package:ping_app/notification/view/notification_view.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:ping_app/util/ping_styles.dart';
import 'package:ping_app/util/ping_utils.dart';
import 'package:ping_app/view/settings/view/setting_view.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../util/helper_class.dart';

Future<void> onPopInvoked(BuildContext context) async {
  final bool shouldPop = await showDialog(
        context: context,
        builder: (context) => context.isWatch ? Scaffold(
          body: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Center(
              child: Column( 
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text('t_areYouSure'.tr(), style: PingStyles.watchStyle.copyWith(fontWeight: FontWeight.w700),),
                    ],
                  ),
                  const SizedBox(height: 5,),
                  Text('t_closingThisWorkProperly'.tr(), style: PingStyles.watchStyle, textAlign: TextAlign.center,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      RawMaterialButton(
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 15,
                        ),
                        padding: const EdgeInsets.all(4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)
                        ),
                        fillColor: Colors.green.withValues(alpha: 0.3),
                        onPressed: () => Navigator.of(context).pop(false) , child: Text('Cancel', style: PingStyles.watchStyle,),),
                      RawMaterialButton(
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 15,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)
                        ),
                        padding: const EdgeInsets.all(4),
                        fillColor: Colors.redAccent.withValues(alpha: 0.3),
                        onPressed: () => Navigator.of(context).pop(true) , child: Text('Ok', style: PingStyles.watchStyle,),),
                    ],
                  )
                ],
              ),
            ),
          ),
        ) : AlertDialog(
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
  final notification = FirebaseNotificationService();
  @override
  void initState() {
    super.initState();
    PingLog.pingLog("Dashboard initState");
    if(HelperClass.message != null){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notification.handleMessage(HelperClass.message!);
        HelperClass.message = null; // Prevent it from showing again
      });
    }
  }

  @override
  void dispose() {
    PingLog.pingLog("Dashboard dispose");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashBoardProvider>(
      create: (_) => DashBoardProvider(),
      builder: (__, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) {
              return;
            }
            await onPopInvoked(context);
          },
          child: Scaffold(
            key: const Key("dashboardView"),
            body: Consumer<DashBoardProvider>(
              builder: (context, provider, _) {
                return SafeArea(
                  child: (context.isWatch)
                      ? Localizations.override(
                          context: context,
                          locale: context.locale,
                          child: Column(
                            children: [
                              Expanded(
                                child: (provider.currentIndex == 0)
                                    ? const MemberListView(mode: DashboardMode.teamLead)
                                    : (provider.currentIndex == 1)
                                        ? const NotificationView(mode: DashboardMode.teamLead)
                                        : const SettingView(),
                              ),
                              Row(
                                children: List.generate(
                                  provider.pages.length,
                                  (index) {
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: InkWell(
                                          onTap: () {
                                            provider.onTap(index);
                                          },
                                          child: Column(
                                            children: [
                                              provider.pages[index]["icon"],
                                              Text(
                                                "${provider.pages[index]["title"]}".tr(),
                                                style: PingStyles.watchStyle,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        )
                      : DefaultTabController(
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
                              Localizations.override(
                                context: context,
                                locale: context.locale,
                                child: TabBar(
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
                              ),
                            ],
                          ),
                        ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
