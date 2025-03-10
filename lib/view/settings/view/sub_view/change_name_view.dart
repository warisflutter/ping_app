import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:ping_app/auth/repo/ping_auth_state.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_utils.dart';
import 'package:provider/provider.dart';

enum ChangeNameMode {
  fullName,
  teamName,
}

extension ChangeNameModeExt on ChangeNameMode {
  String get title {
    switch (this) {
      case ChangeNameMode.fullName:
        return 't_fullName'.tr();
      case ChangeNameMode.teamName:
        return 't_teamName'.tr();
    }
  }

  String get firebaseKey {
    switch (this) {
      case ChangeNameMode.fullName:
        return PingUserModel.keyFullName;
      case ChangeNameMode.teamName:
        return PingUserModel.keyTeamName;
    }
  }
}

class ChangeNameView extends StatefulWidget {
  final ChangeNameMode mode;

  const ChangeNameView({super.key, required this.mode});

  @override
  State<ChangeNameView> createState() => _ChangeNameViewState();
}

class _ChangeNameViewState extends State<ChangeNameView> {
  final name = TextEditingController();
  final initials = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    Future.delayed(Duration.zero, () => loadName());
    super.initState();
  }

  void loadName() {
    final user = context.read<PingAuthState>().currentPingUser;
    if (user != null) {
      name.text = widget.mode == ChangeNameMode.fullName ? user.fullName : user.teamName;
      initials.text = user.initials;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key("viewChangeName"),
      appBar: AppBar(title: Text("${widget.mode.title} ${'t_changeYour'.tr()}")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.mode == ChangeNameMode.fullName)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextFormField(
                    key: const Key("inputInitials"),
                    decoration: InputDecoration(
                      hintText: 't_initials'.tr(),
                      counterText: "",
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    validator: (s) => s?.length == 3 ? null : 't_provide3CharacterInitial'.tr(),
                    maxLength: 3,
                    controller: initials,
                  ),
                ),
              TextField(
                key: const Key("inputName"),
                controller: name,
                readOnly: loading,
                decoration: InputDecoration(
                  hintText: "${'t_enterYour'.tr()} ${widget.mode.title}",
                ),
              ),
              const SizedBox(height: 24),
              Builder(
                key: const Key("buttonUpdate"),
                builder: (context) {
                  return loading
                      ? getLoader()
                      : ElevatedButton(
                          onPressed: () async {
                            bool isInternet = await context.isInternetAvailable();
                            if (isInternet) {
                              if (context.mounted) {
                                final authState = context.read<PingAuthState>();
                                updateName(authState);
                              }
                            } else {
                              if (context.mounted) {
                                snack(context.pingString("t_noInternetPleaseConnectToTheInternet"));
                              }
                            }
                          },
                          child: Text('t_update'.tr()),
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void updateName(PingAuthState state) async {
    final userId = state.currentFirebaseUser?.uid;
    if (userId == null) {
      snack('t_userIsTheApp'.tr());
      return;
    }
    if (name.text.isEmpty) {
      snack("${'t_pleaseEnterThe'.tr()} ${widget.mode.title}");
      return;
    }

    if (widget.mode == ChangeNameMode.fullName && initials.text.length != 3) {
      snack('t_pleaseProvideCharacterInitials'.tr());
      return;
    }

    setState(() => loading = true);
    try {
      if (widget.mode == ChangeNameMode.fullName) {
        await AuthRepo.instance.updateName(
          userId,
          PingUserModel.keyInitials,
          initials.text,
        );
      }

      await AuthRepo.instance.updateName(
        userId,
        widget.mode.firebaseKey,
        name.text,
      );

      await state.reloadPingUser();
      pop();
    } catch (e) {
      snack(e);
    }
    setState(() => loading = false);
  }
}
