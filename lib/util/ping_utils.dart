import 'dart:developer';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:url_launcher/url_launcher.dart';

extension PingUtils on BuildContext {
  double get screenHeight => MediaQuery.of(this).size.height;
  double get screenWidth => MediaQuery.of(this).size.width;
  Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw Exception("Could not launch $url");
    }
  }

  Future<void> sendEmail() async {
    final email = Email(
      body: '',
      subject: 't_pingAppSupport'.tr(),
      recipients: ['office@pingapp.ch'],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
    } catch (error) {
      log('Error sending email: $error');
    }
  }

  Future<bool> isInternetAvailable() async {
    bool value = false;
    if (kIsWeb) {
      PingLog.pingLog("Running on the web, assuming network is available.");
      return true;
    } else {
      PingLog.pingLog("Checking network availability...");
      try {
        final List<InternetAddress> res = await InternetAddress.lookup("google.com");
        PingLog.pingLog('Lookup result: ${res.length} addresses found.');
        if (res.isNotEmpty && res[0].rawAddress.isNotEmpty) {
          PingLog.pingLog("internet is available");
          return true;
        } else {
          PingLog.pingLog('No valid addresses found.');
          return false;
        }
      } on SocketException catch (e) {
        PingLog.pingLog('SocketException: $e');
        return false;
      } catch (e) {
        PingLog.pingLog('Unexpected error: $e');
        return false;
      }
      return value;
    }
  }

  Future<bool?> showConfirmationDialog({
    String message = "",
    required String type,
  }) {
    return showDialog<bool>(
      context: navigatorKey.currentState!.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Send $type",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: (type == "Ping")
              ? Text(
                  "Are you sure you want to send $type",
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                  ),
                )
              : Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }

  String pingString(String text) {
    return text.tr();
  }
}
