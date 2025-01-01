import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';
import 'package:ping_app/util/ping_log.dart';

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
      PingLog.pingLog("keyOnlineStatus: $isOnline");
      PingLog.pingLog("keyLastSeen: ${FieldValue.serverTimestamp()}");
      PingLog.pingLog("id: ${id}");

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

  Future<void> updateFcmToken(String id, String fcmToken) async {
    await usersCollection.doc(id).update({PingUserModel.keyFcmToken: fcmToken});
  }

  Future<void> deleteUser(String id) async {
    await usersCollection.doc(id).update({PingUserModel.keyIsDeleted: true});
  }
}
