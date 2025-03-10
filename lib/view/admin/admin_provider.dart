import 'dart:async';
import 'dart:math';
import 'dart:developer' as log;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';
import 'package:ping_app/models/voucher_model.dart';
import 'package:ping_app/services/firebase_service.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/ping_log.dart';

class AdminProvider extends ChangeNotifier {
  String? type;
  bool loader = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  DocumentSnapshot? lastDocument;

  List<VoucherModel> vouchersList = [];
  Duration remainingTime = Duration.zero;
  Timer? timer;
  final FirebaseService firebaseService = FirebaseService();

  AdminProvider() {
    debugPrint("AdminProvider init");
    startCountDown();
  }

  Future<void> getAdmin() async {
    loader = true;
    String? adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null || adminId.isEmpty) {
      debugPrint("Admin ID is null or empty. User may not be authenticated.");
      loader = false;
      return;
    }

    try {
      final res = await FirebaseFirestore.instance.collection("users").doc(adminId).get();
      if (res.exists) {
        type = res.data()?["type"];
        debugPrint("Admin type: $type");
      } else {
        debugPrint("No admin document found for ID: $adminId");
      }
    } catch (e) {
      debugPrint("Error fetching admin data: $e");
    } finally {
      loader = false;
    }
    notifyListeners();
  }

  Future generateVoucher() async {
    updateLoader(true);
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    Set<String> vouchers = {};
    while (vouchers.length < 10) {
      String code = List.generate(20, (index) => chars[random.nextInt(chars.length)]).join();
      vouchers.add(code);
    }
    debugPrint("Generated Vouchers: $vouchers");
    QuerySnapshot existingVouchers = await firebaseService.voucherCollection.get();
    Set<String> existingCodes = existingVouchers.docs.map((doc) => doc['code'] as String).toSet();

    // Remove Already Existing Vouchers
    vouchers.removeWhere((code) => existingCodes.contains(code));
    if (vouchers.isEmpty) {
      snack("No new vouchers generated. All exist in Firestore.");
      updateLoader(false);
      return;
    }

    // Use Batch Write for Efficiency
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (String code in vouchers) {
      DocumentReference docRef = firebaseService.voucherCollection.doc(); // Auto-generate ID
      batch.set(docRef, {
        'code': code,
        'createdAt': DateTime.now().toIso8601String(),
        'isUsed': false,
      });
    }

    await batch.commit(); // Execute Firestore batch write

    snack(
      "${vouchers.length} New Vouchers Generated Successfully!",
      backgroundColor: Colors.green,
    );

    await fetchVouchers();
    updateLoader(false);
  }

  Future<void> fetchVouchers({
    bool isLoadMore = false,
    bool isRefreshIndicator = false,
  }) async {
    if (isLoadMore) {
      if (!hasMore || isLoadingMore) return;
      isLoadingMore = true;
    } else {
      if (!isRefreshIndicator) {
        updateLoader(true);
      }
      lastDocument = null;
      vouchersList.clear();
    }

    try {
      Query query = firebaseService.voucherCollection.limit(10);
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      QuerySnapshot snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;
        List<VoucherModel> newVouchers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return VoucherModel(
            voucherId: doc.id,
            userId: data['userId'] ?? '',
            createdAt: data['createdAt'] ?? '',
            status: "",
            type: "",
            code: data['code'] ?? '',
            isUsed: data['isUsed'] ?? false,
            pingUserModel: PingUserModel.empty(),
          );
        }).toList();

        vouchersList.addAll(newVouchers);
        hasMore = newVouchers.length == 10;
      } else {
        hasMore = false;
      }
      debugPrint("Fetched vouchers: ${vouchersList.length}");
    } catch (e) {
      debugPrint("Error fetching vouchers: $e");
    }

    if (isLoadMore) {
      isLoadingMore = false;
    } else {
      updateLoader(false);
    }
    notifyListeners();
  }

  copyVoucherCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    snack("Copied to clipboard", backgroundColor: Colors.green);
  }

  void updateLoader(bool value) {
    loader = value;
    notifyListeners();
  }

  bool isApprovedAtOlderThan30Days(DateTime approvedAt) {
    DateTime currentDate = DateTime.now();
    log.log("current Data: $currentDate");
    log.log("approvedAt: $approvedAt");
    DateTime date30DaysAgo = currentDate.subtract(const Duration(days: 30));
    return approvedAt.isBefore(date30DaysAgo);
  }

  Future<String> fetchVoucher() async {
    String data = "";
    try {
      String id = FirebaseAuth.instance.currentUser?.uid ?? "";
      QuerySnapshot querySnapshot = await firebaseService.voucherCollection
          .where("userId", isEqualTo: id)
          .where("isUsed", isEqualTo: true)
          .get();
      log.log("userId: ${firebaseService.userId}");
      if (querySnapshot.docs.isNotEmpty) {
        if (querySnapshot.docs.isNotEmpty) {
          for (var doc in querySnapshot.docs) {
            String usedAt = doc.get("usedAt");
            log.log("userId: ${firebaseService.userId}");
            DateTime approvedAtDate = DateTime.parse(usedAt);
            bool isOlderThan30Days = isApprovedAtOlderThan30Days(approvedAtDate);
            if (isOlderThan30Days) {
              data = "Voucher is Expire|Pro";
            } else {
              data = "Voucher is Not Expire|Pro";
            }
          }
        }
      } else {
        data = "";
      }
    } catch (e, st) {
      PingLog.pingLog("Fetch Voucher Error: $e $st");
      data = "";
    }
    PingLog.pingLog("fetch voucher: $data");
    return data;
  }

  Future<void> startCountDown() async {
    try {
      QuerySnapshot querySnapshot = await firebaseService.firebaseFireStore
          .collection("vouchers")
          .where("userId", isEqualTo: firebaseService.userId)
          .where("isUsed", isEqualTo: true)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          String usedAt = doc.get("usedAt");
          DateTime usedAtDate = DateTime.parse(usedAt);

          // Define expiration time (e.g., 30 days from `usedAt`)
          DateTime expiryDate = usedAtDate.add(Duration(days: 30));

          _startTimer(expiryDate);
        }
      }
    } catch (e, st) {
      debugPrint("Error: $e $st");
    }
  }

  void _startTimer(DateTime expiryDate) {
    timer?.cancel(); // Cancel any existing timer

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final remaining = expiryDate.difference(now);

      if (remaining.isNegative) {
        remainingTime = Duration.zero;
        timer.cancel();
      } else {
        remainingTime = remaining;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    timer!.cancel();
    super.dispose();
  }
}
