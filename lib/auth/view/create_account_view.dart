import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:ping_app/auth/repo/ping_auth_state.dart';
import 'package:ping_app/auth/view/apple_sign_in_button.dart';
import 'package:ping_app/auth/view/captcha_view.dart';
import 'package:ping_app/auth/view/google_sign_in_button.dart';
import 'package:ping_app/auth/view/login_view.dart';
import 'package:ping_app/auth/view/verify_email_view.dart';
import 'package:ping_app/member/view/join_member_view/join_id_view.dart';
import 'package:ping_app/member/view/join_member_view/join_qr_view.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/screen_manager/constants.dart';
import 'package:ping_app/util/validator.dart';
import 'package:provider/provider.dart';

class CreateAccountView extends StatefulWidget {
  const CreateAccountView({super.key});

  @override
  State<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends State<CreateAccountView> {
  bool loading = false;
  final _formKey = GlobalKey<FormState>();
  final teamName = TextEditingController();
  final fullName = TextEditingController();
  final initials = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mainSpacing = MediaQuery.of(context).size.height * 0.05;
    final screenHeight = MediaQuery.of(context).size.height;
    bool addTopPadding = screenHeight > maxDesktopHeight;
    return Scaffold(
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
                      't_createNewAccount'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: mainSpacing),
                    getForm(),
                    SizedBox(height: mainSpacing),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        getTermsAndPolicy(context),
                        const SizedBox(height: 12),
                        (loading)
                            ? getLoader()
                            : ElevatedButton(
                                onPressed: () => _onCreateAccountClicked(),
                                child: Text('t_createAccount'.tr()),
                              ),
                        const SizedBox(height: 8),
                        if (!kIsWeb)
                          OutlinedButton(
                            onPressed: (loading) ? null : () => _onScanQrCodeClick(),
                            child: Text('t_scanQrCode'.tr()),
                          )
                        else
                          OutlinedButton(
                            onPressed: loading ? null : () => _onJoinByIdClick(),
                            child: Text('t_joinById'.tr()),
                          ),
                        GoogleSignInButton(onSignedIn: () {}),
                        const SizedBox(height: 4),
                        (Platform.isIOS) ? AppleSignInButton(onSignedIn: () {}) : const SizedBox.shrink(),
                        const SizedBox(height: 12),
                        getAlreadyHaveAccount(context),
                        const SizedBox(height: 12),
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
                onTap: loading ? null : () {},
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
                onTap: loading ? null : () {},
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

  Widget getAlreadyHaveAccount(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(text: 't_alreadyHaveAnAccount'.tr()),
          const TextSpan(text: ' '),
          WidgetSpan(
            child: InkWell(
              onTap: () => push(const LoginView()),
              child: Text(
                't_login'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(
              hintText: 't_teamName'.tr(),
              prefixIcon: const Icon(Icons.group),
            ),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            validator: mandatoryValidator,
            controller: teamName,
            readOnly: loading,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: 't_initials'.tr(),
                    counterText: '',
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  validator: (s) => s?.length == 3 ? null : 't_provide3CharacterInitial'.tr(),
                  controller: initials,
                  maxLength: 3,
                  readOnly: loading,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: 't_fullName'.tr(),
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  validator: mandatoryValidator,
                  controller: fullName,
                  readOnly: loading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
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
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              hintText: 't_confirmPassword'.tr(),
              prefixIcon: const Icon(Icons.lock),
            ),
            obscureText: true,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value != password.text) {
                return 't_passwordsDoNotMatch'.tr();
              }
              return null;
            },
            readOnly: loading,
          ),
        ],
      ),
    );
  }

  Widget getLogo(BuildContext context) {
    return Builder(builder: (context) {
      return Image.asset(
        'assets/images/ping_gif.gif',
        height: 120,
        fit: BoxFit.cover,
      );
    });
  }

  void _onCreateAccountClicked() async {
    final validated = _formKey.currentState?.validate() ?? false;
    if (!validated) {
      return;
    }

    final captchaVerified = await showDialog(context: context, builder: (context) => const CaptchaAlertDialog());

    if (!captchaVerified) {
      snack('t_invalidCaptcha'.tr());
      return;
    }

    final model = PingUserModel(
      type: "user",
      teamName: teamName.text,
      initials: initials.text,
      fullName: fullName.text,
      email: email.text,
    );
    setState(() => loading = true);
    try {
      await AuthRepo.instance.createAccount(model, password.text);
      final firebaseUser = FirebaseAuth.instance.currentUser;
      push(VerifyEmailView(user: firebaseUser!));
      snack(
        't_accountCreatedAndLogin'.tr(),
        info: true,
        key: const Key("successMessage"),
      );
    } catch (e) {
      snack(e);
    }
    setState(() => loading = false);
  }

  void _onScanQrCodeClick() {
    push(const JoinQrView());
  }

  void _onJoinByIdClick() {
    push(const JoinIdView());
  }
}
