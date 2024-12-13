import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/notification/model/ping_notification_model.dart';
import 'package:ping_app/notification/repo/notification_repo.dart';
import 'package:ping_app/notification/view/notification_response_dialog.dart';

class NotificationService {
  static final instance = NotificationService._();

  StreamSubscription? _subscription;

  NotificationService._();

  int userType = 0;
  bool alreadyRan = false;

  void setNotificationListener(
      BuildContext context, String memberId, int userType) {
    if (alreadyRan && this.userType == userType) {
      return;
    }
    alreadyRan = true;
    this.userType = userType;
    listenToNewNotifications(context, memberId);
  }

  void listenToNewNotifications(BuildContext context, String memberId) {
    if (_subscription != null) {
      _subscription!.cancel();
    }
    _subscription = NotificationRepo.instance.notificationCollection
        .where('toId', isEqualTo: memberId)
        .snapshots()
        .listen((event) {
      final newNotificationEvents = event.docChanges
          .where((element) => element.type == DocumentChangeType.added)
          .map((e) => e.doc)
          .toList();

      final newNotifications = newNotificationEvents
          .map((doc) => PingNotificationModel.fromJson(doc.id, doc.data()!))
          .toList();

      for (final notification in newNotifications) {
        if (!notification.isDelivered) {
          _showNotificationAndDeliver(context, notification);
        }
      }
    });
  }

  void _showNotificationAndDeliver(
      BuildContext context, PingNotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) =>
          NotificationResponseDialog(notification: notification),
    );
    NotificationRepo.instance.markNotificationDelivered(notification.id);
  }
}
