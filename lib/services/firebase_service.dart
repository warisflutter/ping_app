import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/view/subscription/subscription_provider.dart';

class FirebaseService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFireStore = FirebaseFirestore.instance;

  User? get firebaseUser => firebaseAuth.currentUser;

  String get userId => firebaseAuth.currentUser?.uid ?? "";

  CollectionReference<Map<String, dynamic>> get voucherCollection => firebaseFireStore.collection("vouchers");
  CollectionReference get rateLimitCollection => firebaseFireStore.collection('voucher_rate_limits');
  CollectionReference get voucherLogsCollection => firebaseFireStore.collection('voucher_logs');

  CollectionReference<Map<String, dynamic>> get usersCollection => firebaseFireStore.collection("users");

  String webClientId = "565573250233-b4kc3mid8u9prjldftss6q8jefsnnjbv.apps.googleusercontent.com";
  String get webClientIdGetter => webClientId;
  String vapidKey = "BPwJA3iKctTT8t1LRA9TDvGW5iXax_h-0J5JQSXF2yblQSN4rpJW48qvsRdC_y7WIGci3KYT5_FxEloc3kGu_Jg";
  String get vapidKeyGetter => vapidKey;
  Future<void> saveUserDetailsAfterBuySubscription({
    required PurChasedModel purchasedModel,
  }) async {
    try {
      // Save the PurChasedModel data in the user's document in Firestore
      await usersCollection.doc(userId).set({
        'subscription': purchasedModel.toMap(),
        'subscriptionDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Optionally: You can add additional data or actions after saving the user's details.
      debugPrint("User details and subscription data saved successfully!");
    } catch (e) {
      debugPrint("Error saving user details after subscription: $e");
      snack("Error saving user details. Please try again.");
    }
  }

  Future<PurChasedModel?> getUserSubscriptionDetails() async {
    try {
      DocumentSnapshot userDoc = await usersCollection.doc(userId).get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('subscription')) {
          return PurChasedModel.fromMap(data['subscription']);
        }
      }
      return null; // No subscription found
    } catch (e) {
      debugPrint("Error fetching user subscription details: $e");
      return null;
    }
  }

  Future<void> removeUserSubscription() async {
    try {
      await usersCollection.doc(userId).update({
        'subscription': FieldValue.delete(),
        'subscriptionDate': FieldValue.delete(),
      });

      debugPrint("User subscription removed successfully!");
    } catch (e) {
      debugPrint("Error removing user subscription: $e");
      snack("Error removing subscription. Please try again.");
    }
  }

  // Check rate limiting
  Future<bool> checkRateLimit(String userId) async {
    try {
      DocumentSnapshot rateLimitDoc = await rateLimitCollection.doc(userId).get();

      if (!rateLimitDoc.exists) {
        return true; // First attempt
      }

      Map<String, dynamic> data = rateLimitDoc.data() as Map<String, dynamic>;
      DateTime lastAttempt = (data['lastAttempt'] as Timestamp).toDate();
      int dailyAttempts = data['dailyAttempts'] ?? 0;
      DateTime dailyResetTime = (data['dailyResetTime'] as Timestamp).toDate();

      // DateTime now = DateTime.now();
      DateTime now = await getServerTime();
      // Reset daily counter if 24 hours have passed
      if (now.difference(dailyResetTime).inHours >= 24) {
        await rateLimitCollection.doc(userId).set({
          'dailyAttempts': 0,
          'dailyResetTime': Timestamp.fromDate(now),
          'lastAttempt': Timestamp.fromDate(now),
        });
        return true;
      }

      // Check if 1 minute has passed since last attempt
      if (now.difference(lastAttempt).inMinutes < 1) {
        return false; // Too soon
      }

      // Check daily limit
      if (dailyAttempts >= 5) {
        return false; // Daily limit exceeded
      }

      return true;
    } catch (e) {
      debugPrint("Rate limit check error: $e");
      return false; // Fail safe
    }
  }

  // Update rate limiting
  Future<void> updateRateLimit(String userId, bool successful) async {
    try {
      DocumentSnapshot rateLimitDoc = await rateLimitCollection.doc(userId).get();
      // DateTime now = DateTime.now();
      DateTime now = await getServerTime();
      if (rateLimitDoc.exists) {
        Map<String, dynamic> data = rateLimitDoc.data() as Map<String, dynamic>;
        int dailyAttempts = data['dailyAttempts'] ?? 0;
        DateTime dailyResetTime = (data['dailyResetTime'] as Timestamp).toDate();

        // Reset if 24 hours passed
        if (now.difference(dailyResetTime).inHours >= 24) {
          dailyAttempts = 0;
          dailyResetTime = now;
        }

        await rateLimitCollection.doc(userId).set({
          'dailyAttempts': dailyAttempts + 1,
          'dailyResetTime': Timestamp.fromDate(dailyResetTime),
          'lastAttempt': Timestamp.fromDate(now),
          'lastAttemptSuccessful': successful,
        });
      } else {
        await rateLimitCollection.doc(userId).set({
          'dailyAttempts': 1,
          'dailyResetTime': Timestamp.fromDate(now),
          'lastAttempt': Timestamp.fromDate(now),
          'lastAttemptSuccessful': successful,
        });
      }
    } catch (e) {
      debugPrint("Rate limit update error: $e");
    }
  }

  // Log voucher activity
  Future<void> logVoucherActivity({
    required String action,
    required String userId,
    String? voucherCode,
    String? voucherId,
    bool? successful,
    String? errorMessage,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await voucherLogsCollection.add({
        'action': action, // 'redemption_attempt', 'redemption_success', 'generation', etc.
        'userId': userId,
        'voucherCode': voucherCode, // Mask code for security
        'voucherId': voucherId,
        'successful': successful,
        'errorMessage': errorMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': null, // Add if available
        'userAgent': null, // Add if available
        'additionalData': additionalData,
      });
    } catch (e) {
      debugPrint("Logging error: $e");
    }
  }

  Future<DateTime> getServerTime() async {
    final docRef = FirebaseFirestore.instance.collection('serverTime').doc('time');
    await docRef.set({'timestamp': FieldValue.serverTimestamp()});
    final snapshot = await docRef.get();
    final serverTimestamp = snapshot.data()?['timestamp'] as Timestamp?;
    return serverTimestamp == null ? DateTime.now() : serverTimestamp.toDate();

  }


}
