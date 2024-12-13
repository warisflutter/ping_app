import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInButton extends StatelessWidget {
  final void Function() onSignedIn;

  const AppleSignInButton({super.key, required this.onSignedIn});

  @override
  Widget build(BuildContext context) {
    return SignInWithAppleButton(
      borderRadius: BorderRadius.circular(40),
      onPressed: () => signInWithApple(),
    );
  }

  Future<void> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: Platform.isAndroid
            ? WebAuthenticationOptions(
                clientId:
                    'com.googleusercontent.apps.29322079000-5k0ir5mavjs27epo561hkup8ie1jk6qo',
                redirectUri: Uri.parse(
                  'https://pingapp-17ef7.firebaseapp.com/__/auth/handler',
                ),
              )
            : null,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      onSignedIn();
    } catch (e) {
      snack(e);
    }
  }
}
