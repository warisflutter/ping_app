import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/member/model/member_model.dart';

class MemberRepo {
  static final instance = MemberRepo._();

  final _memberChangesController = StreamController<void>.broadcast();

  Stream<void> get memberChanges => _memberChangesController.stream;

  MemberRepo._();

  final _memberCollection = FirebaseFirestore.instance.collection('members');
  final _memberOrder =
      FirebaseFirestore.instance.collection("members_order").doc(FirebaseAuth.instance.currentUser?.uid ?? "all");

  //save members order (list of string)
  Future<void> saveMemberOrder(List<String> order) => _memberOrder.set({"order": order});

  Future<List<String>> getMemberOrder() async {
    final doc = await _memberOrder.get();
    final data = doc.data();
    if (data == null) {
      return [];
    }
    return List<String>.from(data["order"]);
  }

  Future<String> addMember(MemberModel member) async {
    final resp = await _memberCollection.add(member.toJson());
    _memberChangesController.add(null);
    return resp.id;
  }

  Future<void> updateMember(String memberId, MemberModel member) {
    final updatedMember = member.toJson();
    print(updatedMember);
    return _memberCollection.doc(memberId).update(member.toJson());
  }

  Future<void> blockUnblockMember(String memberId, bool isBlocked) async {
    await _memberCollection.doc(memberId).update({
      MemberModel.keyIsBlocked: isBlocked,
    });
    _memberChangesController.add(null);
  }

  Future<void> removeMember(String memberId) async {
    await _memberCollection.doc(memberId).delete();
    _memberChangesController.add(null);
  }

  Future<void> updateOnlineStatus(String memberId, bool isOnline) async {
    debugPrint("updating member online status $isOnline");
    await _memberCollection.doc(memberId).update({
      MemberModel.keyMemberOnline: isOnline,
      MemberModel.keyLastSeen: FieldValue.serverTimestamp(),
    });
    _memberChangesController.add(null);
  }

  Stream<List<MemberModel>> getMembers({
    required PingUserModel ofTeamLead,
    required String? ifMemberId,
    String? myMemberName,
  }) {
    // // if (myMemberName != null) {
    // return _memberCollection
    //     .where(MemberModel.keyTeamLeadId, isEqualTo: ofTeamLead.userId)
    //     .where(MemberModel.keyMemberName, isEqualTo: myMemberName)
    //     .snapshots()
    //     .map((snapshot) {
    //   final rawData = snapshot.docs.map((doc) {
    //     return MemberModel.fromJson(doc.id, doc.data());
    //   }).toList();
    //   return rawData;
    // });
    // }
    return _memberCollection
        .where(
          MemberModel.keyTeamLeadId,
          isEqualTo: ofTeamLead.userId,
        )
        .snapshots()
        .map((snapshot) {
      final rawData = snapshot.docs.map((doc) {
        return MemberModel.fromJson(doc.id, doc.data());
      }).toList();
      return rawData;
    });
  }

  Future<int> getMemberCount(String teamLeadId) async {
    final snapshot = await _memberCollection.where(MemberModel.keyTeamLeadId, isEqualTo: teamLeadId).get();
    return snapshot.size;
  }

  // Future<void> updateFcmToken(String memberId, String fcmToken) async {
  //   await _memberCollection.doc(memberId).update({
  //     MemberModel.keyFcm: fcmToken,
  //   });
  // }
  Future<void> updateFcmToken(String userId, String fcmToken) async {
    try {
      final docRef = _memberCollection.doc(userId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Ensure the field exists before accessing it
        List<String> existingTokens = [];
        if (docSnapshot.data() != null && docSnapshot.data()!.containsKey(PingUserModel.keyFcmToken)) {
          existingTokens = List.from(docSnapshot.get(PingUserModel.keyFcmToken));
        }

        // Check if userId already exists
        bool alreadyExists = existingTokens.contains(fcmToken);

        if (!alreadyExists) {
          await docRef.update({
            MemberModel.keyFcm: FieldValue.arrayUnion([fcmToken])
          });
        }
      } else {
        // If document doesn't exist, create it with the first entry
        await docRef.set({
          MemberModel.keyFcm: [fcmToken]
        });
      }
    } catch (e) {
      PingLog.pingLog("updateFcmToken: $e");
    }
  }

  Future<MemberModel> getMemberById(String memberId) async {
    final doc = await _memberCollection.doc(memberId).get();
    final data = doc.data();
    if (data == null) {
      throw Exception('t_memberNotFound'.tr());
    }
    return MemberModel.fromJson(doc.id, data);
  }

  Future<MemberModel?> getNullableMemberById(String memberId) async {
    final doc = await _memberCollection.doc(memberId).get();
    final data = doc.data();
    if (data == null) {
      return null;
    }
    return MemberModel.fromJson(doc.id, data);
  }

  Future<List<MemberModel>> getMembersByIds(List<String> memberIds) async {
    if (memberIds.isEmpty) return [];

    final snapshots = await Future.wait(memberIds.map((id) => _memberCollection.doc(id).get()));

    return snapshots
        .where((doc) => doc.exists && doc.data() != null)
        .map((doc) => MemberModel.fromJson(doc.id, doc.data()!))
        .toList();
  }

  void dispose() {
    _memberChangesController.close();
  }
}
