import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PingDialogs {
  static void showVoucherDialog({
    required BuildContext context,
    required void Function() applyVoucher,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("t_applyVoucher".tr()),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "t_addRequestForVoucher".tr(),
                textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("t_cancel".tr()),
            ),
            ElevatedButton(
              onPressed: () {
                applyVoucher();
              },
              child: Text("t_apply".tr()),
            ),
          ],
        );
      },
    );
  }
}
