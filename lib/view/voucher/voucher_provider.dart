import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:ping_app/view/voucher/voucher_model.dart';

class VoucherProvider extends ChangeNotifier {
  List<VoucherModel> displayedVouchers = [];
  int approveOrReject = 0;
  bool loader = false;
  final voucher = FirebaseFirestore.instance.collection("pro_users");
  List<String> voucherStatus = [
    "Pending",
    "Approved",
    "Rejected",
  ];
  final codeTEC = TextEditingController();

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
    try {
      if (codeTEC.text.isNotEmpty) {
        String code = codeTEC.text;
        DateTime now = DateTime.now();
        final isNoCodeFound =
            await FirebaseFirestore.instance.collection("subscription").where("id", isEqualTo: code).get();
        if (isNoCodeFound.docs.isEmpty) {
          pop();
          snack("no voucher code found", info: false);
          return;
        }
        final isVoucherFound = await voucher.where("userId", isEqualTo: userId).where("code", isEqualTo: code).get();
        if (isVoucherFound.docs.isNotEmpty) {
          pop();
          snack("voucher is already applied", info: false);
          return;
        }
        String type = "";
        if (code == "basic_monthly" || code == "basic_yearly") {
          type = "Basic";
        } else if (code == "expert_monthly" || code == "expert_yearly") {
          type = "Export";
        } else {
          type = "Pro";
        }
        await voucher.add({
          "code": code,
          "type": type,
          "userId": userId,
          "createdAt": now.toIso8601String(),
        });
        if (context.mounted) {
          Navigator.pop(context);
          codeTEC.clear();
        }
        snack("Voucher applied successfully.");
      } else {
        snack("Voucher code is empty");
      }
    } catch (e) {
      debugPrint("Error applying for voucher: $e");
    }
  }

  Future<String> fetchVoucher() async {
    String data = "";
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    try {
      // Fetch vouchers for the user
      QuerySnapshot querySnapshot = await voucher.where("userId", isEqualTo: userId).get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          String createdAt = doc.get("createdAt");
          String code = doc.get("code");
          String type = doc.get("type");

          if (createdAt.isNotEmpty) {
            DateTime approvedAtDate = DateTime.parse(createdAt);
            bool isOlderThan90Days = isApprovedAtOlderThan90Days(approvedAtDate);

            if (isOlderThan90Days) {
              // Check all voucher types for expiration
              List<String> voucherTypes = [
                "basic_monthly",
                "basic_yearly",
                "expert_monthly",
                "expert_yearly",
                "pro_monthly",
                "pro_yearly"
              ];

              bool voucherFound = false;

              for (String voucherType in voucherTypes) {
                QuerySnapshot voucherQuery =
                    await voucher.where("userId", isEqualTo: userId).where("code", isEqualTo: voucherType).get();

                if (voucherQuery.docs.isNotEmpty) {
                  // If voucher is found and not expired
                  data = "Voucher is Not Expire|$type";
                  voucherFound = true;
                  break;
                }
              }

              if (!voucherFound) {
                // If no active voucher is found
                data = "Voucher is Expire|$type";
              }
            } else {
              // Voucher is not older than 90 days
              data = "Voucher is Not Expire|$type";
            }

            break; // Exit loop after processing the first valid voucher
          }
        }
      } else {
        // No vouchers found
        data = "No vouchers found for the user.";
        PingLog.pingLog(data);
      }
    } catch (e) {
      // Log any errors
      debugPrint("Error fetching vouchers: $e");
      data = "Error occurred while fetching vouchers.";
    }

    return data;
  }

  // Future<String> fetchVoucher() async {
  //   String data = "";
  //   String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  //   QuerySnapshot querySnapshot = await voucher.where("userId", isEqualTo: userId).get();
  //   if (querySnapshot.docs.isNotEmpty) {
  //     for (var doc in querySnapshot.docs) {
  //       String createdAt = doc.get("createdAt");
  //       String type = doc.get("type");
  //       if (createdAt.isNotEmpty) {
  //         DateTime approvedAtDate = DateTime.parse(createdAt);
  //         bool isOlderThan90Days = isApprovedAtOlderThan90Days(approvedAtDate);
  //         if (isOlderThan90Days) {
  //           String code = doc.get("code");
  //           QuerySnapshot basicMonthly =
  //               await voucher.where("userId", isEqualTo: userId).where("basic_monthly", isEqualTo: code).get();
  //           if (basicMonthly.docs.isNotEmpty) {
  //             for (var doc1 in basicMonthly.docs) {
  //               String type = doc1.get("type");
  //               data = "Voucher is Not Expire|$type";
  //             }
  //             break;
  //           }
  //           QuerySnapshot basicYearly =
  //               await voucher.where("userId", isEqualTo: userId).where("basic_yearly", isEqualTo: code).get();
  //           QuerySnapshot querySnapshot =
  //               await voucher.where("userId", isEqualTo: userId).where("expert_monthly", isEqualTo: code).get();
  //           QuerySnapshot querySnapshot =
  //               await voucher.where("userId", isEqualTo: userId).where("expert_yearly", isEqualTo: code).get();
  //           QuerySnapshot querySnapshot =
  //               await voucher.where("userId", isEqualTo: userId).where("pro_yearly", isEqualTo: code).get();
  //           QuerySnapshot querySnapshot =
  //               await voucher.where("userId", isEqualTo: userId).where("pro_monthly", isEqualTo: code).get();
  //           data = "Voucher is Expire|$type";
  //           break;
  //         } else {
  //           data = "Voucher is Not Expire|$type";
  //           break;
  //         }
  //       }
  //     }
  //   } else {
  //     data = "";
  //     PingLog.pingLog("No vouchers found for the user.");
  //   }
  //   return data;
  // }

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
