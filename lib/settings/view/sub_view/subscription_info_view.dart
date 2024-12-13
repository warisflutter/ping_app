import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/subscription/model/subscription_model.dart';
import 'package:ping_app/util/loading_screen.dart';
import 'package:ping_app/subscription/repo/subscription_state.dart';
import 'package:ping_app/util/parsers.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/models/entitlement_info_wrapper.dart';

class SubscriptionInfoView extends StatelessWidget {
  const SubscriptionInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    final subState = context.watch<SubscriptionState>();
    final ei = subState.entitlementInfo;
    if (ei == null && !subState.isDemoAccount) {
      FirebaseAuth.instance.signOut();
      return LoadingScreen(message: 't_loggingOut'.tr());
    }

    final name =
        ei?.entitlementType.name ?? 't_yearlySubscriptionDemoAccount'.tr();

    final daysLeft = ei != null ? getDaysLeft(ei) : "";
    final purchaseDate = ei != null ? getSubscriptionDate(ei) : "July 01, 2024";

    return Scaffold(
      key: const Key("viewSubscriptionInfo"),
      appBar: AppBar(
        title:  Text('t_subscriptionInfo'.tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white.withOpacity(0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(name),
                    subtitle: Text(purchaseDate),
                    trailing: Text(daysLeft),
                  ),
                ],
              ),
            ),
            // const SizedBox(height: 16),
            // if (!kIsWeb)
            //   ElevatedButton(
            //     onPressed: () {
            //       push(const SubscriptionPayWall());
            //     },
            //     child: const Text("Change Plan"),
            //   ),
          ],
        ),
      ),
    );
  }

  String getDaysLeft(EntitlementInfo info) {
    final expiryDateString = info.expirationDate;
    if (expiryDateString == null) {
      return '';
    }

    final expiryDate = DateTime.parse(expiryDateString).toLocal();
    var daysLeft = expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) {
      daysLeft = expiryDate.difference(DateTime.now()).inHours;
      if (daysLeft <= 0) {
        daysLeft = expiryDate.difference(DateTime.now()).inMinutes;
        if (daysLeft <= 0) {
          daysLeft = expiryDate.difference(DateTime.now()).inSeconds;
          if (daysLeft <= 0) {
            return 't_subscriptionExpired'.tr();
          } else {
            return '$daysLeft ${'t_secondLeft'.tr()}';
          }
        } else {
          return '$daysLeft ${'t_minuteLeft'.tr()}';
        }
      } else {
        return '$daysLeft ${'t_hourLeft'.tr()}';
      }
    } else {
      return '$daysLeft ${'t_dayLeft'.tr()}';
    }
  }

  String getSubscriptionDate(EntitlementInfo info) {
    final purchaseDateString = info.latestPurchaseDate;

    final purchaseDate = DateTime.parse(purchaseDateString).toLocal();
    return parseDateTime(purchaseDate);
  }

  String getExpiryDate(EntitlementInfo info) {
    final eDate = info.expirationDate;
    if (eDate == null) {
      return "null";
    }
    final purchaseDate = DateTime.parse(eDate).toLocal();
    return parseDateTime(purchaseDate);
  }
}
