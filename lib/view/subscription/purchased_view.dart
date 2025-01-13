import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_utils.dart';
import 'package:ping_app/view/subscription/subscription_info_view.dart';
import 'package:ping_app/view/subscription/subscription_provider.dart';
import 'package:provider/provider.dart';

class PurchasedView extends StatefulWidget {
  const PurchasedView({super.key});

  @override
  State<PurchasedView> createState() => _PurchasedViewState();
}

class _PurchasedViewState extends State<PurchasedView> {
  @override
  void initState() {
    Provider.of<SubscriptionProvider>(context, listen: false).init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, widget) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text("${subscriptionProvider.purChasedModel?.title} ${"t_subscription".tr()}"),
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
                  Text("${subscriptionProvider.purChasedModel?.details}"),
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
            ),
          ),
        );
      },
    );
  }
}
