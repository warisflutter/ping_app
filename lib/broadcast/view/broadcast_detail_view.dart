import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/broadcast/model/broadcast_model.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/member/model/member_model.dart';
import 'package:ping_app/member/view/member_list_item.dart';
import 'package:ping_app/notification/repo/notification_repo.dart';
import 'package:ping_app/util/audio/ping_audio_record.dart';
import 'package:ping_app/util/audio/verify_audio_view.dart';
import 'package:ping_app/util/parsers.dart';
import 'package:ping_app/util/ping_styles.dart';
import 'package:ping_app/util/record_web/audio_main.dart';
import 'package:ping_app/view/settings/view/sub_view/message_template/message_template_list.dart';
import 'package:ping_app/widgets/global_layout_builder.dart';
import 'package:ping_app/widgets/ping_list_tile.dart';
import 'package:provider/provider.dart';

class BroadcastDetailView extends StatelessWidget {
  final BroadcastModel initialBroadcast;

  const BroadcastDetailView({super.key, required this.initialBroadcast});

  @override
  Widget build(BuildContext context) {
    final teamLead = context.watch<PingAuthState>().currentPingUser;
    if (teamLead == null) {
      return getErrorMessage(
        context,
        't_userIsTryAgain'.tr(),
      );
    }
    return StreamBuilder(
      stream: BroadcastRepository.instance.streamBroadcast(initialBroadcast.id),
      builder: (context, snap) {
        final broadcast = snap.data ?? initialBroadcast;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              broadcast.name,
              style: (context.isWatch) ? PingStyles.watchStyle : null,
            ),
          ),
          floatingActionButton: SizedBox(
            width: (context.isWatch) ? PingStyles.watchButtonHeight : null,
            height: (context.isWatch) ? PingStyles.watchButtonHeight : null,
            child: FloatingActionButton(
              child: Icon(
                Icons.group,
                size: (context.isWatch) ? PingStyles.watchIconSize : null,
              ),
              onPressed: () async {
                final isInternetAvailable = await context.isInternetAvailable();
                if (isInternetAvailable) {
                  if (context.mounted) {
                    _showAddMemberDialog(context, broadcast);
                  }
                } else {
                  snack("t_noInternetPleaseConnectToTheInternet".tr());
                }
              },
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: (context.isWatch) ? const EdgeInsets.only(right: 4.0) : const EdgeInsets.all(16.0),
                  child: Text(
                    parseDateTime(broadcast.createdAt),
                    style: (context.isWatch) ? PingStyles.watchStyle : null,
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<MemberModel>>(
                  future: MemberRepo.instance.getMembersByIds(broadcast.memberIds),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return getLoader();
                    }
                    if (snapshot.hasError) {
                      return getErrorMessage(context, 't_noMembersThisBroadcast'.tr());
                    }
                    final members = snapshot.data ?? [];
                    if (members.isEmpty) {
                      return getErrorMessage(context, 't_noMembersThisBroadcast'.tr());
                    }

                    final sortIds = context.watch<MemberState>().idOrder;
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
                        Expanded(
                          child: ListView.builder(
                            itemCount: members.length,
                            itemBuilder: (context, index) {
                              final member = members[index];
                              return MemberListItem(
                                isLoggedInAsMember: false,
                                currentUserModel: MemberModel.fromPingUserModel(teamLead),
                                listTimeMemberModel: member,
                                operationsBlocked: false,
                                viewOnly: true,
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: (context.isWatch) ? 0.0 : 8.0,
                            horizontal: 16.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PingListTile(
                                verticalH: (context.isWatch) ? 2.0 : null,
                                iconData: Icons.notifications_active,
                                title: 't_sendPing'.tr(),
                                onTap: () async {
                                  final me = MemberModel.fromPingUserModel(teamLead);
                                  for (final member in members) {
                                    final data = await NotificationRepo.instance.sendPingNotification(me, member);
                                    await FirebaseNotificationService().sendNotification(
                                      messageData: data.data ?? "",
                                      type: "0",
                                      id: data.id,
                                      title: "Ping",
                                      body: "${me.name} ${'t_sentAPing'.tr()}",
                                      tokens: member.fcm,
                                      fromId: me.id,
                                      toId: member.id,
                                    );
                                  }
                                },
                              ),
                              PingListTile(
                                verticalH: (context.isWatch) ? 2.0 : null,
                                iconData: Icons.message,
                                title: 't_sendMessage'.tr(),
                                onTap: () async {
                                  final message = await push<String>(const MessageListView(pickMessageMode: true));
                                  if (message != null) {
                                    final me = MemberModel.fromPingUserModel(teamLead);
                                    try {
                                      for (final member in members) {
                                        final data = await NotificationRepo.instance
                                            .sendMessageNotification(me, member, message);
                                        await FirebaseNotificationService().sendNotification(
                                          messageData: data.data ?? "",
                                          type: "1",
                                          id: data.id,
                                          title: "Message",
                                          body: "${me.name} ${'t_sentYouAMessage'.tr()}",
                                          tokens: member.fcm,
                                          fromId: me.id,
                                          toId: member.id,
                                        );
                                      }
                                      snack('t_messageSentSuccessfully'.tr(), info: true);
                                    } catch (e) {
                                      snack(e);
                                    }
                                  }
                                },
                              ),
                              PingListTile(
                                verticalH: (context.isWatch) ? 2.0 : null,
                                iconData: Icons.mic,
                                title: 't_recordAudio'.tr(),
                                onTap: () async {
                                  final me = MemberModel.fromPingUserModel(teamLead);

                                  if (kIsWeb) {
                                    final data = await push<Uint8List?>(const AudioRecordWeb());
                                    if (data != null) {
                                      snack('t_sendingAudioMessage'.tr(), info: true);
                                      for (final selected in members) {
                                        await NotificationRepo.instance.sendDataAudioNotification(me, selected, data);
                                      }
                                      snack('t_audioMessageSendSuccessfully'.tr(), info: true);
                                    }
                                    return;
                                  }
                                  final file = await push<File>(const PingAudioRecord());
                                  if (file == null) {
                                    return;
                                  }
                                  final send = await push<bool>(VerifyAudioView(audioFile: file));
                                  if (send ?? false) {
                                    snack('t_sendingAudioMessage'.tr(), info: true);
                                    for (final member in members) {
                                      final data =
                                          await NotificationRepo.instance.sendAudioNotification(me, member, file);
                                      await FirebaseNotificationService().sendNotification(
                                        messageData: data.data ?? "",
                                        type: "2",
                                        id: data.id,
                                        title: "Audio Message",
                                        body: "${me.name} ${'t_sentYouAudioMessage'.tr()}",
                                        tokens: member.fcm,
                                        fromId: me.id,
                                        toId: member.id,
                                      );
                                    }
                                    snack('t_audioMessageSent'.tr(), info: true);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddMemberDialog(BuildContext context, BroadcastModel broadcast) {
    final authState = context.read<PingAuthState>();
    final teamLead = authState.currentPingUser;
    if (teamLead == null) {
      snack('t_userIsTryAgain'.tr());
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddMemberDialog(broadcast: broadcast, teamLead: teamLead);
      },
    );
  }
}

class AddMemberDialog extends StatefulWidget {
  final BroadcastModel broadcast;
  final PingUserModel teamLead;

  const AddMemberDialog({
    super.key,
    required this.broadcast,
    required this.teamLead,
  });

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  Set<String> selectedMembers = {};

  @override
  void initState() {
    super.initState();
    selectedMembers = Set.from(widget.broadcast.memberIds);
  }

  @override
  Widget build(BuildContext context) {
    return (context.isWatch)
        ? AlertDialog(
            actionsPadding: EdgeInsets.zero,
            contentPadding: (context.isWatch) ? const EdgeInsets.symmetric(horizontal: 8.0) : null,
            insetPadding: (context.isWatch) ? const EdgeInsets.symmetric(horizontal: 8.0) : null,
            title: Text(
              't_addRemoveMembers'.tr(),
              style: (context.isWatch) ? PingStyles.watchStyle : Theme.of(context).textTheme.titleLarge,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: StreamBuilder<List<MemberModel>>(
                    stream: MemberRepo.instance.getMembers(
                      ofTeamLead: widget.teamLead,
                      ifMemberId: null,
                    ),
                    builder: (context, snapshot) {
                      final allMembers = snapshot.data ?? [];
                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: allMembers.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final member = allMembers[index];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                member.name,
                                style: (context.isWatch) ? PingStyles.watchStyle : null,
                              ),
                              SizedBox(
                                height: 25,
                                width: 25,
                                child: Checkbox(
                                  value: selectedMembers.contains(member.id),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedMembers.add(member.id);
                                      } else {
                                        selectedMembers.remove(member.id);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () => pop(),
                        child: Text(
                          't_cancel'.tr(),
                          style: (context.isWatch) ? PingStyles.watchStyle : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () async {
                          try {
                            pop();
                            await BroadcastRepository.instance.updateBroadcastMembers(
                              widget.broadcast.id,
                              selectedMembers.toList(),
                            );
                            snack('t_membersUpdatedSuccessfully'.tr(), info: true);
                          } catch (e) {
                            snack('${'t_errorUpdatingMembers'.tr()}: $e');
                          }
                        },
                        child: Text(
                          't_save'.tr(),
                          style: (context.isWatch) ? PingStyles.watchStyle : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : DialogLayoutBuilder(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  't_addRemoveMembers'.tr(),
                  style: (context.isWatch) ? PingStyles.watchStyle : Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<MemberModel>>(
                  stream: MemberRepo.instance.getMembers(
                    ofTeamLead: widget.teamLead,
                    ifMemberId: null,
                  ),
                  builder: (context, snapshot) {
                    final allMembers = snapshot.data ?? [];
                    return Column(
                      children: allMembers.map((member) {
                        return CheckboxListTile(
                          title: Text(
                            member.name,
                            style: (context.isWatch) ? PingStyles.watchStyle : null,
                          ),
                          value: selectedMembers.contains(member.id),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedMembers.add(member.id);
                              } else {
                                selectedMembers.remove(member.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => pop(),
                      child: Text(
                        't_cancel'.tr(),
                        style: (context.isWatch) ? PingStyles.watchStyle : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          pop();
                          await BroadcastRepository.instance.updateBroadcastMembers(
                            widget.broadcast.id,
                            selectedMembers.toList(),
                          );
                          snack('t_membersUpdatedSuccessfully'.tr(), info: true);
                        } catch (e) {
                          snack('${'t_errorUpdatingMembers'.tr()}: $e');
                        }
                      },
                      child: Text(
                        't_save'.tr(),
                        style: (context.isWatch) ? PingStyles.watchStyle : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
  }
}
// class AddMemberDialog extends StatefulWidget {
//   final BroadcastModel broadcast;
//   final PingUserModel teamLead;
//
//   const AddMemberDialog({
//     super.key,
//     required this.broadcast,
//     required this.teamLead,
//   });
//
//   @override
//   State<AddMemberDialog> createState() => _AddMemberDialogState();
// }
//
// class _AddMemberDialogState extends State<AddMemberDialog> {
//   Set<String> selectedMembers = {};
//
//   @override
//   void initState() {
//     super.initState();
//     selectedMembers = Set.from(widget.broadcast.memberIds);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text('t_addRemoveMembers'.tr()),
//       content: StreamBuilder<List<MemberModel>>(
//         stream: MemberRepo.instance.getMembers(
//           ofTeamLead: widget.teamLead,
//           ifMemberId: null,
//         ),
//         builder: (context, snapshot) {
//           final allMembers = snapshot.data ?? [];
//           return ListView.builder(
//             shrinkWrap: true,
//             itemCount: allMembers.length,
//             itemBuilder: (context, index) {
//               final member = allMembers[index];
//               return CheckboxListTile(
//                 title: Text(member.name),
//                 value: selectedMembers.contains(member.id),
//                 onChanged: (bool? value) {
//                   setState(() {
//                     if (value == true) {
//                       selectedMembers.add(member.id);
//                     } else {
//                       selectedMembers.remove(member.id);
//                     }
//                   });
//                 },
//               );
//             },
//           );
//         },
//       ),
//       actions: <Widget>[
//         TextButton(
//           child: Text('t_cancel'.tr()),
//           onPressed: () => pop(),
//         ),
//         TextButton(
//           child: Text('t_save'.tr()),
//           onPressed: () async {
//             try {
//               pop();
//               await BroadcastRepository.instance.updateBroadcastMembers(
//                 widget.broadcast.id,
//                 selectedMembers.toList(),
//               );
//               snack('t_membersUpdatedSuccessfully'.tr(), info: true);
//             } catch (e) {
//               snack('${'t_errorUpdatingMembers'.tr()}: $e');
//             }
//           },
//         ),
//       ],
//     );
//   }
// }
