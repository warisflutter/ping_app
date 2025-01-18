import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/notification/model/ping_notification_model.dart';
import 'package:ping_app/notification/repo/notification_repo.dart';
import 'package:ping_app/util/audio/ping_audio_player.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_log.dart';

class NotificationResponseDialog extends StatelessWidget {
  final PingNotificationModel notification;

  const NotificationResponseDialog({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    PingLog.pingLog("This is my notification: ${notification.type}");
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.type.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (notification.type == NotificationType.message)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 40,
                ),
                child: Text(
                  notification.data ?? "",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (notification.type == NotificationType.audioMessage)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 40,
                ),
                child: PingAudioPlayer(url: notification.data),
              )
            else
              const SizedBox(height: 40),
            if (notification.type == NotificationType.ping)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        backgroundColor: Colors.green.shade900,
                        onPressed: () {
                          pop();
                          NotificationRepo.instance.respondToNotification(notification.id, true);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(120),
                        ),
                        elevation: 0,
                        child: Icon(
                          Icons.check,
                          color: Colors.green.shade100,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        't_coming'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        onPressed: () {
                          pop();
                          NotificationRepo.instance.respondToNotification(notification.id, false);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(120),
                        ),
                        backgroundColor: Colors.red.shade900,
                        elevation: 0,
                        child: Icon(
                          Icons.clear,
                          color: Colors.red.shade100,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        't_notComing'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
