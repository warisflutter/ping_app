import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:ping_app/view/voucher/voucher_model.dart';

class VoucherProvider extends ChangeNotifier {
  List<VoucherModel> displayedVouchers = [];
  int approveOrReject = 0;
  bool loader = false;
  final voucher = FirebaseFirestore.instance.collection("vouchers");
  List<String> voucherStatus = [
    "Pending",
    "Approved",
    "Rejected",
  ];

  List<String> selectedVoucherType = [];
  List<String> selectedVoucherStatus = [];
  void setVoucherType(String value, int index) {
    selectedVoucherType[index] = value;
    PingLog.pingLog("selectedVoucherType ${selectedVoucherType[index]}");
    notifyListeners();
  }

  void setVoucherStatus(String value, int index) {
    selectedVoucherStatus[index] = value;
    PingLog.pingLog("selectedVoucherStatus ${selectedVoucherStatus[index]}");
    notifyListeners();
  }

  setStatusAndType({
    required String type,
    required int index,
    required String status,
  }) {
    selectedVoucherType = List.generate(index, (index) {
      return type;
    });
    selectedVoucherStatus = List.generate(index, (index) {
      return status;
    });
    notifyListeners();
  }

  void setApproveOrReject(int value) {
    approveOrReject = value;
    fetchVouchers();
    notifyListeners();
  }

  Future initAdmin() async {
    loader = true;
    await fetchVouchers();
    loader = false;
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
        "status": "Pending",
        "userId": userId,
        "approvedAt": "Basic",
        "createdAt": DateTime.now().toString(),
      });
      if (context.mounted) {
        Navigator.pop(context);
      }
      snack("Voucher applied successfully.");
    } catch (e) {
      debugPrint("Error applying for voucher: $e");
    }
  }

  Future<String> fetchVoucher() async {
    String data = "";
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    QuerySnapshot querySnapshot =
        await voucher.where("userId", isEqualTo: userId).where("status", isEqualTo: "Approved").get();
    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        String approvedAt = doc.get("approvedAt");
        String type = doc.get("type");
        if (approvedAt.isNotEmpty) {
          DateTime approvedAtDate = DateTime.parse(approvedAt);
          bool isOlderThan90Days = isApprovedAtOlderThan90Days(approvedAtDate);
          if (isOlderThan90Days) {
            data = "Voucher is Expire";
            break;
          } else {
            data = "Voucher is Not Expire|$type";
            break;
          }
        }
      }
    } else {
      data = "";
      PingLog.pingLog("No vouchers found for the user.");
    }
    return data;
  }

  bool isApprovedAtOlderThan90Days(DateTime approvedAt) {
    DateTime currentDate = DateTime.now();
    DateTime date90DaysAgo = currentDate.subtract(const Duration(days: 90));
    return approvedAt.isBefore(date90DaysAgo);
  }

  Future<void> fetchVouchers() async {
    try {
      QuerySnapshot querySnapshot = await voucher.get();
      List<VoucherModel> userVouchers = await Future.wait(querySnapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] ?? "";
        final pingUser = await AuthRepo.instance.getUserById(userId);

        return VoucherModel(
          type: data['type'] ?? "",
          voucherId: doc.id,
          userId: userId,
          createdAt: data['createdAt'] ?? "",
          pingUserModel: pingUser ?? PingUserModel.empty(),
          status: data['status'],
        );
      }).toList());
      final pendingVouchers = userVouchers.where((voucher) => voucher.status == "Pending").toList();
      final rejectedVouchers = userVouchers.where((voucher) => voucher.status == "Rejected").toList();
      final approvedVouchers = userVouchers.where((voucher) => voucher.status == "Approved").toList();
      displayedVouchers = (approveOrReject == 0)
          ? pendingVouchers
          : (approveOrReject == 1)
              ? approvedVouchers
              : rejectedVouchers;

      selectedVoucherType = List.generate(displayedVouchers.length, (index) {
        return displayedVouchers[index].type;
      });
      selectedVoucherStatus = List.generate(displayedVouchers.length, (index) {
        return displayedVouchers[index].status;
      });

      debugPrint("Fetched ${userVouchers.length} vouchers for the user.");
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching vouchers: $e");
    }
  }

  Future<void> updateVoucher(String voucherId, int index) async {
    try {
      await voucher.doc(voucherId).update({
        'status': selectedVoucherStatus[index],
        'type': selectedVoucherType[index],
        'approvedAt': (selectedVoucherStatus[index] == "Approved") ? '${DateTime.now()}' : '',
      }).then((value) {
        fetchVouchers();
      });
    } catch (e) {
      debugPrint("Error updating voucher status: $e");
    }
  }
}
