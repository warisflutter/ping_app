import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/subscription/repo/subscription_state.dart';
import 'package:ping_app/subscription/view/subscription_offering_view.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionPayWall extends StatefulWidget {
  const SubscriptionPayWall({super.key});

  @override
  State<SubscriptionPayWall> createState() => _SubscriptionPayWallState();
}

class _SubscriptionPayWallState extends State<SubscriptionPayWall> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final offerings = context.watch<SubscriptionState>().offerings;
    if (offerings == null) {
      return getErrorMessage(context, 't_invalidState'.tr());
    }
    final allOfferings = offerings.all.values.toList();
    allOfferings.sort((a, b) => a.availablePackages.first.storeProduct.price
        .compareTo(b.availablePackages.first.storeProduct.price));
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: [
          TextButton.icon(
            label:  Text('t_restorePurchase'.tr()),
            icon: const Icon(Icons.restore),
            onPressed: loading
                ? null
                : () async {
                    setState(() => loading = true);
                    try {
                      await context.read<SubscriptionState>().restorePurchase();
                      snack('t_purchasesRestored'.tr(), info: true);
                    } catch (e) {
                      snack(e);
                    }
                    setState(() => loading = false);
                  },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: loading ? null : () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          itemCount: allOfferings.length,
          itemBuilder: (context, index) {
            final offering = allOfferings[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SubscriptionOfferingView(
                  offering: offering,
                  onPurchase: (Package package) =>
                      actionPurchase(package),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> actionPurchase(Package package) async {
    setState(() => loading = true);
    try {
      await context.read<SubscriptionState>().makePurchase(package);
    } catch (e) {
      snack(e);
    }
    setState(() => loading = false);
  }
}
