import 'package:flutter_driver/flutter_driver.dart';

const pauseDuration = 0;

Future<void> loginFromCreateAccView(FlutterDriver driver,{String password="Lahore123@"}) async {
  await driver.waitFor(find.byValueKey("createAccountView"));
  await Future.delayed(const Duration(seconds: pauseDuration));
  await driver.scroll(
    find.byType('SingleChildScrollView'),
    0,
    -1000,
    const Duration(milliseconds: 300),
  );
  await driver.waitFor(find.byValueKey('loginButton'));
  await Future.delayed(const Duration(seconds: pauseDuration));
  await driver.tap(find.byValueKey('loginButton'));
  await driver.waitFor(find.byValueKey("loginView"));
  await Future.delayed(const Duration(seconds: pauseDuration));
  await driver.tap(find.byValueKey('inputEmail'));
  await Future.delayed(const Duration(seconds: pauseDuration));
  await driver.enterText('kamran.bashir.arain+sb@gmail.com');
  await Future.delayed(const Duration(seconds: pauseDuration));
  await driver.tap(find.byValueKey('inputPassword'));
  await Future.delayed(const Duration(seconds: pauseDuration));
  await driver.enterText(password);
  await Future.delayed(const Duration(seconds: pauseDuration));
  await driver.tap(find.byValueKey('buttonSignIn'));
  await driver.waitFor(find.byValueKey("dashboardView"));
}

Future<void> logoutFromDashboard(FlutterDriver driver) async {
  await driver.waitFor(find.byValueKey("dashboardView"));
  await Future.delayed(const Duration(seconds: pauseDuration));
  await driver.tap(find.byValueKey('tabSettings'));
  await driver.waitFor(find.byValueKey('settingView'));
  await Future.delayed(const Duration(seconds: pauseDuration));
  await driver.scroll(
    find.byType('SingleChildScrollView'),
    0,
    -1000,
    const Duration(milliseconds: 300),
  );
  await Future.delayed(const Duration(seconds: pauseDuration));
  await driver.tap(find.byValueKey('keyLogout'));
  await driver.waitFor(find.byValueKey("createAccountView"));
}
