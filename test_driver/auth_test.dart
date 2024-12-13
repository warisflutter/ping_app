// File: test_driver/auth_test.dart

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
import 'dart:math';

import 'util.dart';

void main() {
  group('Authentication Tests', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
      await Future.delayed(const Duration(seconds: 5));
    });

    tearDownAll(() async {
      driver.close();
    });

    test('Fill and submit create account form', () async {
      await driver.waitFor(find.byValueKey("createAccountView"));
      // Generate random 4 digits for email
      final random = Random();
      final randomDigits = random.nextInt(9000) + 1000;

      // Find and fill the form fields
      await driver.tap(find.byValueKey('teamNameField'));
      await driver.enterText('Andios');
      await Future.delayed(const Duration(seconds: 1));

      await driver.tap(find.byValueKey('initialsField'));
      await driver.enterText('KBA');
      await Future.delayed(const Duration(seconds: pauseDuration));

      await driver.tap(find.byValueKey('fullNameField'));
      await driver.enterText('Kamran Bashir');
      await Future.delayed(const Duration(seconds: pauseDuration));

      await driver.tap(find.byValueKey('emailField'));
      await driver
          .enterText('kamran.bashir.arain+drive_$randomDigits@gmail.com');
      await Future.delayed(const Duration(seconds: pauseDuration));

      await driver.tap(find.byValueKey('passwordField'));
      await driver.enterText('Lahore123@');
      await Future.delayed(const Duration(seconds: pauseDuration));

      await driver.tap(find.byValueKey('confirmPasswordField'));
      await driver.enterText('Lahore123@');
      await Future.delayed(const Duration(seconds: pauseDuration));

      // Tap the create account button
      await driver.tap(find.byValueKey('createAccountButton'));

      await driver.waitFor(find.byValueKey('verifyCaptchaButton'));
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('verifyCaptchaButton'));

      await driver.waitFor(
        find.byValueKey("loginView"),
        timeout: const Duration(seconds: 10),
      );
      await Future.delayed(const Duration(seconds: 3));
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.pageBack());
      await driver.waitFor(find.byValueKey("createAccountView"));
    }, timeout: const Timeout(Duration(minutes: 5)));

    test("Login, Logout and Change Password Test", () async {
      await loginFromCreateAccView(driver);
      await driver.waitFor(find.byValueKey("dashboardView"));
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('tabSettings'));
      await driver.waitFor(find.byValueKey('settingView'));
      // Click the change password button
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('buttonChangePassword'));
      await driver.waitFor(find.byValueKey('viewUpdatePassword'));

      // Enter the new password in both fields
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('inputPassword'));
      await driver.enterText('Andios2015%');
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('inputConfirmPassword'));
      await driver.enterText('Andios2015%');

      // Press the update password button
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('buttonUpdatePassword'));

      await driver.waitFor(find.byValueKey("dashboardView"));
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('tabSettings'));
      await driver.waitFor(find.byValueKey('settingView'));
      await Future.delayed(const Duration(seconds: pauseDuration));
      await logoutFromDashboard(driver);
      await Future.delayed(const Duration(seconds: pauseDuration));
      await loginFromCreateAccView(driver, password: "Andios2015%");
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.waitFor(find.byValueKey("dashboardView"));
      await driver.tap(find.byValueKey('tabSettings'));
      await driver.waitFor(find.byValueKey('settingView'));

      // Now change the password back to the original
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('buttonChangePassword'));
      await driver.waitFor(find.byValueKey('viewUpdatePassword'));
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('inputPassword'));
      await driver.enterText('Lahore123@');
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('inputConfirmPassword'));
      await driver.enterText('Lahore123@');
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('buttonUpdatePassword'));

      await driver.waitFor(find.byValueKey("dashboardView"));
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('tabSettings'));
      await driver.waitFor(find.byValueKey('settingView'));
      await logoutFromDashboard(driver);
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
