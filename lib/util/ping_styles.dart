import 'package:flutter/material.dart';

class PingStyles {
  static TextStyle _watchStyle({
    double? fontSize,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize ?? 8.0,
      color: color,
    );
  }

  static TextStyle get watchStyle => _watchStyle();
  static double get watchIconSize => 12.0;
  static double get watchTextFieldHeight => 30.0;
  static double get watchButtonHeight => 25.0;
  static double get watchLogoHeight => 30.0;
}
