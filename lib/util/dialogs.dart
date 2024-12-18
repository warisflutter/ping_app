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
          title: const Text("Apply Voucher"),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add Request for Voucher",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                applyVoucher();
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }
}
