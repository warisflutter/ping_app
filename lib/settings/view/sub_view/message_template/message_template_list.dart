import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ping_app/auth/repo/ping_auth_state.dart';
import 'package:ping_app/member/repo/member_state.dart';
import 'package:ping_app/settings/repo/setting_repo.dart';
import 'package:ping_app/settings/view/sub_view/message_template/message_add_edit_view.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:ping_app/view/subscription/subscription_info_view.dart';
import 'package:ping_app/view/subscription/subscription_provider.dart';
import 'package:ping_app/view/voucher/voucher_provider.dart';
import 'package:provider/provider.dart';

class MessageListView extends StatefulWidget {
  final bool pickMessageMode;

  const MessageListView({super.key, this.pickMessageMode = false});

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
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
    late String teamLeadId;
    final pingAuthState = context.watch<PingAuthState>();
    final pingUser = pingAuthState.currentPingUser;

    if (pingUser != null) {
      teamLeadId = pingUser.userId;
    } else {
      final memberState = context.watch<MemberState>();
      final userId = memberState.teamLead?.userId;
      if (userId != null) {
        teamLeadId = userId;
      } else {
        return getErrorMessage(context, "No user is logged in");
      }
    }

    return Scaffold(
      key: const Key("messageListView"),
      appBar: AppBar(title: Text('t_messageTemplates'.tr())),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<List<String>>(
                        stream: SettingRepo.instance.getMessages(teamLeadId),
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return getErrorMessage(context, snap.error);
                          }

                          final messages = snap.data;
                          if (messages == null) {
                            return getLoader();
                          }

                          if (messages.isEmpty) {
                            return Center(
                              key: const Key("emptyMessageList"),
                              child: Text('t_noMessageTemplates'.tr()),
                            );
                          }

                          return _buildList(messages);
                        }),
                  ),
                  if (!widget.pickMessageMode)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const Key("buttonAddMessage"),
                        onPressed: () async {
                          final numberOfMessages = await SettingRepo.instance.getMessageCount();
                          if (subscriptionProvider.purChasedModel == null) {
                            final voucherP = Provider.of<VoucherProvider>(context, listen: false);
                            String data = await voucherP.fetchVoucher();
                            if (data.isEmpty) {
                              push(const SubscriptionInfoView());
                              snack('you have buy onr subscription first to continue');
                            } else {
                              PingLog.pingLog("This is my fetchVoucher: $data");
                              String type = data.split("|")[1];
                              PingLog.pingLog("This is my type: $type");
                              if (type == "Basic") {
                                PingLog.pingLog("if (type == Basic) { $numberOfMessages");
                                if (numberOfMessages != 3) {
                                  push(const MessageAddEditView());
                                }
                              } else if (type == "Export") {
                                if (numberOfMessages != 5) {
                                  push(const MessageAddEditView());
                                }
                              } else if (type == "Pro") {
                                if (numberOfMessages != 20) {
                                  push(const MessageAddEditView());
                                }
                              }
                            }
                          } else {
                            int perMessages = subscriptionProvider.purChasedModel?.perUsersAndMessages ?? 0;

                            if (numberOfMessages == perMessages) {
                              snack('t_youHaveMessagesTemplate'.tr());
                            } else {
                              push(const MessageAddEditView());
                            }
                          }
                        },
                        child: Text('t_addMessage'.tr()),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (loading)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: getLoader(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList(List<String> messages) {
    buildMessages() => messages
        .map((message) => ListTile(
              key: ValueKey(message),
              title: Text(message),
              onTap: widget.pickMessageMode ? () => pop(data: message) : null,
              trailing: widget.pickMessageMode
                  ? const SizedBox()
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          key: const Key("editButton"),
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => push(
                            MessageAddEditView(originalMessage: message),
                          ),
                        ),
                        IconButton(
                          key: const Key("keyDeleteButton"),
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => sureDialog(
                            title: 't_deleteTemplate'.tr(),
                            message: 't_areYouThisTemplate'.tr(),
                            context: context,
                            onYes: () => deleteAction(message),
                          ),
                        ),
                        const Icon(Icons.drag_indicator),
                      ],
                    ),
            ))
        .toList();
    return widget.pickMessageMode
        ? ListView(children: buildMessages())
        : ReorderableListView(
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) => actionReordering(oldIndex, newIndex),
            children: buildMessages(),
          );
  }

  void deleteAction(String message) async {
    setState(() => loading = true);
    try {
      await SettingRepo.instance.removeMessage(message);
    } catch (e) {
      snack(e);
    }
    setState(() => loading = false);
  }

  void actionReordering(int oldIndex, int newIndex) async {
    setState(() => loading = true);
    try {
      await SettingRepo.instance.reorderMessages(oldIndex, newIndex);
    } catch (e) {
      snack(e);
    }
    setState(() => loading = false);
  }
}
