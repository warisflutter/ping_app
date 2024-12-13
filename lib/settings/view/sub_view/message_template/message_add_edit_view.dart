import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/settings/repo/setting_repo.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';

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
    return Scaffold(
      key: Key("messageAddEditView"),
      appBar: AppBar(
        title: Text(
          isEditing ? 't_editMessageTemplate'.tr() : 't_addMessageTemplate'.tr(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                key: Key("textFieldMessage"),
                decoration:  InputDecoration(
                  hintText: 't_enterYourMessageHere'.tr(),
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                controller: message,
                readOnly: loading,
              ),
              const SizedBox(height: 32),
              loading
                  ? getLoader()
                  : ElevatedButton(
                      key: Key("buttonAddUpdate"),
                      onPressed: () => addOrUpdateMessageAction(),
                      child: Text(isEditing ? 't_update'.tr() : 't_add'.tr()),
                    ),
            ],
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
        await SettingRepo.instance
            .updateMessage(widget.originalMessage!, message.text);
      } else {
        await SettingRepo.instance.addMessage(message.text);
      }
      pop();
    } catch (e) {
      snack(e);
    }
    setState(() => loading = false);
  }
}
