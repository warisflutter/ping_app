import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/services/firebase_service.dart';
import 'package:ping_app/view/subscription/purchased_view.dart';
import 'package:provider/provider.dart';

class VoucherProvider extends ChangeNotifier {
  bool loader = false;
  final FirebaseService firebaseService = FirebaseService();
  final codeTEC = TextEditingController();
  final globalKey = GlobalKey<FormState>();

  Future applyForVoucher({
    required BuildContext context,
  }) async {
    try {
      String code = codeTEC.text;
      final isValid = RegExp(r'^[A-Z0-9]{20}$').hasMatch(code);
      if (!isValid) {
        snack("Invalid voucher code format. Please enter a valid code.");
        return;
      }
      updateLoader(true);
      QuerySnapshot isCodeExist =
          await firebaseService.voucherCollection.where("code", isEqualTo: code).get();
      if (isCodeExist.docs.isEmpty) {
        updateLoader(false);
        snack("Voucher Code is Not Exist.");
        return;
      }

      QuerySnapshot querySnapshot = await firebaseService.voucherCollection
          .where("isUsed", isEqualTo: false)
          .where("code", isEqualTo: code)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = querySnapshot.docs.first;
        if (context.mounted) {
          final subsProvider = Provider.of<SubscriptionProvider>(
            context,
            listen: false,
          );
          if (subsProvider.purChasedModel == null) {
            await doc.reference.update({
              "isUsed": true,
              "usedAt": DateTime.now().toIso8601String(),
              "userId": firebaseService.userId,
            });
            updateLoader(false);
            replace(const PurchasedView(fromApply: true));
            snack(
              "🎉 Voucher applied successfully! Enjoy your benefits.",
              backgroundColor: Colors.green,
            );
          } else {
            updateLoader(false);
            snack("Please cancel your current subscription before applying a voucher.");
          }
        }
      } else {
        updateLoader(false);
        snack(" Voucher has already been used.");
      }
    } catch (e, st) {
      updateLoader(false);
      PingLog.pingLog("Apply Voucher Error: $e $st");
    }
  }

  void updateLoader(bool value) {
    loader = value;
    notifyListeners();
  }

  @override
  void dispose() {
    codeTEC.clear();
    super.dispose();
  }
}
