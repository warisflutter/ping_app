import 'package:flutter/material.dart';
import 'package:ping_app/view/check_payment/check_payment_provider.dart';
import 'package:provider/provider.dart';

class CheckPaymentScreen extends StatelessWidget {
  const CheckPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckPaymentProvider>(
      builder: (_, provider, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                provider.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
