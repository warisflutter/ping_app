import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:ping_app/dashboard/dashboard_view.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/validator.dart';

class CompleteProfileView extends StatefulWidget {
  final User firebaseUser;

  const CompleteProfileView({super.key, required this.firebaseUser});

  @override
  State<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final initials = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('t_completeYourProfile'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                TextFormField(
                  controller: _teamNameController,
                  decoration: InputDecoration(
                    labelText: 't_teamName'.tr(),
                    prefixIcon: const Icon(Icons.group),
                  ),
                  validator: mandatoryValidator,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.person),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: 't_initials'.tr(),
                          counterText: "",
                        ),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        validator: (s) => s?.length == 3
                            ? null
                            : 't_provide3CharacterInitial'.tr(),
                        controller: initials,
                        maxLength: 3,
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: 't_fullName'.tr(),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: mandatoryValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? getLoader()
                    : ElevatedButton(
                        onPressed: _updateProfile,
                        child: Text('t_updateProfile'.tr()),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final updatedUser = PingUserModel(
          type: "user",
          teamName: _teamNameController.text,
          initials: initials.text,
          fullName: _fullNameController.text,
          email: widget.firebaseUser.email ?? 't_noEmail'.tr(),
        );
        await AuthRepo.instance.createAccountWithoutPassword(
          widget.firebaseUser.uid,
          updatedUser,
        );
        widget.firebaseUser.reload();
        replaceAll(const DashboardView());
      } catch (e) {
        snack('${'t_failedToUpdateProfile'.tr()}: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }
}
