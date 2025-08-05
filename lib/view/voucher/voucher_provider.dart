import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/models/voucher_model.dart';
import 'package:ping_app/services/firebase_service.dart';
import 'package:ping_app/view/subscription/purchased_view.dart';
import 'package:provider/provider.dart';
import 'dart:math';
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
      // final isValid = RegExp(r'^[A-Z0-9]{20}$').hasMatch(code);
      final user = FirebaseAuth.instance.currentUser;
      if(user == null){
        snack('User not authenticated', backgroundColor: Colors.red);
        return;
      }
      final isValid = RegExp(r'^[A-Z0-9]+$').hasMatch(code.toUpperCase());
      if (!isValid) {
        await firebaseService.updateRateLimit(user.uid, false);
        await firebaseService.logVoucherActivity(
          action: 'redemption_attempt',
          userId: user.uid,
          voucherCode: code,
          successful: false,
          errorMessage: 'Invalid code format',
        );
        snack("Invalid voucher code format. Please enter a valid code.");
        return;
      }

      updateLoader(true);
      bool canAttempt = await firebaseService.checkRateLimit(user.uid);
      if (!canAttempt) {
        await firebaseService.logVoucherActivity(
          action: 'redemption_attempt',
          userId: user.uid,
          voucherCode: code,
          successful: false,
          errorMessage: 'Rate limit exceeded',
        );
        snack('Too many attempts. Please wait before trying again.', backgroundColor: Colors.red);
        updateLoader(false);
        return;
      }
      QuerySnapshot isCodeExist =
          await firebaseService.voucherCollection.where("code", isEqualTo: code.toUpperCase()).limit(1).get();
      if (isCodeExist.docs.isEmpty) {
        updateLoader(false);
        await firebaseService.updateRateLimit(user.uid, false);
        await firebaseService.logVoucherActivity(
          action: 'redemption_attempt',
          userId: user.uid,
          voucherCode: code,
          successful: false,
          errorMessage: 'Voucher not found',
        );
        snack("Voucher Code not found");
        updateLoader(false);
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
              "usedAt": FieldValue.serverTimestamp(),
              "usedBy": firebaseService.userId,
              "status": VoucherStatus.used.name,
            });
            updateLoader(false);
            await firebaseService.updateRateLimit(user.uid, true);
            await firebaseService.logVoucherActivity(
              action: 'redemption_success',
              userId: user.uid,
              voucherCode: code,
              voucherId: querySnapshot.docs.first.id,
              successful: true,
            );
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
        await firebaseService.updateRateLimit(user.uid, false);
        await firebaseService.logVoucherActivity(
          action: 'redemption_attempt',
          userId: user.uid,
          voucherCode: code,
          successful: false,
          errorMessage: 'Voucher already used',
        );
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
