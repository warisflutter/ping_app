import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:ping_app/util/ping_styles.dart';
import 'package:ping_app/util/ping_utils.dart';
import 'package:ping_app/view/settings/repo/setting_repo.dart';
import 'package:ping_app/widgets/base_widget.dart';
import 'package:ping_app/widgets/global_layout_builder.dart';
import 'package:ping_app/widgets/ping_text_field.dart';

class MessageAddEditView extends StatefulWidget {
  final String? originalMessage;

  const MessageAddEditView({super.key, this.originalMessage});

  @override
  State<MessageAddEditView> createState() => _MessageAddEditViewState();
}

class _MessageAddEditViewState extends State<MessageAddEditView> {
  final message = TextEditingController();
  bool loading = false;

  bool get isEditing => widget.originalMessage != null;

  @override
  void initState() {
    super.initState();
    message.text = widget.originalMessage ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return BaseWidget(
      key: const Key("messageAddEditView"),
      title: Text(
        isEditing ? 't_editMessageTemplate'.tr() : 't_addMessageTemplate'.tr(),
        style: (context.isWatch) ? PingStyles.watchStyle : null,
      ),
      body: SafeArea(
        child: GlobalLayoutBuilder(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PingTextField(
                  key: const Key("textFieldMessage"),
                  hintText: 't_enterYourMessageHere'.tr(),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  controller: message,
                  readOnly: loading,
                ),
                SizedBox(height: (context.isWatch) ? 10.0 : 32),
                (loading)
                    ? getLoader()
                    : SizedBox(
                        height: (context.isWatch) ? PingStyles.watchButtonHeight : null,
                        child: ElevatedButton(
                          key: const Key("buttonAddUpdate"),
                          onPressed: () async {
                            final isConnected = await context.isInternetAvailable();
                            if (isConnected) {
                              addOrUpdateMessageAction();
                            } else {
                              snack("t_noInternetPleaseConnectToTheInternet".tr());
                            }
                          },
                          child: Text(
                            isEditing ? 't_update'.tr() : 't_add'.tr(),
                            style: (context.isWatch) ? PingStyles.watchStyle : null,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // void addMessageAction() async {
  //   if (message.text.isEmpty) {
  //     snack("Please enter the message");
  //     return;
  //   }
  //
  //   setState(() => loading = true);
  //   try {
  //     await SettingRepo.instance.addMessage(message.text);
  //     pop();
  //   } catch (e) {
  //     snack(e);
  //   }
  //   setState(() => loading = false);
  // }

  void addOrUpdateMessageAction() async {
    if (message.text.isEmpty) {
      snack('t_pleaseEnterTheMessage'.tr());
      return;
    }

    if (isEditing && message.text == widget.originalMessage) {
      pop();
      return;
    }

    setState(() => loading = true);
    try {
      if (isEditing) {
        await SettingRepo.instance.updateMessage(widget.originalMessage!, message.text);
      } else {
        String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
        FirebaseFirestore.instance.collection('message_templates');
        await SettingRepo.instance.addMessage(message.text);
      }
      pop();
    } catch (e, s) {
      PingLog.pingLog("error: $e");
      PingLog.pingLog("error: $s");
      snack(e);
    }
    setState(() => loading = false);
  }
}
