import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:purchases_flutter/models/entitlement_info_wrapper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionRepo {
  static final instance = SubscriptionRepo._();

  SubscriptionRepo._();

  final subscriptionCollection =
      FirebaseFirestore.instance.collection('subscriptions');

  void setSubscriptionStatus(String userId, EntitlementInfo? status) {
    if (status == null) {
      subscriptionCollection.doc(userId).delete();
      return;
    }
    subscriptionCollection.doc(userId).set(status.toJson());
  }

  Future<EntitlementInfo?> getSubscriptionStatus(String userId) async {
    final doc = await subscriptionCollection.doc(userId).get();
    final data = doc.data();
    return data != null ? EntitlementInfo.fromJson(data) : null;
  }

  Stream<EntitlementInfo?> getSubscriptionStatusStream(String userId) {
    return subscriptionCollection.doc(userId).snapshots().map((doc) {
      final data = doc.data();
      return data != null ? EntitlementInfo.fromJson(data) : null;
    });
  }
}
