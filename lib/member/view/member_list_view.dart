import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/repo/ping_auth_state.dart';
import 'package:ping_app/dashboard/dashboard_mode.dart';
import 'package:ping_app/member/repo/member_state.dart';
import 'package:ping_app/member/view/add_member_view/member_manage_view.dart';
import 'package:ping_app/member/model/member_model.dart';
import 'package:ping_app/member/repo/member_repo.dart';
import 'package:ping_app/member/view/member_list_item.dart';
import 'package:ping_app/subscription/model/subscription_model.dart';
import 'package:ping_app/subscription/repo/subscription_state.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
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

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<PingAuthState>();
    final memberState = context.watch<MemberState>();
    final subscriptionState = context.watch<SubscriptionState>();

    final mode = widget.mode;
    final isTeamLead = mode.isTeamLead;
    final isMember = mode.isMember;

    final myTeamLead = isTeamLead ? authState.currentPingUser : memberState.teamLead;

    final ifMember = memberState.member;
    if (isMember && ifMember == null) {
      return getErrorMessage(
        context,
        't_memberNotTheApp'.tr(),
      );
    }

    if (myTeamLead == null) {
      return getErrorMessage(context, 't_teamLeadTheApp'.tr());
    }
    print("..............${ifMember?.isBlocked}");
    return Scaffold(
      appBar: AppBar(
        title: Text(isMember ? ifMember!.name : 't_myTeam'.tr()),
        actions: [
          if (mode.isTeamLead)
            TextButton.icon(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() => loading = true);
                      final subType = subscriptionState.subscriptionType;

                      try {
                        final numberOfMembers = await MemberRepo.instance.getMemberCount(myTeamLead.userId);
                        if (numberOfMembers >= subType.maxMembersAllowed) {
                          snack(
                            't_youHaveMembersAllowed'.tr(),
                          );
                          return;
                        }
                        push(const MemberManageView());
                      } catch (e) {
                        snack(e);
                      }
                      setState(() => loading = false);
                    },
              icon: const Icon(Icons.add),
              label: Text('t_addMembers'.tr()),
            ),
          if (mode.isMember)
            TextButton.icon(
              onPressed: () => memberState.leaveTeam(),
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
          final operationsBlocked = (subscriptionState.subscriptionType.maxMembersAllowed) <= data.length;

          final members = data.where((member) => !member.isBlocked).toList();
          print("This is members: ${members.map((e) => e.isOnline).toList()}");

          int numberOfOnlineMembers = members.where((member) => member.isOnline).toList().length;
          if (isMember) {
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
            //send members with id not in sortIds to end
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
              getTeamCard(myTeamLead.teamName, numberOfOnlineMembers),
              Expanded(
                child: Column(children: [
                  if (isTeamLead)
                    Padding(
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
                    ),
                  if (isMember)
                    MemberListItem(
                      operationsBlocked: operationsBlocked,
                      isLoggedInAsMember: isMember,
                      currentUserModel: isMember ? ifMember! : MemberModel.fromPingUserModel(myTeamLead),
                      listTimeMemberModel: MemberModel.fromPingUserModel(myTeamLead),
                    ),
                  const Divider(),
                  Expanded(
                    child: showBlocked
                        ? ListView(
                            children: blockedMembers
                                .map((member) => MemberListItem(
                                      operationsBlocked: operationsBlocked,
                                      key: ValueKey(member.id),
                                      isLoggedInAsMember: isMember,
                                      currentUserModel:
                                          isMember ? ifMember! : MemberModel.fromPingUserModel(myTeamLead),
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
                                print("team lead members: name ${member.name} status ${member.isOnline}");
                                return MemberListItem(
                                  operationsBlocked: operationsBlocked,
                                  key: ValueKey(member.id),
                                  reOrderAble: true,
                                  isLoggedInAsMember: isMember,
                                  currentUserModel: isMember ? ifMember! : MemberModel.fromPingUserModel(myTeamLead),
                                  listTimeMemberModel: member,
                                );
                              },
                            ).toList()),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget getTeamCard(String teamName, int onlineCount) {
    return Builder(
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(teamName, style: Theme.of(context).textTheme.bodyLarge),
            Text("${'t_online'.tr()} ($onlineCount)", style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
