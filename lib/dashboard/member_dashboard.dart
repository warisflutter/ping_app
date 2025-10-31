import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/dashboard/dashboard_mode.dart';
import 'package:ping_app/dashboard/dashboard_view.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/member/view/member_list_view.dart';
import 'package:ping_app/notification/view/notification_view.dart';
import 'package:ping_app/util/ping_styles.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import 'package:screenshot/screenshot.dart';
// import 'package:wear_plus/wear_plus.dart';

import '../member/model/member_model.dart';
import '../member/view/member_list_item.dart';
import '../services/notification_service.dart';
import '../util/helper_class.dart';
// import '../widgets/watch_member_list_tile.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  final notification = FirebaseNotificationService();

  @override
  void initState() {
    super.initState();
    if (HelperClass.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notification.handleMessage(HelperClass.message!);
        HelperClass.message = null; // Prevent it from showing again
      });
    }
  }

  //B1VcQLO7P1LrLNwjxixX

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        onPopInvoked(context);
      },
      child: Scaffold(
        body: SafeArea(
          child:
              // ? Consumer<SubscriptionProvider>(
              //     builder: (context, subscriptionProvider, _) {
              //       final authState = context.watch<PingAuthState>();
              //       final memberState = context.watch<MemberState>();
              //       const mode = DashboardMode.member;
              //       final isTeamLead = mode.isTeamLead;
              //       final isMember = mode.isMember;
              //       final myTeamLead = isTeamLead
              //           ? authState.currentPingUser
              //           : memberState.teamLead;
              //       final ifMember = memberState.member;
              //       if (isMember && ifMember == null) {
              //         return getErrorMessage(context, "");
              //       }
              //       if (myTeamLead == null) {
              //         return getErrorMessage(context, "");
              //       }
              //       return WatchShape(
              //           builder: (context, shape, _) => Padding(
              //                 padding: const EdgeInsets.symmetric(
              //                     horizontal: 15, vertical: 10),
              //                 child: Column(
              //                   mainAxisSize: MainAxisSize.min,
              //                   children: [
              //                     WatchShape(
              //                       builder: (context, shape, _) => shape ==
              //                               WearShape.round
              //                           ? Column(
              //                               children: [
              //                                 Row(
              //                                   crossAxisAlignment:
              //                                       CrossAxisAlignment.center,
              //                                   mainAxisAlignment:
              //                                       MainAxisAlignment.center,
              //                                   children: [
              //                                     GestureDetector(
              //                                         onTap: () => push<String>(
              //                                               const NotificationView(
              //                                                   mode:
              //                                                       DashboardMode
              //                                                           .member),
              //                                             ),
              //                                         child: const Icon(
              //                                           Icons.notifications,
              //                                           size: 16,
              //                                         )),
              //                                     const SizedBox(
              //                                       width: 5,
              //                                     ),
              //                                     Text(
              //                                       myTeamLead.teamName,
              //                                       style: PingStyles.watchStyle
              //                                           .copyWith(
              //                                               fontWeight:
              //                                                   FontWeight
              //                                                       .w600),
              //                                     ),
              //                                   ],
              //                                 ),
              //                                 Text(
              //                                   memberState.member!.name,
              //                                   style: PingStyles.watchStyle,
              //                                 )
              //                               ],
              //                             )
              //                           : Row(
              //                               children: [
              //                                 Expanded(
              //                                     child: Column(
              //                                   crossAxisAlignment:
              //                                       CrossAxisAlignment.start,
              //                                   children: [
              //                                     Row(
              //                                       children: [
              //                                         Text(
              //                                           myTeamLead.teamName,
              //                                           style: PingStyles
              //                                               .watchStyle
              //                                               .copyWith(
              //                                                   fontWeight:
              //                                                       FontWeight
              //                                                           .w600),
              //                                         ),
              //                                       ],
              //                                     ),
              //                                     Text(
              //                                       memberState.member!.name,
              //                                       style:
              //                                           PingStyles.watchStyle,
              //                                     )
              //                                   ],
              //                                 )),
              //                                 GestureDetector(
              //                                     onTap: () => push<String>(
              //                                           const NotificationView(
              //                                               mode: DashboardMode
              //                                                   .member),
              //                                         ),
              //                                     child: const Icon(
              //                                       Icons.notifications,
              //                                       size: 16,
              //                                     ))
              //                               ],
              //                             ),
              //                     ),
              //                     Expanded(
              //                       child: StreamBuilder<List<MemberModel>>(
              //                           stream: MemberRepo.instance.getMembers(
              //                             ofTeamLead: myTeamLead,
              //                             ifMemberId: ifMember?.id,
              //                             myMemberName: ifMember?.name ?? "",
              //                           ),
              //                           builder: (context, snap) {
              //                             if (snap.hasError) {
              //                               return getErrorMessage(
              //                                   context, snap.error);
              //                             }
              //                             final data = snap.data;
              //                             if (data == null) {
              //                               return getLoader();
              //                             }
              //                             if (data.isEmpty && !isMember) {
              //                               return getErrorMessage(context,
              //                                   't_noMembersFound'.tr());
              //                             }
              //                             final operationsBlocked =
              //                                 (20) <= data.length;
              //                             final members = data
              //                                 .where(
              //                                     (member) => !member.isBlocked)
              //                                 .toList();
              //                             int numberOfOnlineMembersForTL =
              //                                 members
              //                                     .where((member) =>
              //                                         member.isOnline)
              //                                     .toList()
              //                                     .length;
              //                             int numberOfOnlineMembers = 0;
              //                             if (isMember) {
              //                               numberOfOnlineMembers = members
              //                                   .where(
              //                                       (member) => member.isOnline)
              //                                   .where((member) =>
              //                                       member.id !=
              //                                       memberState.member!.id)
              //                                   .toList()
              //                                   .length;
              //                               if (myTeamLead.isOnline == true) {
              //                                 numberOfOnlineMembers++;
              //                               }
              //                             }
              //                             final blockedMembers = data
              //                                 .where(
              //                                     (member) => member.isBlocked)
              //                                 .toList();
              //                             final sortIds = memberState.idOrder;
              //                             if (sortIds != null) {
              //                               final availIds = sortIds
              //                                   .where((id) => members
              //                                       .any((m) => m.id == id))
              //                                   .toList();
              //                               members.sort(
              //                                 (a, b) =>
              //                                     availIds.indexOf(a.id) -
              //                                     availIds.indexOf(b.id),
              //                               );
              //                               members.sort(
              //                                 (a, b) => availIds.contains(a.id)
              //                                     ? -1
              //                                     : availIds.contains(b.id)
              //                                         ? 1
              //                                         : 0,
              //                               );
              //                             }
              //                             members.removeWhere((m) =>
              //                                 m.id == memberState.member?.id);
              //                             members.insert(
              //                                 0,
              //                                 MemberModel.fromPingUserModel(
              //                                     memberState.teamLead!));
              //                             return WatchShape(
              //                                 builder: (context, shape, _) {
              //                               return ReorderableGridView.builder(
              //                                 padding: EdgeInsets.only(
              //                                     top: 10,
              //                                     left: shape == WearShape.round
              //                                         ? 10
              //                                         : 0,
              //                                     right:
              //                                         shape == WearShape.round
              //                                             ? 10
              //                                             : 0),
              //                                 shrinkWrap: true,
              //                                 itemCount: members.length,
              //                                 gridDelegate:
              //                                     SliverGridDelegateWithFixedCrossAxisCount(
              //                                         crossAxisCount: 2,
              //                                         childAspectRatio: shape ==
              //                                                 WearShape.square
              //                                             ? 1.20
              //                                             : 1.5,
              //                                         mainAxisSpacing: 10,
              //                                         crossAxisSpacing: 10),
              //                                 itemBuilder: (context, index) =>
              //                                     WatchMemberListTile(
              //                                       key: ValueKey(members[index].id),
              //                                   isTeamLeader:
              //                                       index == 0 ? true : false,
              //                                   member: members[index],
              //                                   currentUser:
              //                                       memberState.member!,
              //                                 ),
              //                                 onReorder:
              //                                     (int oldIndex, int newIndex) {
              //                                   final currentIds = members
              //                                       .where((e) =>
              //                                           e.id !=
              //                                           memberState.member!.id)
              //                                       .map((e) => e.id)
              //                                       .toList();
              //                                   memberState.reorderIdOrder(
              //                                       currentIds,
              //                                       oldIndex,
              //                                       newIndex,
              //                                       memberState.member?.id ?? ''
              //                                   );
              //                                 },
              //                               );
              //                             });
              //                           }),
              //                     )
              //                   ],
              //                 ),
              //               ));
              //     },
              //   )
          DefaultTabController(
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
        ),
      ),
    );
  }
}
