import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ping_app/member/model/member_model.dart';
import 'package:ping_app/member/repo/member_repo.dart';
import 'package:ping_app/member/repo/member_state.dart';
import 'package:ping_app/member/view/add_member_view/member_manage_view.dart';
import 'package:ping_app/member/view/add_member_view/member_qr_code.dart';
import 'package:ping_app/notification/model/ping_notification_model.dart';
import 'package:ping_app/notification/repo/notification_repo.dart';
import 'package:ping_app/services/notification_service.dart';
import 'package:ping_app/util/audio/ping_audio_record.dart';
import 'package:ping_app/util/audio/verify_audio_view.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:ping_app/util/ping_styles.dart';
import 'package:ping_app/util/ping_utils.dart';
import 'package:ping_app/util/record_web/audio_main.dart';
import 'package:ping_app/view/settings/view/sub_view/message_template/message_template_list.dart';
import 'package:ping_app/widgets/ping_list_tile.dart';
import 'package:provider/provider.dart';


class MemberListItem extends StatefulWidget {
  final bool isLoggedInAsMember;
  final MemberModel currentUserModel;
  final MemberModel listTimeMemberModel;
  final bool reOrderAble;
  final bool operationsBlocked;
  final bool viewOnly;

  const MemberListItem({
    super.key,
    required this.isLoggedInAsMember,
    required this.currentUserModel,
    required this.listTimeMemberModel,
    required this.operationsBlocked,
    this.reOrderAble = false,
    this.viewOnly = false,
  });

  @override
  State<MemberListItem> createState() => _MemberListItemState();
}

