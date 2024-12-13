// File: test_driver/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:ping_app/main.dart' as app;

void main() {
  // This line enables the extension
  enableFlutterDriverExtension();
  WidgetsFlutterBinding.ensureInitialized();

  app.main();
}

//flutter drive --target=test_driver/app.dart --driver=test_driver/auth_test.dart
//flutter drive --target=test_driver/app.dart --driver=test_driver/settings_test.dart

// flutter build ios --release --no-codesign
// flutter drive --use-application-binary=build/ios/iphonesimulator/Runner.app \
// --target=test_driver/app.dart \
// --driver=test_driver/auth_test.dart
