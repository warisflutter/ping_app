import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/subscription/model/subscription_model.dart';
import 'package:ping_app/util/ping_heading_card.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionOfferingView extends StatelessWidget {
  final Offering offering;
  final void Function(Package) onPurchase;

  const SubscriptionOfferingView({
    super.key,
    required this.offering,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final metaData = OfferingMetaModel.fromJson(offering.metadata);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PingHeadingCard(title: metaData.title),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            metaData.description,
            textAlign: TextAlign.center,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: metaData.benefits
              .map((e) => ListTile(
                    title: Text(e),
                    leading:
                        const Icon(Icons.check_circle, color: Colors.green),
                  ))
              .toList(),
        ),
        const SizedBox(
          height: 32,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: offering.availablePackages
              .map((e) => buildPurchaseButton(context, e))
              .toList(),
        ),
      ],
    );
  }

  Widget buildPurchaseButton(BuildContext context, Package package) {
    final trial = package.storeProduct.introductoryPrice;
    // final subState = context.watch<SubscriptionState>();
    // final ei = subState.entitlementInfo;
    // final isSubscribed = ei == null
    //     ? false
    //     : ei.productIdentifier == package.storeProduct.identifier;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          elevation: 8.0,
          // color: isSubscribed ? Colors.green : Colors.white,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            // onTap: isSubscribed ? null : () => onPurchase(package),
            onTap: () => onPurchase(package),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    package.storeProduct.priceString,
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    package.packageType.name,
                    style: TextStyle(color: Colors.black.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
        // if(isSubscribed)
        //   Positioned(
        //     top: -20,
        //     right: -16,
        //     child: Container(
        //       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
        //       decoration: const BoxDecoration(
        //         color: Colors.white,
        //         borderRadius: BorderRadius.only(
        //           topRight: Radius.circular(8.0),
        //           bottomLeft: Radius.circular(8.0),
        //         ),
        //       ),
        //       child: const Text(
        //         'Subscribed',
        //         style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        //       ),
        //     ),
        //   ),
        // if (trial != null && !isSubscribed)
        if (trial != null)
          Positioned(
            top: -20,
            right: -16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8.0),
                  bottomLeft: Radius.circular(8.0),
                ),
              ),
              child: Text(
                't_3MonthTrial'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
