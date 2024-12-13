import 'package:easy_localization/easy_localization.dart';

String? mandatoryValidator(String? input) {
  return input != null && input.isNotEmpty ? null : 't_required'.tr();
}

String? userNameValidator(String? input) {
  if (input == null || input.isEmpty) {
    return 't_userNameIsRequired'.tr();
  }
  if (input.length > 8) {
    return 't_userName8Characters'.tr();
  }
  if (input.contains(" ")) {
    return 't_userNameContainSpace'.tr();
  }
  if (input.contains(RegExp(r'[A-Z]'))) {
    return 't_userNameCaseLetters'.tr();
  }
  if (input.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
    return 't_userNameSpecialCharacters'.tr();
  }
  return null;
}

String? intValidator(String? input) {
  try {
    int.parse(input ?? '');
    return null;
  } catch (e) {
    return 't_enterAValidNumber'.tr();
  }
}

String? passwordValidator(String? input) {
  return input != null && input.isNotEmpty
      ? input.length > 7
          ? RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])').hasMatch(input)
              ? null
              : 't_bothUpperCharactersRequired'.tr()
          : 't_8OrCharactersRequired'.tr()
      : 't_passwordIsRequired'.tr();
}

String? emailValidator(String? input) {
  final RegExp emailRegex = RegExp(r"""
^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))$""");
  return input != null && emailRegex.hasMatch(input)
      ? null
      : 't_enterCorrectEmailAddress'.tr();
}

String? phoneValidator(String? input) {
  final RegExp phoneRegex = RegExp(r'^\+?[0-9]{10,}$');
  return input != null && phoneRegex.hasMatch(input)
      ? null
      : 't_enterCorrectPhoneNumber'.tr();
}

