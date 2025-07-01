import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:ping_app/notification/model/ping_notification_model.dart';
import 'package:ping_app/notification/repo/notification_repo.dart';
import 'package:ping_app/util/audio/ping_audio_player.dart';
import 'package:ping_app/util/audio/ping_audio_player_web.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:ping_app/util/ping_styles.dart';
import 'package:ping_app/util/ping_utils.dart';

class NotificationResponseDialog extends StatefulWidget {
  final PingNotificationModel notification;
  final bool? isFromNotification;
  const NotificationResponseDialog({
    super.key,
    required this.notification,
    this.isFromNotification = false
  });

  @override
  State<NotificationResponseDialog> createState() => _NotificationResponseDialogState();
}

class _NotificationResponseDialogState extends State<NotificationResponseDialog> {
  late Timer _timer;
  double _progress = 1.0; // Starts full
  int _duration = 5; // seconds
  int _elapsed = 0;


  @override
  void initState(){
    super.initState();
    var isFromNotification = widget.isFromNotification ?? false;
    if(!isFromNotification){
      initializeTimer();
    }

  }

  @override
  void dispose() {
    if(!widget.isFromNotification!){
      _timer.cancel();
    }
    super.dispose();
  }

  void initializeTimer() async{
    _duration = await AuthRepo.instance.getDialogTimer(widget.notification.fromId);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _elapsed += 100;
        _progress = 1.0 - (_elapsed / (_duration * 1000));
        if (_progress <= 0) {
          _progress = 0;
          _timer.cancel();
          Navigator.of(context).pop(); // Close the dialog
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    PingLog.pingLog("This is my notification: ${widget.notification.type}");
    return (context.isWatch)
        ? Material(
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: Colors.black,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: PingStyles.watchIconSize,
                                )),
                          ),
                          Text(
                            widget.notification.type.title,
                            style: (context.isWatch)
                                ? PingStyles.watchStyle
                                : const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                          ),
                          // const SizedBox(height: 4),
                          Text(
                            widget.notification.message,
                            style: (context.isWatch)
                                ? PingStyles.watchStyle
                                : const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                          ),
                          if (widget.notification.type == NotificationType.message)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 20,
                              ),
                              child: Text(
                                widget.notification.data ?? "",
                                style: (context.isWatch)
                                    ? PingStyles.watchStyle
                                    : const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                              ),
                            )
                          else if (widget.notification.type == NotificationType.audioMessage)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 10,
                              ),
                              child: (kIsWeb)
                                  ? PingAudioPlayerWeb(url: widget.notification.data)
                                  : PingAudioPlayer(url: widget.notification.data),
                            )
                          else
                            const SizedBox(height: 20),
                          if (widget.notification.type == NotificationType.ping)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: FloatingActionButton(
                                        backgroundColor: Colors.green.shade900,
                                        onPressed: () {
                                          pop();
                                          NotificationRepo.instance.respondToNotification(widget.notification.id, true);
                                        },
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(120),
                                        ),
                                        elevation: 0,
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.green.shade100,
                                          size: PingStyles.watchIconSize,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      't_coming'.tr(),
                                      style:
                                          (context.isWatch) ? PingStyles.watchStyle : Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: FloatingActionButton(
                                        onPressed: () {
                                          pop();
                                          NotificationRepo.instance.respondToNotification(widget.notification.id, false);
                                        },
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(120),
                                        ),
                                        backgroundColor: Colors.red.shade900,
                                        elevation: 0,
                                        child: Icon(
                                          Icons.clear,
                                          color: Colors.red.shade100,
                                          size: PingStyles.watchIconSize,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      't_notComing'.tr(),
                                      style:
                                          (context.isWatch) ? PingStyles.watchStyle : Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if(!widget.isFromNotification!)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 3, right: 8),
                      child: LinearProgressIndicator(value: _progress, color: _progress > 0.2 ? Colors.green : Colors.red),
                    )
                  ],
                ),
              ),
            ),
          )
        : Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.notification.type.title,
                        style: (context.isWatch)
                            ? PingStyles.watchStyle
                            : const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                      ),
                      // const SizedBox(height: 4),
                      Text(
                        widget.notification.message,
                        style: (context.isWatch)
                            ? PingStyles.watchStyle
                            : const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                      ),
                      if (widget.notification.type == NotificationType.message)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 40,
                          ),
                          child: Text(
                            widget.notification.data ?? "",
                            style: (context.isWatch)
                                ? PingStyles.watchStyle
                                : const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                            textAlign: TextAlign.start,
                          ),
                        )
                      else if (widget.notification.type == NotificationType.audioMessage)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 40,
                          ),
                          child: (kIsWeb)
                              ? PingAudioPlayerWeb(url: widget.notification.data)
                              : PingAudioPlayer(url: widget.notification.data),
                        )
                      else
                        const SizedBox(height: 40),
                      if (widget.notification.type == NotificationType.ping)
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
                                    NotificationRepo.instance.respondToNotification(widget.notification.id, true);
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
                                    NotificationRepo.instance.respondToNotification(widget.notification.id, false);
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
                if(!widget.isFromNotification!)
                Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 5, right: 10),
                  child: LinearProgressIndicator(value: _progress, color: _progress > 0.2 ? Colors.green : Colors.red),
                )
              ],
            ),
          );
  }
}
