import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/repo/ping_auth_state.dart';
import 'package:ping_app/dashboard/dashboard_mode.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/member/model/member_model.dart';
import 'package:ping_app/member/repo/member_state.dart';
import 'package:ping_app/notification/model/ping_notification_model.dart';
import 'package:ping_app/notification/repo/notification_repo.dart';
import 'package:ping_app/notification/view/notification_response_dialog.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:provider/provider.dart';

class NotificationView extends StatelessWidget {
  final DashboardMode mode;

  const NotificationView({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    late MemberModel member;

    if (mode.isTeamLead) {
      final user = context.read<PingAuthState>().currentPingUser;
      if (user != null) {
        member = MemberModel.fromPingUserModel(user);
      } else {
        return getErrorMessage(context, '');
      }
    } else {
      final m = context.read<MemberState>().member;
      if (m == null) {
        return getErrorMessage(context, '');
      }
      member = m;
    }

    return Scaffold(
      appBar: AppBar(title: Text("t_notifications".tr())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: StreamBuilder<List<PingNotificationModel>>(
            stream: NotificationRepo.instance.getNotifications(member.id),
            builder: (context, snap) {
              if (snap.hasError) {
                return getErrorMessage(context, snap.error);
              }

              final data = snap.data;
              if (data == null) {
                return getLoader();
              }

              if (data.isEmpty) {
                return getErrorMessage(context, "No Notifications Found");
              }

              data.sort((a, b) => (b.sentAt ?? DateTime.now()).compareTo(a.sentAt ?? DateTime.now()));

              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final notification = data[index];
                  return ListTile(
                    leading: Icon(notification.type.icon),
                    title: Text(notification.type.title),
                    subtitle: Text(notification.message),
                    trailing: notification.isResponded
                        ? notification.response!
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.cancel, color: Colors.red)
                        : notification.isDelivered
                            ? const Icon(Icons.done_all)
                            : notification.sentAt != null
                                ? const Icon(Icons.done)
                                : const Icon(Icons.pending_actions),
                    onTap: () {
                      if (notification.type.name != "ping") {
                        showDialog(
                          context: context,
                          builder: (context) => NotificationResponseDialog(
                            notification: notification,
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
