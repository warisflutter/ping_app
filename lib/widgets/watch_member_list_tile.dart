import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:googleapis/admob/v1.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/member/model/member_model.dart';
import 'package:provider/provider.dart';
import '../member/view/member_list_item.dart';
import '../notification/model/ping_notification_model.dart';
import '../notification/repo/notification_repo.dart';
import '../util/audio/ping_audio_record.dart';
import '../util/audio/verify_audio_view.dart';
import '../view/settings/view/sub_view/message_template/message_template_list.dart';

class WatchMemberListTile extends StatefulWidget {
  final bool isTeamLeader;
  final MemberModel member;
  final MemberModel currentUser;

  const WatchMemberListTile(
      {super.key,
      required this.isTeamLeader,
      required this.member,
      required this.currentUser});

  @override
  State<WatchMemberListTile> createState() => _WatchMemberListTileState();
}

class _WatchMemberListTileState extends State<WatchMemberListTile> {
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
        .getMostRecentNotificationFromMeToId(
            widget.currentUser.id, widget.member.id)
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
    final color = widget.member.memberColor;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        showAdaptiveDialog(
            context: context,
            builder: (_) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      WatchOptionItem(
                        onTap: () async {
                          final res = await isMemberBlocked(widget.member.id);
                          pop();
                          if (res) {
                            snack("t_blockMemberCantSendPing".tr(),
                                info: false);
                          } else {
                            if (context.mounted) {
                              bool confirmation =
                                  await context.showConfirmationDialog(
                                        title: "t_sendPing".tr(),
                                        type: "Ping",
                                      ) ??
                                      false;
                              if (confirmation) {
                                final data = await NotificationRepo.instance
                                    .sendPingNotification(
                                        widget.currentUser, widget.member);
                                final res = await FirebaseNotificationService()
                                    .sendNotification(
                                  messageData: data.data ?? "",
                                  type: "0",
                                  id: data.id,
                                  title: "Ping",
                                  body:
                                      "${widget.member.name} ${'t_sentAPing'.tr()}",
                                  tokens: widget.member.fcm,
                                  fromId: widget.currentUser.id,
                                  toId: widget.member.id,
                                );
                                if (res) {
                                  if(!context.mounted) return;
                                  dialog(true, context, "t_pingSentSuccessfully".tr());
                                  // snack("t_pingSentSuccessfully".tr(),
                                  //     info: true);
                                }
                              }
                            }
                          }
                        },
                        icon: Icons.phonelink_ring,
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      WatchOptionItem(
                        onTap: () async {
                          final res =
                              await isMemberBlocked(widget.currentUser.id);
                          pop();
                          if (res) {
                            snack("t_blockMemberCantSendMessage".tr(),
                                info: false);
                          } else {
                            String? message = await push<String>(
                                const MessageListView(pickMessageMode: true));

                            if (message != null && context.mounted) {
                              bool confirmation =
                                  await context.showConfirmationDialog(
                                        title: "t_sendMessage".tr(),
                                        message: message,
                                        type: "Message",
                                      ) ??
                                      false;
                              if (confirmation) {
                                final data = await NotificationRepo.instance
                                    .sendMessageNotification(widget.currentUser,
                                        widget.member, message);
                                final res = await FirebaseNotificationService()
                                    .sendNotification(
                                  messageData: data.data ?? "",
                                  type: "1",
                                  id: data.id,
                                  title: "Message",
                                  body:
                                      "${widget.currentUser.name} ${'t_sentYouAMessage'.tr()}",
                                  tokens: widget.member.fcm,
                                  fromId: widget.currentUser.id,
                                  toId: widget.member.id,
                                );
                                if (res) {
                                  if(!context.mounted) return;
                                  dialog(true, context, "t_messageSentSuccessfully".tr());
                                  // snack("t_messageSentSuccessfully".tr(),
                                  //     info: true);
                                }
                              }
                              // else {
                              //   snack("t_messageSendingCancelled".tr());
                              // }
                            }
                          }
                        },
                        icon: Icons.message,
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      WatchOptionItem(
                        onTap: () async {
                          final file = await push<File>(const PingAudioRecord());
                          if (file == null) {
                            return;
                          }
                          final send = await push<bool>(VerifyAudioView(audioFile: file));
                          if (send ?? false) {
                            pop();
                            final data = await NotificationRepo.instance.sendAudioNotification(widget.currentUser, widget.member, file);
                            var res = await FirebaseNotificationService().sendNotification(
                              messageData: data.data ?? "",
                              type: "2",
                              id: data.id,
                              title: "Audio Message",
                              body: "${widget.currentUser.name} ${'t_sentYouAudioMessage'.tr()}",
                              tokens: widget.member.fcm,
                              fromId: widget.currentUser.id,
                              toId: widget.member.id,
                            );
                            if (res) {
                              if(!context.mounted) return;
                              dialog(true, context, "t_messageSentSuccessfully".tr());
                            }
                          }
                        },
                        icon: Icons.mic,
                      ),
                    ],
                  ),
                ));
      },
      child: Container(
        decoration: BoxDecoration(
            color: (recentNotification?.toId == widget.member.id)
                    ? recentNotification?.color ?? Colors.transparent
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.isTeamLeader ? Colors.blueGrey : Colors.white, width: 1.2)),
        child: Center(
            child: Text(
          getInitials(widget.member.name),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
        )),
      ),
    );
  }

  String getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
    } else if (parts.length == 1 && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }
}

class WatchOptionItem extends StatelessWidget {
  final IconData icon;
  final void Function() onTap;

  const WatchOptionItem({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          height: 30,
          decoration: BoxDecoration(
              color: Colors.grey, borderRadius: BorderRadius.circular(6)),
          child: Center(
            child: Icon(icon),
          ),
        ),
      ),
    );
  }
}









