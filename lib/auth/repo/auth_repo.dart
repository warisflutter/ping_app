import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';
import 'package:ping_app/util/ping_log.dart';

import '../../member/model/member_model.dart';

class AuthRepo {
  static final instance = AuthRepo._();

  AuthRepo._();

  final usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> createAccount(PingUserModel pingUser, String password) async {
    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: pingUser.email,
      password: password,
    );
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw Exception('t_failedToCreateUser'.tr());
    }
    await firebaseUser.sendEmailVerification();
    await usersCollection.doc(firebaseUser.uid).set(pingUser.toJson());
  }

  Future<void> createAccountWithoutPassword(String userId, PingUserModel user) async {
    await usersCollection.doc(userId).set(user.toJson());
  }

  Future<void> updateOnlineStatus(String id, bool isOnline) async {
    try {
      // PingLog.pingLog("keyOnlineStatus: $isOnline");
      // PingLog.pingLog("keyLastSeen: ${FieldValue.serverTimestamp()}");
      PingLog.pingLog("id: $id");
      await usersCollection.doc(id).update({
        PingUserModel.keyOnlineStatus: isOnline,
        PingUserModel.keyLastSeen: FieldValue.serverTimestamp(),
      }).then((value) {
        PingLog.pingLog("updating team lead online status $isOnline");
      });
    } catch (e, s) {
      PingLog.pingLog("error: $e $s");
    }
  }

  Future<PingUserModel?> getUserById(String id) async {
    final userDoc = await usersCollection.doc(id).get();
    final data = userDoc.data();
    if (!userDoc.exists || data == null) {
      return null;
    }
    return PingUserModel.fromJson(userDoc.id, data);
  }

  Stream<PingUserModel?> getUserStreamById(String id) {
    return usersCollection.doc(id).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        return null;
      }
      return PingUserModel.fromJson(doc.id, data);
    });
  }

  Future<void> updateName(String id, String key, String name) async {
    if (key != PingUserModel.keyFullName && key != PingUserModel.keyTeamName && key != PingUserModel.keyInitials) {
      throw Exception('t_invalidKey'.tr());
    }
    await usersCollection.doc(id).update({key: name});
  }

  Future<void> updateFcmToken(String userId, String fcmToken) async {
    try {
      debugPrint("fcm Token $fcmToken");
      final docRef = usersCollection.doc(userId);
      final docSnapshot = await docRef.get();
      var device = '';
      if(kIsWeb){
        device = 'Web';
      }
      else{
        if(Platform.isAndroid){
          device = 'Android';
        }
        else if(Platform.isIOS){
          device = 'iOS';
        }
        else{
          device = 'Other';
        }
      }
      var fcmEntity = FcmEntity(token: fcmToken, device: device);
      if (docSnapshot.exists) {
        // Ensure the field exists before accessing it
        List<FcmEntity> existingTokens = [];
        // if (docSnapshot.data() != null && docSnapshot.data()!.containsKey(PingUserModel.keyFcmToken)) {
        //   existingTokens = List.from(docSnapshot.get(PingUserModel.keyFcmToken));
        // }

        if (docSnapshot.data() != null &&
            docSnapshot.data()!.containsKey(PingUserModel.keyFcmToken)) {
          List<dynamic> rawList = docSnapshot.get(PingUserModel.keyFcmToken);
          existingTokens = rawList
              .map((item) => FcmEntity.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }

        // Check if fcmToken already exists
        bool alreadyExists = existingTokens.any((t) => t.token == fcmToken);

        if (alreadyExists) {
          debugPrint("token is already exist");
        } else {
          await docRef.update({
            PingUserModel.keyFcmToken: FieldValue.arrayUnion([fcmEntity.toJson()])
          });
        }
      } else {
        // If document doesn't exist, create it with the first entry
        await docRef.set({
          PingUserModel.keyFcmToken: [fcmEntity.toJson()]
        });
      }
    } catch (e) {
      PingLog.pingLog("updateFcmToken: $e");
    }
  }

  Future<void> updateDialogTimer(String userId, int timer) async{
    try{
      final docRef = usersCollection.doc(userId);
      final docSnapshot = await docRef.get();
      if(docSnapshot.exists){
        await docRef.update({
          'dialogTimer': timer
        });
      }
    }
    catch(e){
      PingLog.pingLog("updateDialogTimer: $e");
    }
  }


  Future<void> deleteUser() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.delete();
      await usersCollection.doc(user.uid).delete();
    }
  }

  Future<int> getDialogTimer(String userId) async{
    int dialogTimer = 5;
    var user = await getUserById(userId);
    if(user != null){
      dialogTimer = user.dialogTimer;
    }
    else{
      final memberRef = FirebaseFirestore.instance.collection('members').doc(userId);
      var memberSnapshot = await memberRef.get();
      if(memberSnapshot.exists){
        var json = memberSnapshot.data() as Map<String, dynamic>;
        var member = json['teamLeadId'];
        var aUser = await getUserById(member);
        if(aUser != null){
          dialogTimer = aUser.dialogTimer;
        }
      }
    }
    return dialogTimer;
  }

}
