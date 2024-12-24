import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/view/login_view.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';

class VerifyEmailView extends StatefulWidget {
  final User user;

  const VerifyEmailView({super.key, required this.user});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    final email = user.email;
    if (email == null) {
      return getErrorMessage(context, 't_emailIsNotAvailable'.tr());
    }

    return Scaffold(
      appBar: AppBar(title: Text('t_verifyYourEmail'.tr())),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('t_anEmailSentTo'.tr()),
              const SizedBox(height: 8),
              Text(email, style: Theme.of(context).textTheme.titleLarge),
            ]),
            loading
                ? getLoader()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => refreshAction(user),
                            icon: const Icon(Icons.refresh),
                            label: Text('t_refresh'.tr()),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => resendEmailAction(user),
                              child: Text('t_resendEmail'.tr()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Theme(
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
                                onPressed: () => logoutAction(),
                                child: Text('t_logout'.tr()),
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> resendEmailAction(User user) async {
    setState(() => loading = true);
    try {
      await user.sendEmailVerification();
      snack("Verification link is resent to your email", info: true);
    } catch (e) {
      snack(e);
    }
    setState(() => loading = false);
  }

  Future<void> logoutAction() async {
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      snack(e);
    }
    setState(() => loading = false);
  }

  Future<void> refreshAction(User user) async {
    setState(() => loading = true);
    try {
      await user.reload();
      if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
        // Navigate to login view if email is verified
        replace(const LoginView());
      } else {
        // Show a message if the email is not verified
        snack("Your email is not verified yet. Please verify your email.");
      }
    } catch (e) {
      snack(e);
    }
    setState(() => loading = false);
  }
}
