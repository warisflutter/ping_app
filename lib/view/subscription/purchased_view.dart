import 'dart:async';
import 'package:ping_app/file_path.dart';
import 'package:universal_io/io.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ping_app/view/subscription/subscription_info_view.dart';
import 'package:provider/provider.dart';

class PurchasedView extends StatefulWidget {
  final bool fromApply;

  const PurchasedView({
    super.key,
    this.fromApply = false,
  });

  @override
  State<PurchasedView> createState() => _PurchasedViewState();
}

class _PurchasedViewState extends State<PurchasedView> {
  late StreamSubscription _subscription;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // Provider.of<SubscriptionProvider>(context, listen: false).init();
      Provider.of<AdminProvider>(context, listen: false).startCountDown();
      if (widget.fromApply) {
        Future.delayed(const Duration(seconds: 2)).then((value) {
          startPeriodicStream();
        });
      } else {
        startPeriodicStream();
      }
    });
    super.initState();
  }

  void startPeriodicStream() {
    _subscription = Stream.periodic(const Duration(seconds: 1), (time) {
      print('This runs every 2 seconds! $time');
      checkConditions();
    }).listen((_) {});
  }

  void checkConditions() {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    if (subscriptionProvider.purChasedModel == null && adminProvider.remainingTime == Duration.zero) {
      pop();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionProvider, AdminProvider>(
      builder: (context, subscriptionProvider, adminProvider, _) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: (subscriptionProvider.purChasedModel != null)
                ? Text(
                    "${"${subscriptionProvider.purChasedModel?.title}".tr()} ${"t_subscription".tr()}",
                  )
                : Text(
                    "t_VoucherRedeemed".tr(),
                  ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Lottie.asset(
                    height: 200,
                    width: 200,
                    'assets/images/success_animation.json',
                  ),
                  Text(
                    (subscriptionProvider.purChasedModel == null)
                        ? "t_YouHaveSuccessfullyRedeemedTheVoucher".tr()
                        : "${subscriptionProvider.purChasedModel?.details}".tr(),
                  ),
                  const SizedBox(height: 5),
                  (subscriptionProvider.purChasedModel == null)
                      ? Builder(
                          builder: (context) {
                            final duration = adminProvider.remainingTime;
                            final String formattedTime =
                                "${duration.inDays}d ${duration.inHours % 24}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s";
                            return Text(
                              textAlign: TextAlign.center,
                              (duration == Duration.zero) ? "" : "$formattedTime \n${"t_TimeLeft".tr()}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            );
                          },
                        )
                      : Column(
                          children: [
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                replace(const SubscriptionInfoView());
                              },
                              child: Text("t_upgradeDowngradeSubscription".tr()),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                String url = (Platform.isAndroid)
                                    ? "https://play.google.com/store/account/subscriptions"
                                    : "https://account.apple.com/account/manage/section/subscriptions";
                                context.launchURL(url);
                              },
                              child: Text("t_cancelSubscription".tr()),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () async {
          //     QuerySnapshot querySnapshot = await adminProvider.voucher
          //         .where("userId", isEqualTo: adminProvider.userId)
          //         .where("isUsed", isEqualTo: true)
          //         .get();
          //     if (querySnapshot.docs.isNotEmpty) {
          //       if (querySnapshot.docs.isNotEmpty) {
          //         await querySnapshot.docs[0].reference.update({
          //           "isUsed": true,
          //           "usedAt": "2024-02-05T17:52:47.920592",
          //         });
          //       }
          //     }
          //     adminProvider.startCountDown();
          //   },
          //   child: const Icon(Icons.cancel),
          // ),
        );
      },
    );
  }
}