class _MemberListItemState extends State<MemberListItem> {
  PingNotificationModel? recentNotification;
  StreamSubscription? notificationSubscription;



  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      Provider.of<MemberState>(context, listen: false).loadMemberIdFromPrefs();
      await loadRecentNotification();
    });
  }



  Future<void> loadRecentNotification() async {
    if (notificationSubscription != null) {
      await notificationSubscription?.cancel();
    }

    notificationSubscription = NotificationRepo.instance
        .getMostRecentNotificationFromMeToId(widget.currentUserModel.id, widget.listTimeMemberModel.id)
        .listen((notification) {
      final nextTick = notification?.nextTick();
      // PingLog.pingLog("nextTick: $nextTick");
      if (nextTick != null) {
        Future.delayed(nextTick, () => loadRecentNotification());
      }
      if (mounted) {
        setState(() {
          recentNotification = notification;
        });
      }
    });
  }

  @override
  void dispose() {
    notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.listTimeMemberModel.memberColor;
    return Container(
      height: (context.isWatch) ? 32 : null,
      margin: EdgeInsets.symmetric(
        vertical: (context.isWatch) ? 4.0 : 16,
        horizontal: (kIsWeb) ? 0.0 : 16,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: (recentNotification?.toId == widget.listTimeMemberModel.id)
            ? recentNotification?.color ?? Colors.transparent
            : Colors.transparent,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.isWatch ? 6 :  12.0),
                    child: Text(
                      widget.listTimeMemberModel.initials,
                      style: (context.isWatch)
                          ? PingStyles.watchStyle
                          : Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding:  EdgeInsets.symmetric(horizontal: context.isWatch ? 8 : 24, vertical: 8) -
                      (widget.reOrderAble ? const EdgeInsets.only(left: 8) : EdgeInsets.zero),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.reOrderAble)
                            Icon(
                              Icons.drag_indicator,
                              color: Colors.grey,
                              size: (context.isWatch) ? PingStyles.watchIconSize : null,
                            ),
                          SizedBox(width: (context.isWatch) ? null : 8),
                          // if (widget.listTimeMemberModel.isOnline && !widget.listTimeMemberModel.isBlocked)
                          //   const Padding(
                          //     padding: EdgeInsets.only(right: 8.0),
                          //     child: Icon(Icons.circle, color: Colors.green, size: 12),
                          //   ),
                          Text(
                            widget.listTimeMemberModel.name,
                            style: (context.isWatch) ? PingStyles.watchStyle : null,
                          ),
                        ],
                      ),
                      if (!widget.viewOnly)
                        (context.isWatch)
                            ? GestureDetector(
                                onTap: () {
                                  showMemberOptions(
                                    context,
                                    widget.isLoggedInAsMember,
                                    widget.currentUserModel,
                                    widget.listTimeMemberModel,
                                  );
                                },
                                child: Icon(
                                  Icons.more_horiz,
                                  size: (context.isWatch) ? PingStyles.watchIconSize : null,
                                ),
                              )
                            : IconButton(
                                onPressed: () {
                                  showMemberOptions(
                                    context,
                                    widget.isLoggedInAsMember,
                                    widget.currentUserModel,
                                    widget.listTimeMemberModel,
                                  );
                                },
                                icon: const Icon(Icons.more_horiz),
                              )
                      else
                        const SizedBox(height: 40)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showMemberOptions(BuildContext context, bool isMember, MemberModel me, MemberModel selected) {
    showBottomSheet(
      context: context,
      enableDrag: false,
      builder: (context) => BottomSheet(
        enableDrag: false,
        elevation: 8,
        constraints: const BoxConstraints(maxHeight: 450),
        onClosing: () {
          PingLog.pingLog("on closing");
        },
        builder: (context) {
          return Consumer<MemberState>(
            builder: (context, memberState, _) {
              // final member = memberState.member;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: (context.isWatch)
                            ? InkWell(
                                onTap: () {
                                  pop();
                                },
                                child: Icon(
                                  Icons.close,
                                  size: PingStyles.watchIconSize,
                                ),
                              )
                            : IconButton(
                                onPressed: () {
                                  pop();
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    // if (widget.operationsBlocked)
                    //   Padding(
                    //     padding: const EdgeInsets.all(16.0),
                    //     child: getErrorMessage(
                    //       context,
                    //       "You have more members than allowed. Please upgrade your plan or delete some members.",
                    //     ),
                    //   ),
                    if (!widget.operationsBlocked)
                      if (!selected.isBlocked)
                        PingListTile(
                          iconData: Icons.phonelink_ring,
                          title: "t_ping".tr(),
                          onTap: () async {
                            final res = await isMemberBlocked(widget.currentUserModel.id);
                            pop();
                            if (res) {
                              snack("t_blockMemberCantSendPing".tr(), info: false);
                            } else {
                              if (context.mounted) {
                                bool confirmation = await context.showConfirmationDialog(
                                      title: "t_sendPing".tr(),
                                      type: "Ping",
                                    ) ??
                                    false;
                                if (confirmation) {
                                  final data = await NotificationRepo.instance.sendPingNotification(me, selected);

                                  final res = await FirebaseNotificationService().sendNotification(
                                    messageData: data.data ?? "",
                                    type: "0",
                                    id: data.id,
                                    title: "Ping",
                                    body: "${me.name} ${'t_sentAPing'.tr()}",
                                    tokens: selected.fcm,
                                    fromId: me.id,
                                    toId: selected.id,
                                  );
                                  if (res) {
                                    snack("t_pingSentSuccessfully".tr(), info: true);
                                  }
                                } else {
                                  snack("t_pingSendingCancelled".tr());
                                }
                              }
                            }
                          },
                        ),
                    if (!widget.operationsBlocked)
                      if (!selected.isBlocked)
                        PingListTile(
                          iconData: Icons.message,
                          title: "t_message".tr(),
                          onTap: () async {
                            final res = await isMemberBlocked(widget.currentUserModel.id);
                            pop();
                            if (res) {
                              snack("t_blockMemberCantSendMessage".tr(), info: false);
                            } else {
                              String? message = await push<String>(const MessageListView(pickMessageMode: true));

                              if (message != null ){
                                bool confirmation = await context.showConfirmationDialog(
                                      title: "t_sendMessage".tr(),
                                      message: message,
                                      type: "Message",
                                    ) ??
                                    false;
                                if (confirmation) {
                                  final data =
                                      await NotificationRepo.instance.sendMessageNotification(me, selected, message);
                                  final res = await FirebaseNotificationService().sendNotification(
                                    messageData: data.data ?? "",
                                    type: "1",
                                    id: data.id,
                                    title: "Message",
                                    body: "${me.name} ${'t_sentYouAMessage'.tr()}",
                                    tokens: selected.fcm,
                                    fromId: me.id,
                                    toId: selected.id,
                                  );
                                  if (res) {
                                    snack("t_messageSentSuccessfully".tr(), info: true);
                                  }
                                } else {
                                  snack("t_messageSendingCancelled".tr());
                                }
                              }
                            }
                          },
                        ),
                    if (!widget.operationsBlocked)
                      if (!selected.isBlocked)
                        PingListTile(
                          iconData: Icons.mic,
                          title: "t_audioMessage".tr(),
                          onTap: () async {
                            if (kIsWeb) {
                              final data = await push<Uint8List?>(const AudioRecordWeb());
                              if (data != null) {
                                pop();
                                final audioInfo = await NotificationRepo.instance.sendDataAudioNotification(me, selected, data);
                                // Send FCM push
                                final res = await FirebaseNotificationService().sendNotification(
                                  messageData: audioInfo.data,
                                  type: "2",
                                  id: audioInfo.id,
                                  title: "Audio Message",
                                  body: "${me.name} ${'t_sentYouAudioMessage'.tr()}",
                                  tokens: selected.fcm,
                                  fromId: me.id,
                                  toId: selected.id,
                                );
                                if (res) {
                                  snack("t_messageSentSuccessfully".tr(), info: true);
                                }
                              }
                              return;
                            }
                            final file = await push<File>(const PingAudioRecord());
                            if (file == null) {
                              return;
                            }
                            final send = await push<bool>(VerifyAudioView(audioFile: file));
                            if (send ?? false) {
                              pop();
                              final data = await NotificationRepo.instance.sendAudioNotification(me, selected, file);
                              final res = await FirebaseNotificationService().sendNotification(
                                messageData: data.data ?? "",
                                type: "2",
                                id: data.id,
                                title: "Audio Message",
                                body: "${me.name} ${'t_sentYouAudioMessage'.tr()}",
                                tokens: selected.fcm,
                                fromId: me.id,
                                toId: selected.id,
                              );
                              if (res) {
                                snack("t_messageSentSuccessfully".tr(), info: true);
                              }
                            }
                          },
                        ),
                    if (!widget.operationsBlocked)
                      if (!isMember)
                        PingListTile(
                          iconData: Icons.edit,
                          title: "t_updateMember".tr(),
                          onTap: () {
                            pop();
                            push(MemberManageView(member: selected));
                          },
                        ),
                    if (!widget.operationsBlocked)
                      PingListTile(
                        iconData: Icons.qr_code,
                        title: "t_viewQRCode".tr(),
                        onTap: () {
                          pop();
                          push(MemberQrCode(memberId: selected.id));
                        },
                      ),
                    if (!widget.operationsBlocked)
                      if (!isMember)
                        PingListTile(
                          iconData: selected.isBlocked ? Icons.lock_open : Icons.block,
                          title: selected.isBlocked ? "t_unblockMember".tr() : "t_blockMember".tr(),
                          onTap: () async {
                            pop();
                            bool checkInternet = await context.isInternetAvailable();
                            if (checkInternet) {
                              MemberRepo.instance
                                  .blockUnblockMember(selected.id, !selected.isBlocked)
                                  .catchError((error) => snack(error));
                            } else {
                              if (context.mounted) {
                                snack(context.pingString("t_noInternetPleaseConnectToTheInternet"));
                              }
                            }
                          },
                        ),
                    if (!isMember)
                      PingListTile(
                        iconData: Icons.remove_circle,
                        iconColor: Colors.red,
                        title: "t_removeMember".tr(),
                        textColor: Colors.red,
                        onTap: () {
                          pop();
                          sureDialog(
                            context: context,
                            title: "t_removeMember".tr(),
                            message: "${"t_areYouSureYouWantToRemove".tr()} ${selected.name}",
                            onYes: () async {
                              bool isInternet = await context.isInternetAvailable();
                              if (isInternet) {
                                MemberRepo.instance.removeMember(selected.id).catchError((error) => snack(error));
                              } else {
                                snack("t_noInternetPleaseConnectToTheInternet".tr());
                              }
                            },
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<bool> isMemberBlocked(String memberId) async {
  try {
    final memberDoc = await FirebaseFirestore.instance.collection("members").doc(memberId).get();
    if (memberDoc.exists) {
      return memberDoc.data()?['isBlocked'] ?? false;
    } else {
      return false;
    }
  } catch (e) {
    PingLog.pingLog("Error checking member block status: $e");
    return false;
  }
}
