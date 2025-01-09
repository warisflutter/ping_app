import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ping_app/file_path.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInButton extends StatelessWidget {
  final void Function() onSignedIn;

  const AppleSignInButton({
    super.key,
    required this.onSignedIn,
  });

  @override
  Widget build(BuildContext context) {
    return SignInWithAppleButton(
      borderRadius: BorderRadius.circular(40),
      onPressed: () => signInWithApple(context),
    );
  }

  Future<void> signInWithApple(BuildContext context) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: Platform.isAndroid
            ? WebAuthenticationOptions(
                clientId:
                    'com.googleusercontent.apps.607056826389-6dugrh1bl521559ga4nljlsjnub9nqi8',
                redirectUri: Uri.parse(
                  'https://pingapp-94e13.firebaseapp.com/__/auth/handler',
                ),
              )
            : null,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        PingLog.pingLog("---Firebase user is null after sign-in.---");
        return;
      }
      if (context.mounted) {
        final userDoc =
            await FirebaseFirestore.instance.collection("users").doc(firebaseUser.uid).get();
        if (userDoc.exists) {
          AppLifecycleService().reset();
          AppLifecycleService().initialize(isMember: false, userId: firebaseUser.uid);
          FcmRepo.instance.updateTeamLeadFcmToken(firebaseUser.uid);
          replaceAll(const DashboardView());
        } else {
          push(CompleteProfileView(firebaseUser: firebaseUser));
        }
      }
      onSignedIn();
    } catch (e) {
      snack(e);
    }
  }
}
