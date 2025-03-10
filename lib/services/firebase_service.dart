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

  CollectionReference<Map<String, dynamic>> get usersCollection => firebaseFireStore.collection("users");

  Future<void> saveUserDetailsAfterBuySubscription({
    required PurChasedModel purchasedModel,
  }) async {
    try {
      // Save the PurChasedModel data in the user's document in Firestore
      await usersCollection.doc(userId).set({
        'subscription': purchasedModel.toMap(),
        'subscriptionDate': DateTime.now().toIso8601String(),
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
}
