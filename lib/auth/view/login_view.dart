import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/file_path.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool loading = false;
  final _formKey = GlobalKey<FormState>();

  final email = TextEditingController(
    text: kDebugMode ? "apptweak.hafiz@gmail.com" : "",
  );

  final password = TextEditingController(
    text: kDebugMode ? "Ping123456" : "",
  );

  @override
  Widget build(BuildContext context) {
    final mainSpacing = context.screenHeight * 0.05;
    final screenHeight = context.screenHeight;
    bool addTopPadding = screenHeight > maxDesktopHeight;

    return Scaffold(
      key: const Key("loginView"),
      appBar: AppBar(title: const Text("")),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 8.0,
            ),
            child: Center(
              child: SizedBox(
                width: mobileWidth,
                child: Column(
                  children: [
                    if (kIsWeb && addTopPadding) SizedBox(height: mainSpacing),
                    getLogo(context),
                    SizedBox(height: mainSpacing),
                    Text(
                      't_signInYourAccount'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: mainSpacing),
                    getForm(),
                    SizedBox(height: mainSpacing),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        loading
                            ? getLoader()
                            : ElevatedButton(
                                key: const Key("buttonSignIn"),
                                onPressed: () => _onSignInClicked(),
                                child: Text('t_signIn'.tr()),
                              ),
                        TextButton(
                          onPressed: () => _onForgotPasswordClicked(),
                          child: Text('t_forgotYourPassword'.tr()),
                        ),
                        const SizedBox(height: 40),
                        GoogleSignInButton(onSignedIn: () => pop()),
                        const SizedBox(height: 16),
                        (Platform.isIOS) ? AppleSignInButton(onSignedIn: () => pop()) : const SizedBox.shrink(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getTermsAndPolicy(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(text: 't_byContinuingToOur'.tr()),
            WidgetSpan(
              child: InkWell(
                onTap: () {},
                child: Text(
                  't_termsOfService'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                ),
              ),
            ),
            TextSpan(text: ' ${"and".tr()} '),
            WidgetSpan(
              child: InkWell(
                onTap: () {},
                child: Text(
                  't_privacyPolicy'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            key: const Key("inputEmail"),
            decoration: InputDecoration(
              hintText: 't_email'.tr(),
              prefixIcon: const Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: emailValidator,
            controller: email,
            readOnly: loading,
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key("inputPassword"),
            decoration: InputDecoration(
              hintText: 't_password'.tr(),
              prefixIcon: const Icon(Icons.lock),
            ),
            keyboardType: TextInputType.text,
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: passwordValidator,
            controller: password,
            readOnly: loading,
          ),
        ],
      ),
    );
  }

  Widget getLogo(BuildContext context) {
    return Image.asset('assets/images/logo.png', height: 120);
  }

  void _onSignInClicked() async {
    final validated = _formKey.currentState?.validate() ?? false;
    if (!validated) return;

    final email = this.email.text;
    final password = this.password.text;

    setState(() => loading = true);
    try {
      final ref = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = ref.user?.uid;
      final res = await FirebaseFirestore.instance.collection("users").doc(uid).get();
      if (uid == null) {
        snack('t_errorAccountTheUser'.tr());
      } else if (res["type"] == "admin") {
        replaceAll(const AdminView());
      } else {
        AppLifecycleService().reset();
        AppLifecycleService().initialize(isMember: false, userId: uid);
        final firebaseUser = FirebaseAuth.instance.currentUser;
        FirebaseNotificationService().updateTeamLeadFcmToken(firebaseUser!.uid);
        replaceAll(const DashboardView());
      }
    } catch (e) {
      snack(e);
    }
    setState(() => loading = false);
  }

  void _onForgotPasswordClicked() async {
    final email = this.email.text;
    if (email.isEmpty) {
      snack('t_pleaseEnterEmailAddress'.tr());
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      snack('${'t_passwordResetEmailSent'.tr()}: $email');
    } catch (e) {
      snack(e);
    }
  }
}
