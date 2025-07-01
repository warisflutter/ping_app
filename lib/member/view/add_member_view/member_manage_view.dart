import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/repo/ping_auth_state.dart';
import 'package:ping_app/member/model/member_model.dart';
import 'package:ping_app/member/repo/member_repo.dart';
import 'package:ping_app/member/view/add_member_view/member_qr_code.dart';
import 'package:ping_app/member/view/member_color_dialog.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_utils.dart';
import 'package:ping_app/util/validator.dart';
import 'package:ping_app/widgets/global_layout_builder.dart';
import 'package:provider/provider.dart';

class MemberManageView extends StatefulWidget {
  final MemberModel? member;

  const MemberManageView({super.key, this.member});

  @override
  State<MemberManageView> createState() => _MemberManageViewState();
}

class _MemberManageViewState extends State<MemberManageView> {
  final formState = GlobalKey<FormState>();
  bool loading = false;
  final memberName = TextEditingController();
  final initials = TextEditingController();

  Color? memberColor;

  bool get isUpdateView => widget.member != null;

  @override
  void initState() {
    memberName.text = widget.member?.name ?? "";
    initials.text = widget.member?.initials ?? "";
    memberColor = widget.member?.memberColor;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: isUpdateView ? Text('t_updateMemberName'.tr()) : Text('t_enterMemberName'.tr())),
      body: SafeArea(
        child: GlobalLayoutBuilder(
          child: Form(
            key: formState,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          controller: initials,
                          decoration: InputDecoration(
                            hintText: 't_initials'.tr(),
                            counterText: "",
                          ),
                          validator: (s) {
                            return s?.length == 3 ? null : 't_provide3LetterInitials'.tr();
                          },
                          maxLength: 3,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextFormField(
                          controller: memberName,
                          validator: mandatoryValidator,
                          decoration: InputDecoration(
                            hintText: 't_enterMembersName'.tr(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MemberColorSelectorView(
                      onColorSelected: (color) => setState(() => memberColor = color),
                      initialColor: memberColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  (loading)
                      ? getLoader()
                      : ElevatedButton(
                          onPressed: () async {
                            bool isInternet = await context.isInternetAvailable();
                            if (isInternet) {
                              if (isUpdateView) {
                                updateMemberAction();
                              } else if (!isUpdateView) {
                                addMemberAction();
                              }
                            } else {
                              if (context.mounted) {
                                snack(context.pingString("t_noInternetPleaseConnectToTheInternet"));
                              }
                            }
                          },
                          child: (isUpdateView) ? Text('t_updateMember'.tr()) : Text('t_addMember'.tr()),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> addMemberAction() async {
    final validated = formState.currentState?.validate() ?? false;
    if (!validated) {
      return;
    }
    final pingUser = context.read<PingAuthState>().currentPingUser;
    if (pingUser == null) {
      snack('t_userNotTheApp'.tr());
      return;
    }
    setState(() => loading = true);
    try {
      final member = MemberModel(
        name: memberName.text,
        initials: initials.text,
        teamLeadId: pingUser.userId,
        memberColor: memberColor,
      );
      final id = await MemberRepo.instance.addMember(member);
      replace(MemberQrCode(memberId: id));
    } catch (e) {
      snack(e);
    }
    setState(() => loading = false);
  }

  void updateMemberAction() async {
    final validated = formState.currentState?.validate() ?? false;
    if (!validated) {
      return;
    }
    final member = widget.member;
    if (member == null) {
      snack('t_invalidStateNotFound'.tr());
      return;
    }
    try {
      await MemberRepo.instance.updateMember(
        member.id,
        member.copyWith(
          initials: initials.text,
          name: memberName.text,
          memberColor: memberColor,
        ),
      );
      pop();
    } catch (e) {
      snack(e);
    }
  }
}
