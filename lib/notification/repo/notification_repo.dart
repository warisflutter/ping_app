import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/member/model/member_model.dart';
import 'package:ping_app/notification/model/ping_notification_model.dart';

import '../../services/notification_service.dart';
import '../../util/messenger.dart';

class NotificationRepo {
  static final instance = NotificationRepo._();

  NotificationRepo._();

  final notificationCollection = FirebaseFirestore.instance.collection("notifications");

  final audioStorage = FirebaseStorage.instance.ref('audio');

  Future<PingNotificationModel> sendPingNotification(
    MemberModel fromMember,
    MemberModel toMember,
  ) async {
    try {
      final n = PingNotificationModel(
        fromId: fromMember.id,
        toId: toMember.id,
        type: NotificationType.ping,
        message: "${fromMember.name} ${'t_sentAPing'.tr()}",
      );
      final data = await notificationCollection.add(n.toJson());
      final doc = await notificationCollection.doc(data.id).get();
      return PingNotificationModel.fromJson(data.id, doc.data()!);
    } catch (e, st) {
      log("Error: $e");
      log("Stack trace: $st");

      rethrow;
    }
  }

  Future<void> sendWatchNotification({
    required String fromId,
    required String toId,
    required String title,
    required NotificationType type,
    String? data,
  }) async {
    final n = {
      "fromId": fromId,
      "toId": toId,
      "type": type.index,
      "data": data,
      "message": title,
      "sentAt": FieldValue.serverTimestamp(),
      "deliveredAt": null,
      "response": null
    };
    List<String>? token;
    String? receiverName;
    final res = await notificationCollection.add(n);
    final doc = await notificationCollection.doc(res.id).get();
    final newData = PingNotificationModel.fromJson(res.id, doc.data()!);
    DocumentSnapshot membersDoc = await FirebaseFirestore.instance.collection('members').doc(toId).get();
    if (membersDoc.exists) {
      token = membersDoc['fcm'] ?? '';
      receiverName = membersDoc['name'] ?? '';
    } else {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(toId).get();
      if (userDoc.exists) {
        token = userDoc['fcm'] ?? '';
        receiverName = userDoc['fullName'] ?? '';
      }
    }
    debugPrint("response-------$n");
    debugPrint("token-------$token");
    if (token == null || token.isEmpty) {
      debugPrint("Token is missing for $toId");
    }
    final newRes = await FirebaseNotificationService().sendNotification(
      messageData: newData.data ?? "",
      type: "${type.index}",
      id: newData.id,
      title: (type.index == 0)
          ? "Ping"
          : (type.index == 1)
              ? "Message"
              : "Audio Message",
      body: (type.index == 0)
          ? "$receiverName ${'t_sentAPing'.tr()}"
          : (type.index == 1)
              ? "$receiverName ${'t_sentYouAMessage'.tr()}"
              : "$receiverName ${'t_sentYouAudioMessage'.tr()}",
      tokens: token ?? [],
      fromId: fromId,
      toId: toId,
    );
    if (newRes) {
      snack(
        (type.index == 0)
            ? "t_pingSentSuccessfully".tr()
            : (type.index == 1)
                ? "t_messageSentSuccessfully".tr()
                : "t_audioMessageSendSuccessfully".tr(),
        info: true,
      );
    } else {
      snack(
        (type.index == 0)
            ? "t_pingSendingCancelled".tr()
            : (type.index == 1)
                ? "t_messageSendingCancelled".tr()
                : "t_messageSendingCancelled".tr(),
      );
    }
  }

  Future<PingNotificationModel> sendMessageNotification(
    MemberModel fromMember,
    MemberModel toMember,
    String message,
  ) async {
    try {
      final n = PingNotificationModel(
        fromId: fromMember.id,
        toId: toMember.id,
        type: NotificationType.message,
        message: "${fromMember.name} ${'t_sentYouAMessage'.tr()}",
        data: message,
      );
      final data = await notificationCollection.add(n.toJson());
      final doc = await notificationCollection.doc(data.id).get();
      return PingNotificationModel.fromJson(data.id, doc.data()!);
    } catch (e, st) {
      log("Error: $e");
      log("Stack trace: $st");
      rethrow;
    }
  }

