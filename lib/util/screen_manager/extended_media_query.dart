import 'package:flutter/material.dart';
import 'package:ping_app/util/screen_manager/constants.dart';

class Screen {}

extension MediaQueryExtension on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;

  bool get isLargeLaptop => screenSize.width >= largeLaptopWidth;

  bool get isLaptop =>
      screenSize.width >= laptopWidth && screenSize.width < largeLaptopWidth;

  bool get isTabletOrPhone => screenSize.width < laptopWidth;

  bool get isPhone => screenSize.width < tabletWidth;


  double get eighthWidth => screenSize.width / 8;

  double get fourthWidth => screenSize.width / 4;
}
