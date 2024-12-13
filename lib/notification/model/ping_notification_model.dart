import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  ping,
  message,
  audioMessage,
}

extension NotificationTypeExtension on NotificationType {
  String get title {
    switch (this) {
      case NotificationType.ping:
        return 't_ping'.tr();
      case NotificationType.message:
        return 't_message'.tr();
      case NotificationType.audioMessage:
        return 't_audioMessage'.tr();
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.ping:
        return Icons.phonelink_ring;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.audioMessage:
        return Icons.mic;
    }
  }
}

class PingNotificationModel {
  static const durationExpire = Duration(seconds: 25);
  static const durationBlackOut = Duration(seconds: 5);

  static const keyDeliverAt = 'deliveredAt';
  static const keyResponse = 'response';

  final String id;
  final String fromId;
  final String toId;
  final NotificationType type;
  final String? data;
  final String message;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final bool? response;

  bool get is30SecAgo =>
      (DateTime.now().difference(sentAt ?? DateTime.now()).inSeconds) > 30;

  Duration? nextTick() {
    if (is30SecAgo) {
      return null;
    }
    final notification = this;
    final expiryTime =
        (notification.sentAt ?? DateTime.now()).add(durationExpire);
    if (expiryTime.isAfter(DateTime.now())) {
      return expiryTime.difference(DateTime.now());
    } else {
      final blackOutTime = (expiryTime).add(durationBlackOut);
      if (blackOutTime.isAfter(DateTime.now())) {
        return blackOutTime.difference(DateTime.now());
      } else {
        return null;
      }
    }
  }

  Color get color {
    final notification = this;
    final response = this.response;

    if (notification.type != NotificationType.ping || is30SecAgo) {
      return Colors.transparent;
    }

    final expiryTime =
        (notification.sentAt ?? DateTime.now()).add(durationExpire);
    if (expiryTime.isAfter(DateTime.now())) {
      return response != null
          ? response
              ? Colors.green
              : Colors.red
          : deliveredAt != null
              ? Colors.white.withOpacity(0.5)
              : sentAt != null
                  ? Colors.white.withOpacity(0.5)
                  : Colors.transparent;
    } else {
      final blackOutTime = (expiryTime).add(durationBlackOut);
      if (blackOutTime.isAfter(DateTime.now())) {
        return response != null
            ? response
                ? Colors.green
                : Colors.red
            : Colors.black.withOpacity(0.5);
      } else {
        return Colors.transparent;
      }
    }
  }

  PingNotificationModel({
    required this.fromId,
    required this.toId,
    required this.type,
    required this.message,
    this.data,
  })  : sentAt = null,
        deliveredAt = null,
        response = null,
        id = "";

  bool get isDelivered => deliveredAt != null || response != null;

  bool get isResponded => response != null;

  PingNotificationModel.fromJson(this.id, Map<String, dynamic> json)
      : fromId = json['fromId'],
        toId = json['toId'],
        type = NotificationType.values[json['type']],
        data = json['data'],
        message = json['message'],
        sentAt = _parseTimestamp(json['sentAt']),
        deliveredAt = _parseTimestamp(json[keyDeliverAt]),
        response = json[keyResponse];

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is Map<String, dynamic>) {
      if (value.containsKey('_seconds') && value.containsKey('_nanoseconds')) {
        return Timestamp(value['_seconds'], value['_nanoseconds']).toDate();
      }
    }

    // If it's neither a Timestamp nor a Map with _seconds and _nanoseconds,
    // you might want to handle other cases or return null
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'fromId': fromId,
      'toId': toId,
      'type': type.index,
      'data': data,
      'message': message,
      keyResponse: response,
      'sentAt': sentAt ?? FieldValue.serverTimestamp(),
      keyDeliverAt: deliveredAt,
    };
  }
}