  Future<PingNotificationModel> sendAudioNotification(
    MemberModel fromMember,
    MemberModel toMember,
    File audio,
  ) async {
    try {
      final doc = notificationCollection.doc();
      final fileUrl = await uploadFileAndGetUrl(doc.id, audio);
      final n = PingNotificationModel(
        fromId: fromMember.id,
        toId: toMember.id,
        type: NotificationType.audioMessage,
        message: "${fromMember.name} ${'t_sentYouAudioMessage'.tr()}",
        data: fileUrl,
      );
      await doc.set(n.toJson());
      final fetchedDoc = await doc.get();
      return PingNotificationModel.fromJson(doc.id, fetchedDoc.data()!);
    } catch (e, st) {
      log("Error in sendAudioNotification: $e");
      log("Stack trace: $st");
      rethrow;
    }
  }

  Future<void> sendDataAudioNotification(MemberModel fromMember, MemberModel toMember, Uint8List data) async {
    final doc = notificationCollection.doc();
    final fileUrl = await uploadDataAndGetUrl(doc.id, data);

    final n = PingNotificationModel(
      fromId: fromMember.id,
      toId: toMember.id,
      type: NotificationType.audioMessage,
      message: "${fromMember.name} ${'t_sentYouAudioMessage'.tr()}",
      data: fileUrl,
    );

    await doc.set(n.toJson());
  }

  Future<void> respondToNotification(String id, bool response) async {
    await notificationCollection.doc(id).update({
      PingNotificationModel.keyResponse: response,
    });
  }

  Stream<List<PingNotificationModel>> getNotifications(String memberId) {
    return notificationCollection
        .where('toId', isEqualTo: memberId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PingNotificationModel.fromJson(doc.id, doc.data())).toList());
  }

  Stream<List<PingNotificationModel>> getNotificationsFromMe(String memberId) {
    return notificationCollection
        .where('fromId', isEqualTo: memberId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PingNotificationModel.fromJson(doc.id, doc.data())).toList());
  }

  Stream<List<PingNotificationModel>> getNotificationsFromMeToId(String fromId, String toId) {
    return notificationCollection
        .where('fromId', isEqualTo: fromId)
        .where('toId', isEqualTo: toId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PingNotificationModel.fromJson(doc.id, doc.data())).toList());
  }

  Stream<PingNotificationModel?> getMostRecentNotification(String memberId) {
    return getNotifications(memberId).map((event) {
      if (event.isEmpty) {
        return null;
      }
      event.sort((a, b) => (b.sentAt ?? DateTime.now()).compareTo(a.sentAt ?? DateTime.now()));
      return event.first;
    });
  }

  Stream<PingNotificationModel?> getMostRecentNotificationFromMeToId(String fromId, String toId) {
    return getNotificationsFromMeToId(fromId, toId).map((event) {
      if (event.isEmpty) {
        return null;
      }
      event.sort((a, b) => (b.sentAt ?? DateTime.now()).compareTo(a.sentAt ?? DateTime.now()));
      return event.first;
    });
  }

  Future<void> markNotificationDelivered(String notificationId) {
    return notificationCollection.doc(notificationId).update({
      PingNotificationModel.keyDeliverAt: FieldValue.serverTimestamp(),
    });
  }

  Future<String> uploadFileAndGetUrl(String id, File file) async {
    final ref = audioStorage.child("$id.m4a");
    final metadata = SettableMetadata(contentType: 'audio/m4a');
    await ref.putFile(file, metadata);
    return ref.getDownloadURL();
  }

  Future<String> uploadDataAndGetUrl(String id, Uint8List data) async {
    final ref = audioStorage.child("$id.wav");
    final metadata = SettableMetadata(contentType: 'audio/wav');
    await ref.putData(data, metadata);
    return ref.getDownloadURL();
  }
}
