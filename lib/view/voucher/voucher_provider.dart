import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/view/voucher/voucher_model.dart';

class VoucherProvider extends ChangeNotifier {
  List<VoucherModel> userVouchers = [];
  int approveOrReject = 0;
  final voucher = FirebaseFirestore.instance.collection("vouchers");
  List<String> voucherStatus = [
    "Pending",
    "Approve",
    "Reject",
  ];
  List<String> subscriptions = [
    "ping_basic_subscription",
    "ping_export_subscription",
    "ping_pro_subscription",
  ];
  void setApproveOrReject(int value) {
    approveOrReject = value;
    notifyListeners();
  }

  Future<void> applyForVoucher(BuildContext context) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    QuerySnapshot querySnapshot = await voucher.where("userId", isEqualTo: userId).get();
    if (querySnapshot.docs.isNotEmpty) {
      debugPrint("User has already applied for a voucher.");
      if (context.mounted) {
        Navigator.pop(context);
      }
      snack("User has already applied for a voucher.", info: false);
      return;
    }
    try {
      await voucher.add({
        "status": "0",
        "userId": userId,
        "createdAt": DateTime.now().toString(),
      });
      if (context.mounted) {
        Navigator.pop(context);
      }
      debugPrint("Voucher applied successfully.");
    } catch (e) {
      debugPrint("Error applying for voucher: $e");
    }
  }

  Future<void> fetchVoucher() async {
    try {
      QuerySnapshot querySnapshot = await voucher.get();
      userVouchers = await Future.wait(querySnapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] ?? "";
        final pingUser = await AuthRepo.instance.getUserById(userId);

        return VoucherModel(
          voucherId: doc.id,
          userId: userId,
          createdAt: data['createdAt'] ?? "",
          pingUserModel: pingUser ?? PingUserModel.empty(),
          status: data['status'],
        );
      }).toList());
      debugPrint("Fetched ${userVouchers.length} vouchers for the user.");
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching vouchers: $e");
    }
  }

  Future<void> updateVoucherStatus(String voucherId, String newStatus) async {
    try {
      await voucher.doc(voucherId).update({
        'status': newStatus,
      }).then((value) {
        fetchVoucher();
      });
    } catch (e) {
      debugPrint("Error updating voucher status: $e");
    }
  }

  fetchSubscriptions() {}
}
