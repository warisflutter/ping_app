import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ping_app/member/model/member_model.dart';
import 'package:ping_app/notification/model/ping_notification_model.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
        message: "${fromMember.name} ${'t_sentAPing'.tr()}", // Translation example
      );

      // Add notification to the collection
      final data = await notificationCollection.add(n.toJson());

      // Get the document by ID to retrieve the complete data
      final doc = await notificationCollection.doc(data.id).get();

      // Return the model object with the data retrieved
      return PingNotificationModel.fromJson(data.id, doc.data()!);
    } catch (e, st) {
      // Log error and stack trace
      log("Error: $e");
      log("Stack trace: $st");

      // Optionally, return a default value or throw a specific exception
      rethrow; // Or you can return a default model with empty values, e.g.,
      // return PingNotificationModel(fromId: '', toId: '', type: NotificationType.ping, message: '');
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
    await notificationCollection.add(n);
  }

  // Future<void> sendMessageNotification(MemberModel fromMember, MemberModel toMember, String message) async {
  //   final n = PingNotificationModel(
  //     fromId: fromMember.id,
  //     toId: toMember.id,
  //     type: NotificationType.message,
  //     message: "${fromMember.name} ${'t_sentYouAMessage'.tr()}",
  //     data: message,
  //   );
  //
  //   await notificationCollection.add(n.toJson());
  // }
  Future<PingNotificationModel> sendMessageNotification(
    MemberModel fromMember,
    MemberModel toMember,
    String message,
  ) async {
    try {
      // Create the notification model for a message
      final n = PingNotificationModel(
        fromId: fromMember.id,
        toId: toMember.id,
        type: NotificationType.message,
        message: "${fromMember.name} ${'t_sentYouAMessage'.tr()}", // Translation example
        data: message,
      );

      // Add notification to the collection
      final data = await notificationCollection.add(n.toJson());

      // Get the document by ID to retrieve the complete data
      final doc = await notificationCollection.doc(data.id).get();

      // Return the model object with the data retrieved
      return PingNotificationModel.fromJson(data.id, doc.data()!);
    } catch (e, st) {
      // Log error and stack trace
      log("Error: $e");
      log("Stack trace: $st");

      // Optionally, return a default value or throw a specific exception
      rethrow; // Or you can return a default model with empty values, e.g.,
      // return PingNotificationModel(fromId: '', toId: '', type: NotificationType.message, message: '', data: '');
    }
  }

  Future<void> sendAudioNotification(MemberModel fromMember, MemberModel toMember, File audio) async {
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
