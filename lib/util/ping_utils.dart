import 'dart:developer';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:ping_app/util/ping_styles.dart';
import 'package:url_launcher/url_launcher.dart';

extension PingUtils on BuildContext {
  double get screenHeight => MediaQuery.of(this).size.height;

  double get screenWidth => MediaQuery.of(this).size.width;
  bool get isWatch => screenWidth <= 200 && screenHeight <= 200;
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
      // return value;
    }
  }

  Future<bool?> showConfirmationDialog({
    String message = "",
    required String title,
    required String type,
  }) {
    return showAdaptiveDialog<bool>(
      context: navigatorKey.currentState!.context,
      builder: (BuildContext context) {
        return context.isWatch ?
            Material(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: Colors.black,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400
                        ),
                      ),
                      const SizedBox(height: 5,),
                      type == "Ping"
                          ? Text(
                        "${"t_AreYouSureYouWantToSend".tr()} $type",
                        style: PingStyles.watchStyle,
                      )
                          : Text(
                        message,
                        style: PingStyles.watchStyle,
                      ),
                      const SizedBox(height: 10,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          InkWell(
                              onTap: () => Navigator.of(context).pop(false),
                              child: Text("t_cancel".tr(), style: PingStyles.watchStyle,)),
                          const SizedBox(width: 10,),
                          InkWell(
                              onTap: () => Navigator.of(context).pop(true),
                              child: Text("t_send".tr(), style: PingStyles.watchStyle,)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            )
        : AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: (type == "Ping")
              ? Text(
                  "${"t_AreYouSureYouWantToSend".tr()} $type",
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
              child:  Text("t_cancel".tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child:  Text("t_send".tr()),
            ),
          ],
        );
      },
    );
  }

  String pingString(String text) {
    return text.tr();
  }

  Future<void> deleteAccountDialog({
    required void Function()? onPressed,
  }) {
    return showDialog(
      context: this,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          title: Text(
            "t_delete".tr().toUpperCase(),
            softWrap: true,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "t_areYouSureThisActionWillRemoveAllYourData".tr(),
            softWrap: true,
            textAlign: TextAlign.left,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(this);
              },
              child: Text(
                't_cancel'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            TextButton(
              onPressed: onPressed,
              child: Text(
                "t_delete".tr().toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showSubscriptionDialog(
    BuildContext context, {
    required void Function()? onTap,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("t_cancelSubscription".tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("t_youNeedToCancelYourCurrentSubscriptionBeforeYouCanUpgradeDowngrade".tr()),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        pop();
                      },
                      child: Text("t_close".tr()),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onTap,
                      child: Text("t_cancel".tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
