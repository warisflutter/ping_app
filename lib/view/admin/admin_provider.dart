import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminProvider extends ChangeNotifier {
  String? type;
  bool loader = false;
  int approveOrReject = 0;

  AdminProvider() {
    getAdmin();
  }
  Future<void> getAdmin() async {
    loader = true;
    notifyListeners();

    String? adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null || adminId.isEmpty) {
      debugPrint("Admin ID is null or empty. User may not be authenticated.");
      loader = false;
      notifyListeners();
      return;
    }

    try {
      final res = await FirebaseFirestore.instance.collection("users").doc(adminId).get();
      if (res.exists) {
        type = res.data()?["type"];
        debugPrint("Admin type: $type");
        notifyListeners();
      } else {
        debugPrint("No admin document found for ID: $adminId");
      }
    } catch (e) {
      debugPrint("Error fetching admin data: $e");
    } finally {
      loader = false;
      notifyListeners();
    }
  }

  void setApproveOrReject(int value) {
    approveOrReject = value;
    notifyListeners();
  }
}
