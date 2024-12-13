import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ping_app/util/navigator.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showLoader(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: Center(
        child: SizedBox(
          height: 50,
          width: 50,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    ),
  );
}

void snack(dynamic message, {bool info = false, Key? key}) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      key: key,
      backgroundColor: info ? Colors.green : Colors.red,
      content: Text(
        _dynamicToMessage(message),
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}

void snackSync(ScaffoldMessengerState state, dynamic message,
        {bool info = false}) =>
    state.showSnackBar(
      SnackBar(
        backgroundColor: info ? Colors.green : Colors.red,
        content: Text(
          _dynamicToMessage(message),
          style: Theme.of(state.context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.white),
        ),
      ),
    );

void alert(BuildContext context, dynamic message, {bool info = false}) {
  if (kDebugMode) {
    print(message);
  }
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      alignment: Alignment.bottomRight,
      titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16) +
          const EdgeInsets.only(bottom: 16),
      title: SizedBox(
        width: 270,
        child: Column(
          children: [
            Row(
              children: [
                info
                    ? const Icon(
                        Icons.info,
                        color: Colors.green,
                        size: 20,
                      )
                    : const Icon(
                        Icons.warning,
                        color: Colors.red,
                        size: 20,
                      ),
                const SizedBox(width: 8),
                Text(
                  "Ping App",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: info ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 4),
          ],
        ),
      ),
      content: SizedBox(
        width: 370,
        child: Text(
          _dynamicToMessage(message),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ),
  );
}

Widget getLoader({double size = 32, String message = ""}) => Center(
      child: SizedBox(
        height: size,
        width: size,
        child: const CircularProgressIndicator(),
      ),
    );

Widget getErrorMessage(BuildContext context, dynamic error, {info = false}) =>
    Center(
      child: Text(
        _dynamicToMessage(error),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: info ? Theme.of(context).primaryColor : Colors.red),
      ),
    );

void sureDialog({
  required BuildContext context,
  required String title,
  required String message,
  required void Function() onYes,
}) =>
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child:  Text('t_no'.tr()),
            onPressed: () => pop(),
          ),
          TextButton(
            key: Key("sureDialogYes"),
            onPressed: () {
              pop();
              onYes();
            },
            child: Text('t_yes'.tr()),
          ),
        ],
      ),
    );

String _dynamicToMessage(message) {
  if (kDebugMode) {
    if (message is Error) {
      print(message.stackTrace);
    }
  }

  return message is FirebaseException
      ? _handleFirebaseException(message)
      : message is PlatformException
          ? "${message.code}: ${message.message}"
          : message is String
              ? message
              : "$message";
}

String _handleFirebaseException(FirebaseException error) {
  final code = error.code;
  final message = error.message;
  return "$code: $message";
}

Widget getLoadingText({double height = 16, double width = 100}) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );

Widget getLoadingImage({double radius = 50}) => CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
    );
