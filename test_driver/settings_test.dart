// File: test_driver/login_and_settings_test.dart

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'util.dart';

void main() {
  group('Settings Test', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
      await Future.delayed(const Duration(seconds: 5));
      await loginFromCreateAccView(driver);
      await driver.waitFor(find.byValueKey("dashboardView"));
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('tabSettings'));
      await driver.waitFor(find.byValueKey('settingView'));
    });

    tearDownAll(() async {
      await logoutFromDashboard(driver);
      driver.close();
    });

    test('test settings, and manage messages', () async {
      await driver.waitFor(find.byValueKey('settingView'));

      // Go to All Messages
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('buttonAllMessages'));
      await driver.waitFor(find.byValueKey('messageListView'));

      // Function to add a message
      Future<void> addMessage(String messageText) async {
        await Future.delayed(const Duration(seconds: pauseDuration));
        await driver.tap(find.byValueKey('buttonAddMessage'));
        await driver.waitFor(find.byValueKey('messageAddEditView'));
        await Future.delayed(const Duration(seconds: pauseDuration));
        await driver.tap(find.byValueKey('textFieldMessage'));
        await Future.delayed(const Duration(seconds: pauseDuration));
        await driver.enterText(messageText);
        await Future.delayed(const Duration(seconds: pauseDuration));
        await driver.tap(find.byValueKey('buttonAddUpdate'));
        await driver.waitFor(find.byValueKey('messageListView'));
        expect(
            await driver.getText(find.text(messageText)), equals(messageText));
      }

      // Add three messages
      await addMessage('Message Number One');
      await addMessage('Message Number Two');
      await addMessage('Message Number Three');

      // Edit the first message
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.descendant(
          of: find.byValueKey('Message Number One'),
          matching: find.byValueKey('editButton')));
      await driver.waitFor(find.byValueKey('messageAddEditView'));
      expect(await driver.getText(find.byValueKey('textFieldMessage')),
          equals('Message Number One'));
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('textFieldMessage'));
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.enterText('Edited Message');
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('buttonAddUpdate'));
      await driver.waitFor(find.byValueKey('messageListView'));
      expect(await driver.getText(find.text('Edited Message')),
          equals('Edited Message'));

      // Function to delete a message
      Future<void> deleteMessage(String messageText) async {
        await Future.delayed(const Duration(seconds: pauseDuration));
        await driver.tap(find.descendant(
            of: find.byValueKey(messageText),
            matching: find.byValueKey('keyDeleteButton')));
        await Future.delayed(const Duration(seconds: pauseDuration));
        await driver.tap(find.byValueKey('sureDialogYes'));
        await driver.waitFor(find.byValueKey('messageListView'));

        try {
          final finder = find.text(messageText);
          await driver.getText(finder,
              timeout: const Duration(seconds: pauseDuration));
          fail('Message still exists: $messageText');
        } catch (e) {
          //expected
        }
      }

      // Delete all messages
      await deleteMessage('Edited Message');
      await deleteMessage('Message Number Two');
      await deleteMessage('Message Number Three');
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.pageBack());
      await driver.waitFor(find.byValueKey('settingView'));
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('test change name functionality', () async {
      await driver.waitFor(find.byValueKey("settingView"));

      // Click buttonChangeYourName
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('buttonChangeYourName'));
      await driver.waitFor(find.byValueKey('viewChangeName'));

      // Change inputInitials to "UPD"
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('inputInitials'));
      await driver.enterText('UPD');

      // Change inputName to "Updated Name"
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('inputName'));
      await driver.enterText('Updated Name');

      // Press buttonUpdate
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('buttonUpdate'));
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.waitFor(find.byValueKey('settingView'));
      await driver.waitFor(find.byValueKey('buttonChangeYourName'));

      // Click buttonChangeYourName again
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('buttonChangeYourName'));
      await driver.waitFor(find.byValueKey('viewChangeName'));

      // Verify changed name and initials
      expect(await driver.getText(find.byValueKey('inputInitials')),
          equals('UPD'));
      expect(await driver.getText(find.byValueKey('inputName')),
          equals('Updated Name'));

      // Change them back to KBA and Kamran Bashir Arain
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('inputInitials'));
      await driver.enterText('KBA');
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('inputName'));
      await driver.enterText('Kamran Bashir Arain');

      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('buttonUpdate'));
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.waitFor(find.byValueKey('settingView'));
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('test change team name functionality', () async {
      await driver.waitFor(find.byValueKey("settingView"));

      // Click buttonChangeTeamName
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('buttonChangeTeamName'));
      await driver.waitFor(find.byValueKey('viewChangeName'));

      // Change inputName to "Updated Team"
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('inputName'));
      await driver.enterText('Updated Team');

      // Press buttonUpdate
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('buttonUpdate'));

      // Go back to settingView
      await driver.waitFor(find.byValueKey('settingView'));

      // Click buttonChangeTeamName again
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('buttonChangeTeamName'));
      await driver.waitFor(find.byValueKey('viewChangeName'));

      // Verify changed team name
      expect(await driver.getText(find.byValueKey('inputName')),
          equals('Updated Team'));

      // Set it back to "Andios"
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('inputName'));
      await driver.enterText('Andios');

      // Press buttonUpdate
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('buttonUpdate'));

      // Go back
      await Future.delayed(const Duration(seconds: pauseDuration));
      // Verify settingView appears
      await driver.waitFor(find.byValueKey('settingView'));
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('test subscriptions and contact support', () async {
      await driver.waitFor(find.byValueKey("settingView"));

      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.scroll(
        find.byType('SingleChildScrollView'),
        0,
        -1000,
        const Duration(milliseconds: 300),
      );

      // Click buttonSubscriptions
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('buttonSubscriptions'));
      await driver.waitFor(find.byValueKey('viewSubscriptionInfo'));

      // Go back
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.pageBack());
      await driver.waitFor(find.byValueKey('settingView'));

      // Click keyContactSupport
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.byValueKey('keyContactSupport'));
      await driver.waitFor(find.byValueKey('viewContactSupport'));

      // Go back
      await Future.delayed(const Duration(seconds: pauseDuration));
      await driver.tap(find.pageBack());

      // Verify settingView appears
      await driver.waitFor(find.byValueKey('settingView'));
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
