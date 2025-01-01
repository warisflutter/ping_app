import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LinkedProfilesScreen extends StatefulWidget {
  const LinkedProfilesScreen({super.key});

  @override
  State<LinkedProfilesScreen> createState() => _LinkedProfilesScreenState();
}

class _LinkedProfilesScreenState extends State<LinkedProfilesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('t_linkedProfiles'.tr()),
      ),
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return Center(child: Text('t_noUserSignedIn'.tr()));
          }
          final user = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildEmailPasswordCard(user),
              const SizedBox(height: 16),
              _buildGoogleProfileCard(user),
              const SizedBox(height: 16),
              _buildAppleProfileCard(user),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmailPasswordCard(User user) {
    final hasPassword =
        user.providerData.any((provider) => provider.providerId == 'password');
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.email),
            title: Text('t_emailPassword'.tr()),
            subtitle: Text(user.email ?? 't_noEmail'.tr()),
            trailing: hasPassword
                ? const Icon(Icons.check_circle, color: Colors.green)
                : TextButton(
                    onPressed: () => _showSetPasswordDialog(context),
                    child: Text('t_setPassword'.tr()),
                  ),
          ),
        ],
      ),
    );
  }

  void _showSetPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('t_setPassword'.tr()),
        content: TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(hintText: 't_enterNewPassword'.tr()),
        ),
        actions: [
          TextButton(
            child: Text('t_cancel'.tr()),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('t_set'.tr()),
            onPressed: () async {
              if (_passwordController.text.isNotEmpty) {
                await _setPassword(_passwordController.text);
                pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _setPassword(String password) async {
    try {
      await _auth.currentUser?.updatePassword(password);
      setState(() {});
    } catch (e) {
      snack('${'t_errorSettingPassword'.tr()}: $e');
    }
  }

  Widget _buildGoogleProfileCard(User user) {
    late UserInfo? googleProvider;
    try {
      googleProvider = user.providerData
          .firstWhere((provider) => provider.providerId == 'google.com');
    } catch (e) {
      googleProvider = null;
    }
    final googleLinked = googleProvider != null;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.android),
        title: Text('t_google'.tr()),
        subtitle: Text(
          googleLinked
              ? googleProvider.email ?? 't_noEmail'.tr()
              : 't_notLinked'.tr(),
        ),
        trailing: googleLinked
            ? const Icon(Icons.check_circle, color: Colors.green)
            : TextButton(
                onPressed: _linkGoogleAccount,
                child: Text('t_link'.tr()),
              ),
      ),
    );
  }

  Widget _buildAppleProfileCard(User user) {
    late UserInfo? appleProvider;
    try {
      appleProvider = user.providerData
          .firstWhere((provider) => provider.providerId == 'apple.com');
    } catch (e) {
      appleProvider = null;
    }
    final appleLinked = appleProvider != null;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.apple),
        title: Text('t_apple'.tr()),
        subtitle: Text(
          appleLinked
              ? appleProvider.email ?? 't_noEmail'.tr()
              : 't_notLinked'.tr(),
        ),
        trailing: appleLinked
            ? const Icon(Icons.check_circle, color: Colors.green)
            : TextButton(
                onPressed: _linkAppleAccount,
                child: Text('t_link'.tr()),
              ),
      ),
    );
  }

  Future<void> _linkGoogleAccount() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.currentUser?.linkWithCredential(credential);
        setState(() {});
      }
    } catch (e) {
      snack(e);
    }
  }

  Future<void> _linkAppleAccount() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      await _auth.currentUser?.linkWithCredential(oauthCredential);
      setState(() {});
    } catch (e) {
      snack(e);
      // Show error message to user
    }
  }
}
