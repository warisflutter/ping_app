import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/member/model/member_model.dart';
import 'package:ping_app/member/repo/member_repo.dart';
import 'package:ping_app/member/view/add_member_view/member_manage_view.dart';
import 'package:ping_app/member/view/add_member_view/member_qr_code.dart';
import 'package:ping_app/notification/model/ping_notification_model.dart';
import 'package:ping_app/notification/repo/notification_repo.dart';
import 'package:ping_app/settings/view/sub_view/message_template/message_template_list.dart';
import 'package:ping_app/util/audio/ping_audio_record.dart';
import 'package:ping_app/util/audio/verify_audio_view.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/record_web/audio_main.dart';

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
    loadRecentNotification();
    super.initState();
  }

  Future<void> loadRecentNotification() async {
    if (notificationSubscription != null) {
      await notificationSubscription?.cancel();
    }
    notificationSubscription = NotificationRepo.instance
        .getMostRecentNotificationFromMeToId(
            widget.currentUserModel.id, widget.listTimeMemberModel.id)
        .listen((notification) {
      final nextTick = notification?.nextTick();
      if (nextTick != null) {
        Future.delayed(nextTick, () => loadRecentNotification());
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => recentNotification = notification);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.listTimeMemberModel.memberColor;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: recentNotification?.toId == widget.listTimeMemberModel.id
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
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    widget.listTimeMemberModel.initials,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                )),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8) -
                          (widget.reOrderAble
                              ? const EdgeInsets.only(left: 8)
                              : EdgeInsets.zero),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.reOrderAble)
                            const Icon(
                              Icons.drag_indicator,
                              color: Colors.grey,
                            ),
                          const SizedBox(width: 8),
                          if (widget.listTimeMemberModel.isOnline &&
                              !widget.listTimeMemberModel.isBlocked)
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.circle,
                                  color: Colors.green, size: 12),
                            ),
                          Text(widget.listTimeMemberModel.name),
                        ],
                      ),
                      if (!widget.viewOnly)
                        IconButton(
                          onPressed: () => showMemberOptions(
                            context,
                            widget.isLoggedInAsMember,
                            widget.currentUserModel,
                            widget.listTimeMemberModel,
                          ),
                          icon: const Icon(Icons.more_horiz),
                        )
                      else
                        SizedBox(height: 40)
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

  void showMemberOptions(BuildContext context, bool isMember, MemberModel me,
      MemberModel selected) {
    showBottomSheet(
      context: context,
      enableDrag: false,
      builder: (context) => BottomSheet(
        enableDrag: false,
        elevation: 8,
        constraints: const BoxConstraints(maxHeight: 450),
        onClosing: () {},
        builder: (context) {
          return Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: IconButton(
                  onPressed: () => pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
            if (widget.operationsBlocked)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: getErrorMessage(
                  context,
                  "You have more members than allowed. Please upgrade your plan or delete some members.",
                ),
              ),
            if (!widget.operationsBlocked)
              if (!selected.isBlocked)
                ListTile(
                  leading: const Icon(Icons.phonelink_ring),
                  title: const Text("Ping"),
                  onTap: () {
                    pop();
                    NotificationRepo.instance
                        .sendPingNotification(me, selected);
                  },
                ),
            if (!widget.operationsBlocked)
              if (!selected.isBlocked)
                ListTile(
                  leading: const Icon(Icons.message),
                  title: const Text("Message"),
                  onTap: () async {
                    final message = await push<String>(
                        const MessageListView(pickMessageMode: true));
                    if (message != null) {
                      pop();
                      try {
                        await NotificationRepo.instance
                            .sendMessageNotification(me, selected, message);
                        snack("Message sent successfully", info: true);
                      } catch (e) {
                        snack(e);
                      }
                    }
                  },
                ),
            if (!widget.operationsBlocked)
              if (!selected.isBlocked)
                ListTile(
                  leading: const Icon(Icons.mic),
                  title: const Text("Audio Message"),
                  onTap: () async {
                    if (kIsWeb) {
                      final data =
                          await push<Uint8List?>(const AudioRecordWeb());
                      if (data != null) {
                        pop();
                        NotificationRepo.instance
                            .sendDataAudioNotification(me, selected, data);
                      }
                      return;
                    }
                    final file = await push<File>(const PingAudioRecord());
                    if (file == null) {
                      return;
                    }
                    final send =
                        await push<bool>(VerifyAudioView(audioFile: file));
                    if (send ?? false) {
                      pop();
                      NotificationRepo.instance
                          .sendAudioNotification(me, selected, file);
                    }
                  },
                ),
            if (!widget.operationsBlocked)
              if (!isMember)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text("Update Member"),
                  onTap: () {
                    pop();
                    push(MemberManageView(member: selected));
                  },
                ),
            if (!widget.operationsBlocked)
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text("View QR Code"),
                onTap: () {
                  pop();
                  push(MemberQrCode(memberId: selected.id));
                },
              ),
            if (!widget.operationsBlocked)
              if (!isMember)
                ListTile(
                  leading: selected.isBlocked
                      ? const Icon(Icons.lock_open)
                      : const Icon(Icons.block),
                  title: selected.isBlocked
                      ? const Text("Unblock Member")
                      : const Text("Block Member"),
                  onTap: () {
                    pop();
                    MemberRepo.instance
                        .blockUnblockMember(selected.id, !selected.isBlocked)
                        .catchError((error) => snack(error));
                  },
                ),
            if (!isMember)
              ListTile(
                leading: const Icon(Icons.remove_circle, color: Colors.red),
                title: const Text(
                  "Remove Member",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  pop();
                  sureDialog(
                    context: context,
                    title: "Remove Member",
                    message: "Are you sure you want to remove ${selected.name}",
                    onYes: () => MemberRepo.instance
                        .removeMember(selected.id)
                        .catchError((error) => snack(error)),
                  );
                },
              ),
          ]);
        },
      ),
    );
  }
}
