import 'package:flutter/material.dart';
import 'package:ping_app/util/ping_styles.dart';
import 'package:ping_app/util/ping_utils.dart';

class PingTextField extends StatelessWidget {
  final String hintText;
  final IconData? prefixIcon;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? counterText;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final bool readOnly;
  final bool? obscureText;
  final void Function(String)? onChanged;
  const PingTextField({
    super.key,
    this.readOnly = false,
    required this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.controller,
    this.obscureText,
    this.maxLength,
    this.counterText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (context.isWatch) ? PingStyles.watchTextFieldHeight : null,
      child: TextFormField(
        onChanged: onChanged,
        maxLength: maxLength,
        decoration: InputDecoration(
          counterText: counterText,
          hintText: hintText,
          prefixIcon: (prefixIcon == null)
              ? null
              : Icon(
                  prefixIcon,
                  size: (context.isWatch) ? PingStyles.watchIconSize : null,
                ),
        ),
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        obscureText: obscureText ?? false,
        controller: controller,
        readOnly: readOnly,
        style: (context.isWatch) ? PingStyles.watchStyle : null,
      ),
    );
  }
}
