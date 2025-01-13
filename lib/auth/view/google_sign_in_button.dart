import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/repo/app_lifecycle_service.dart';
import 'package:ping_app/auth/view/complete_profile_view.dart';
import 'package:ping_app/dashboard/dashboard_view.dart';
import 'package:ping_app/util/fcm_repo.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_log.dart';

class GoogleSignInButton extends StatelessWidget {
  final void Function() onSignedIn;

  const GoogleSignInButton({super.key, required this.onSignedIn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        onPressed: () => _handleGoogleSignIn(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Image(
                image: AssetImage("assets/images/google.png"),
                height: 18.0,
                width: 18.0,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 8),
                child: Text(
                  't_signInWithGoogle'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    PingLog.pingLog("---handleGoogleSignIn function start---");
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        PingLog.pingLog("---Google user is null. Sign-in canceled by user.---");
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        PingLog.pingLog("---Firebase user is null after sign-in.---");
        return;
      }

      if (context.mounted) {
        final userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          AppLifecycleService().reset();
          AppLifecycleService()
              .initialize(isMember: false, userId: firebaseUser.uid);
          FcmRepo.instance.updateTeamLeadFcmToken(firebaseUser.uid);
          replaceAll(const DashboardView());
        } else {
          push(CompleteProfileView(firebaseUser: firebaseUser));
        }
      }
      onSignedIn();
    } catch (e, stackTrace) {
      PingLog.pingLog("---Error during Google sign-in: $e $stackTrace---");
      snack("An error occurred during sign-in. Please try again.");
    }
    PingLog.pingLog("---handleGoogleSignIn function end---");
  }
}
