import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifySubscriptionView extends StatelessWidget {
  const VerifySubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('t_subscribeToAPackage'.tr())),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Row(),
            Text(
              't_youAreAndSubscribe'.tr(),
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      outlinedButtonTheme: OutlinedButtonThemeData(
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(Colors.red),
                          side: WidgetStateProperty.all(
                            const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                    child: OutlinedButton(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      child: Text('t_logout'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
