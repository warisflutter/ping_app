import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/repo/ping_auth_state.dart';
import 'package:ping_app/member/repo/member_state.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:ping_app/util/ping_styles.dart';
import 'package:ping_app/util/ping_utils.dart';
import 'package:ping_app/view/admin/admin_provider.dart';
import 'package:ping_app/view/settings/repo/setting_repo.dart';
import 'package:ping_app/view/settings/view/sub_view/message_template/message_add_edit_view.dart';
import 'package:ping_app/view/subscription/subscription_info_view.dart';
import 'package:ping_app/view/subscription/subscription_provider.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
// import 'package:wear_plus/wear_plus.dart';

class MessageListView extends StatefulWidget {
  final bool pickMessageMode;

  const MessageListView({super.key, this.pickMessageMode = false});

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
  bool loading = false;
  PageController controller = PageController();


  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
      appBar: context.isWatch ? null : AppBar(
          title: Text(
        't_messageTemplates'.tr(),
        // style: (context.isWatch) ? PingStyles.watchStyle : null,
      )),
      body: Consumer<SubscriptionProvider>(builder: (context, subscriptionProvider, _) {
        return Stack(
          children: [
            // if(context.isWatch)
            // WatchShape(
            //   builder: (context, shape, _) => shape == WearShape.square ? Positioned(
            //       left: 8,
            //       top: 8,
            //       child: GestureDetector(
            //           onTap: () => Navigator.pop(context),
            //           child: const Icon(Icons.arrow_back, size: 16,)))
            //       : Positioned(
            //       left: 8,
            //       top: 8,
            //       right: 8,
            //       child: GestureDetector(
            //           onTap: () => Navigator.pop(context),
            //           child: const Icon(Icons.arrow_back, size: 16,)))
            // ),
            Positioned(
                left: 8,
                top: 8,
                child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 16,))),
            SafeArea(
              child: LayoutBuilder(builder: (context, constraints) {
                double maxWidth = constraints.maxWidth > 800 ? 200.0 : 16.0;
                return Padding(
                  padding: (kIsWeb)
                      ? EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: maxWidth,
                        )
                      : const EdgeInsets.all(16.0),
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

                              return context.isWatch ? Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: SizedBox(
                                      height: MediaQuery.sizeOf(context).height / 1.8,
                                      width: MediaQuery.sizeOf(context).width,
                                      child: PageView(
                                        controller: controller,
                                        children: messages.map((m) => InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: widget.pickMessageMode ? () => pop(data: m) : null,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white54,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            margin: const EdgeInsets.only(right: 5),
                                            child: Center(child: Text(m, textAlign: TextAlign.center, style: PingStyles.watchStyle,)),
                                          ),
                                        )).toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8,),
                                  SmoothPageIndicator(
                                      controller: controller,  // PageController
                                      count:  messages.length,
                                      effect:  WormEffect(
                                        dotWidth: 8,
                                        dotHeight: 8,
                                        dotColor: Colors.grey.withValues(alpha: 0.5),
                                        activeDotColor: Colors.white
                                      ),  // your preferred effect
                                      onDotClicked: (index){
                                        controller.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                      }
                                  )
                                ],
                              ) : _buildList(messages);
                            }),
                      ),
                      if (!widget.pickMessageMode)
                        (context.screenHeight < 120)
                            ? const SizedBox.shrink()
                            : SizedBox(
                                height: (context.isWatch) ? PingStyles.watchButtonHeight : null,
                                width: double.infinity,
                                child: ElevatedButton(
                                  key: const Key("buttonAddMessage"),
                                  onPressed: () async {
                                    final isConnected = await context.isInternetAvailable();
                                    if (isConnected) {
                                      // subscriptionProvider.init();
                                      final numberOfMessages = await SettingRepo.instance.getMessageCount();
                                      if (subscriptionProvider.purChasedModel == null) {
                                        if (context.mounted) {
                                          final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                                          final voucherData = await adminProvider.fetchVoucher();
                                          if (voucherData.isEmpty) {
                                            if (!context.mounted) return;
                                            if (kIsWeb || context.isWatch) {
                                              snack("You need to buy subscription from mobile app.");
                                            } else {
                                              push(const SubscriptionInfoView());
                                            }
                                          } else {
                                            subscriptionProvider.handleVoucherType(
                                              voucherData: voucherData,
                                              numberOfMembers: numberOfMessages,
                                              type: "message",
                                            );
                                          }
                                        }
                                      } else {
                                        PingLog.pingLog("purChasedModel is not null");
                                        subscriptionProvider.handleSubscription(
                                          numberOfMembers: numberOfMessages,
                                          type: "message",
                                        );
                                      }
                                    } else {
                                      snack("t_noInternetPleaseConnectToTheInternet".tr());
                                    }
                                  },
                                  child: Text(
                                    't_addMessage'.tr(),
                                    style: (context.isWatch) ? PingStyles.watchStyle : null,
                                  ),
                                ),
                              ),
                    ],
                  ),
                );
              }),
            ),
            if (loading)
              Positioned.fill(
                child: AbsorbPointer(
                  absorbing: true,
                  child: Container(
                    color: Colors.black.withValues(alpha: .5),
                    child: getLoader(),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildList(List<String> messages) {
    print("widget.pickMessageMode${widget.pickMessageMode}");
    buildMessages() => messages
        .map(
          (message) => (!context.isWatch)
              ? ListTile(
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
                                onYes: () async {
                                  final isConnected = await context.isInternetAvailable();
                                  if (isConnected) {
                                    deleteAction(message);
                                  } else {
                                    snack("t_noInternetPleaseConnectToTheInternet".tr());
                                  }
                                },
                              ),
                            ),
                            const Icon(Icons.drag_indicator),
                          ],
                        ),
                )
              : Padding(
                  padding: EdgeInsets.all((context.isWatch) ? 8.0 : 16.0),
                  child: InkWell(
                    // key: ValueKey(message),
                    onTap: widget.pickMessageMode ? () => pop(data: message) : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          message,
                          style: (context.isWatch) ? PingStyles.watchStyle : null,
                        ),
                        widget.pickMessageMode
                            ? const SizedBox()
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  InkWell(
                                    key: const Key("editButton"),
                                    child: Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                      size: PingStyles.watchIconSize,
                                    ),
                                    onTap: () => push(
                                      MessageAddEditView(originalMessage: message),
                                    ),
                                  ),
                                  InkWell(
                                    key: const Key("keyDeleteButton"),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: PingStyles.watchIconSize,
                                    ),
                                    onTap: () => sureDialog(
                                      title: 't_deleteTemplate'.tr(),
                                      message: 't_areYouThisTemplate'.tr(),
                                      context: context,
                                      onYes: () async {
                                        final isConnected = await context.isInternetAvailable();
                                        if (isConnected) {
                                          deleteAction(message);
                                        } else {
                                          snack("t_noInternetPleaseConnectToTheInternet".tr());
                                        }
                                      },
                                    ),
                                  ),
                                  Icon(
                                    Icons.drag_indicator,
                                    size: PingStyles.watchIconSize,
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
        )
        .toList();
    return (widget.pickMessageMode || context.isWatch)
        ? ListView(
            children: buildMessages(),
          )
        : ReorderableListView(
            // buildDefaultDragHandles: false,
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
