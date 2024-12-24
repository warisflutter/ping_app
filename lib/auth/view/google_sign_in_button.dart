import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:ping_app/auth/repo/ping_auth_state.dart';
import 'package:ping_app/auth/view/complete_profile_view.dart';
import 'package:ping_app/dashboard/dashboard_view.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:provider/provider.dart';

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
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final res = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = Provider.of<PingAuthState>(context, listen: false).currentFirebaseUser;
      if (res.user != null) {
        debugPrint("email: ${res.user?.email}");
        debugPrint("phoneNumber: ${res.user?.phoneNumber}");
        final userDoc = await FirebaseFirestore.instance.collection("users").doc(firebaseUser!.uid).get();
        if (userDoc.exists) {
          replaceAll(const DashboardView());
        } else {
          replace(CompleteProfileView(firebaseUser: firebaseUser));
        }
      }

      onSignedIn();
    } catch (e) {
      snack(e);
    }
  }
}
