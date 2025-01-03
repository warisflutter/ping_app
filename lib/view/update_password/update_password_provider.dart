import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_log.dart';

class UpdatePasswordProvider extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  bool _loading = false;
  bool get loading => _loading;

  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<void> updatePassword(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      snack('t_userIsTheApp'.tr());
      return;
    }

    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setLoading(true);
    try {
      await user.updatePassword(password.text);
      pop();
      snack('t_passwordUpdatedSuccessfully'.tr(), info: true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // if (context.mounted) {
        // _showReAuthenticateDialog(context, user);
        // }
      } else {
        PingLog.pingLog("Update Password Error: $e");
        snack(e);
      }
    } finally {
      setLoading(false);
    }
  }

  Future<void> _showReAuthenticateDialog(
    BuildContext context,
    User user,
  ) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('t_reAuthenticate'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 't_email'.tr()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 't_password'.tr()),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => pop(),
              child: Text('t_cancel'.tr()),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();

                try {
                  final credential = EmailAuthProvider.credential(
                    email: email,
                    password: password,
                  );
                  await user.reauthenticateWithCredential(credential);
                  pop();
                  if (context.mounted) {
                    await updatePassword(context);
                  }
                } on FirebaseAuthException catch (e) {
                  snack(e.message ?? 'Reauthentication failed');
                }
              },
              child: Text('t_confirm'.tr()),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }
}
