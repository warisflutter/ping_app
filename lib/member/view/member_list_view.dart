import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ping_app/auth/repo/app_lifecycle_service.dart';
import 'package:ping_app/auth/repo/ping_auth_state.dart';
import 'package:ping_app/auth/view/create_account_view.dart';
import 'package:ping_app/dashboard/dashboard_mode.dart';
import 'package:ping_app/member/repo/member_state.dart';
import 'package:ping_app/member/model/member_model.dart';
import 'package:ping_app/member/repo/member_repo.dart';
import 'package:ping_app/member/view/member_list_item.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:ping_app/util/ping_utils.dart';
import 'package:ping_app/view/admin/admin_provider.dart';
import 'package:ping_app/view/subscription/subscription_info_view.dart';
import 'package:ping_app/view/subscription/subscription_provider.dart';
import 'package:ping_app/view/voucher/voucher_provider.dart';
import 'package:ping_app/watch_os/watch_repo.dart';
import 'package:provider/provider.dart';

class MemberListView extends StatefulWidget {
  final DashboardMode mode;

  const MemberListView({
    super.key,
    required this.mode,
  });

  @override
  State<MemberListView> createState() => _MemberListViewState();
}

class _MemberListViewState extends State<MemberListView> {
  bool showBlocked = false;
  bool loading = false;
  late SubscriptionProvider subscriptionProvider;

  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(builder: (context, subscriptionProvider, _) {
      final authState = context.watch<PingAuthState>();
      final memberState = context.watch<MemberState>();
      final mode = widget.mode;
      final isTeamLead = mode.isTeamLead;
      final isMember = mode.isMember;
      final myTeamLead = isTeamLead ? authState.currentPingUser : memberState.teamLead;
      final ifMember = memberState.member;
      if (isMember && ifMember == null) {
        return getErrorMessage(context, "");
      }
      if (myTeamLead == null) {
        return getErrorMessage(context, "");
      }
      return Scaffold(
        appBar: AppBar(
          title: Text(isMember ? ifMember?.name ?? "" : 't_myTeam'.tr()),
          actions: [
            if (mode.isTeamLead)
              TextButton.icon(
                onPressed: () async {
                  final isConnected = await context.isInternetAvailable();
                  if (isConnected) {
                    // subscriptionProvider.init();
                    final numberOfMembers = await MemberRepo.instance.getMemberCount(myTeamLead.userId);
                    if (subscriptionProvider.purChasedModel == null) {
                      PingLog.pingLog("purChasedModel is null");
                      if (context.mounted) {
                        final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                        final voucherData = await adminProvider.fetchVoucher();
                        // log("voucherData $voucherData");
                        if (voucherData.isEmpty) {
                          // if (!context.mounted) return;
                          // if (kIsWeb || context.isWatch) {
                          //   snack("you need to buy subscription from mobile app");
                          // } else {
                          push(const SubscriptionInfoView());
                          // }
                        } else {
                          subscriptionProvider.handleVoucherType(
                            voucherData: voucherData,
                            numberOfMembers: numberOfMembers,
                            type: "",
                          );
                        }
                      }
                    } else {
                      PingLog.pingLog("purChasedModel is not null");
                      subscriptionProvider.handleSubscription(
                        numberOfMembers: numberOfMembers,
                        type: "",
                      );
                    }
                  } else {
                    snack("t_noInternetPleaseConnectToTheInternetToViewSubscriptionPlans".tr());
                  }
                },
                icon: const Icon(Icons.add),
                label: Text('t_addMembers'.tr()),
              ),
            if (mode.isMember)
              TextButton.icon(
                onPressed: () {
                  AppLifecycleService().reset();
                  memberState.leaveTeam();
                  replaceAll(const CreateAccountView());
                },
                label: Text('t_leaveTeam'.tr()),
                icon: const Icon(Icons.exit_to_app),
              ),
          ],
        ),
        body: StreamBuilder<List<MemberModel>>(
          stream: MemberRepo.instance.getMembers(
            ofTeamLead: myTeamLead,
            ifMemberId: ifMember?.id,
          ),
          builder: (context, snap) {
            if (snap.hasError) {
              return getErrorMessage(context, snap.error);
            }
            final data = snap.data;
            if (data == null) {
              return getLoader();
            }
            if (data.isEmpty && !isMember) {
              return getErrorMessage(context, 't_noMembersFound'.tr());
            }
            final operationsBlocked = (20) <= data.length;
            final members = data.where((member) => !member.isBlocked).toList();
            int numberOfOnlineMembersForTL = members.where((member) => member.isOnline).toList().length;
            int numberOfOnlineMembers = 0;
            if (isMember) {
              numberOfOnlineMembers = members
                  .where((member) => member.isOnline)
                  .where((member) => member.id != memberState.member!.id)
                  .toList()
                  .length;
              if (myTeamLead.isOnline == true) {
                numberOfOnlineMembers++;
              }
            }
            final blockedMembers = data.where((member) => member.isBlocked).toList();
            final sortIds = memberState.idOrder;
            if (sortIds != null) {
              final availIds = sortIds.where((id) => members.any((m) => m.id == id)).toList();
              members.sort(
                (a, b) => availIds.indexOf(a.id) - availIds.indexOf(b.id),
              );
              members.sort(
                (a, b) => availIds.contains(a.id)
                    ? -1
                    : availIds.contains(b.id)
                        ? 1
                        : 0,
              );
            }

            return Column(
              children: [
                getTeamCard(
                  numberOfOnlineMembers: mode.isTeamLead ? numberOfOnlineMembersForTL : numberOfOnlineMembers,
                  teamName: myTeamLead.teamName,
                ),
                Expanded(
                  child: Column(
                    children: [
                      (isTeamLead)
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ChoiceChip(
                                    label: Text("${'t_members'.tr()} (${members.length})"),
                                    selected: !showBlocked,
                                    onSelected: (selected) => setState(() => showBlocked = false),
                                  ),
                                  const SizedBox(width: 16),
                                  ChoiceChip(
                                    label: Text("${'t_blocked'.tr()} (${blockedMembers.length})"),
                                    selected: showBlocked,
                                    onSelected: (selected) => setState(() => showBlocked = true),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                      (isMember)
                          ? MemberListItem(
                              operationsBlocked: operationsBlocked,
                              isLoggedInAsMember: isMember,
                              currentUserModel:
                                  isMember ? ifMember! : MemberModel.fromPingUserModel(myTeamLead),
                              listTimeMemberModel: MemberModel.fromPingUserModel(myTeamLead),
                            )
                          : const SizedBox.shrink(),
                      const Divider(),
                      Expanded(
                        child: (showBlocked)
                            ? ListView(
                                children: blockedMembers
                                    .map((member) => MemberListItem(
                                          operationsBlocked: operationsBlocked,
                                          key: ValueKey(member.id),
                                          isLoggedInAsMember: isMember,
                                          currentUserModel: isMember
                                              ? ifMember!
                                              : MemberModel.fromPingUserModel(myTeamLead),
                                          listTimeMemberModel: member,
                                        ))
                                    .toList(),
                              )
                            : ReorderableListView(
                                onReorder: (oldIndex, newIndex) {
                                  final currentIds = members.map((e) => e.id).toList();
                                  memberState.reorderIdOrder(currentIds, oldIndex, newIndex);
                                },
                                children: members.map(
                                  (member) {
                                    if (isMember) {
                                      if (ifMember?.name == member.name) {
                                        return KeyedSubtree(
                                          key: ValueKey("SizedBox-${member.id}"),
                                          child: const SizedBox.shrink(),
                                        );
                                      } else {
                                        return MemberListItem(
                                          operationsBlocked: operationsBlocked,
                                          key: ValueKey(member.id),
                                          reOrderAble: true,
                                          isLoggedInAsMember: isMember,
                                          currentUserModel: (isMember)
                                              ? ifMember!
                                              : MemberModel.fromPingUserModel(myTeamLead),
                                          listTimeMemberModel: member,
                                        );
                                      }
                                    } else {
                                      return MemberListItem(
                                        operationsBlocked: operationsBlocked,
                                        key: ValueKey(member.id),
                                        reOrderAble: true,
                                        isLoggedInAsMember: isMember,
                                        currentUserModel: (isMember)
                                            ? ifMember!
                                            : MemberModel.fromPingUserModel(myTeamLead),
                                        listTimeMemberModel: member,
                                      );
                                    }
                                  },
                                ).toList()),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  Widget getTeamCard({
    required String teamName,
    required int numberOfOnlineMembers,
  }) {
    return Consumer<MemberState>(
      builder: (context, memberState, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(teamName, style: Theme.of(context).textTheme.bodyLarge),
              // Text(
              //   "${'t_online'.tr()} ($numberOfOnlineMembers)",
              //   style: Theme.of(context).textTheme.bodyLarge,
              // ),
            ],
          ),
        );
      },
    );
  }
}
