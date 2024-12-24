import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ping_app/view/subscription/subscription_model.dart';

class SubscriptionProvider extends ChangeNotifier {
  int selectType = 0;
  bool subscriptionType = false;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> productsDetails = <ProductDetails>[];
  void init() {
    debugPrint("SubscriptionProvider init");
    setSelectType(0);
    setSubscriptionType(false);
  }

  Future<List<ProductDetails>> fetchSubscriptionDetails() async {
    List<String> subscriptionIds = <String>[
      "basicmonthly",
      "basicyearly",
      "expertmonthly",
      "expertyearly",
      "promonthly",
      "proyearly",
    ];

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(
      subscriptionIds.toSet(),
    );

    // Check for IDs not found
    if (response.notFoundIDs.isNotEmpty) {
      log("These IDs were not found: ${response.notFoundIDs}");
    }

    // Log if there is an error
    if (response.error != null) {
      log("Error: ${response.error}");
    }

    // Log details of each subscription
    for (var product in response.productDetails) {
      log("ID: ${product.id}");
      log("Title: ${product.title}");
      log("Description: ${product.description}");
      log("Price: ${product.price}");
      log("Currency: ${product.rawPrice}");
    }

    return response.productDetails;
  }

  List<SubscriptionModel> subscriptions = <SubscriptionModel>[
    SubscriptionModel(
      details: "You will be change ",
      // "Our Basic access plan lets you use the core features of our app at an affordable price. Stay connected with your team and improve your communication efficiency.",
      supportedPlatforms: "Android, iOS and web version",
      type: "Basic subscription",
      annuallyPrice: "199.00",
      monthlyPrice: "19.00",
      numberOfMessages: "up to 3 message templates",
      numberOfVoiceMessages: "Unlimited number of voice messages",
      teamMembers: "up to 3 users per team",
    ),
    SubscriptionModel(
      details:
          "Upgrade to our Expert app version for an even better user experience and expanded features. Take your productivity to the next level.",
      type: "Expert subscription",
      supportedPlatforms: "Android, iOS and web version",
      annuallyPrice: "249.00",
      monthlyPrice: "24.00",
      numberOfMessages: "up to 5 message templates",
      numberOfVoiceMessages: "Unlimited number of voice messages",
      teamMembers: "up to 5 users per team",
    ),
    SubscriptionModel(
      details:
          "Upgrade to the Pro version of our app to get access to advanced features and an even better user experience. With our Pro version, you can unlock full functionality to take your productivity to the next level.",
      type: "Pro subscription",
      supportedPlatforms: "Android, iOS and web version",
      annuallyPrice: "349.00",
      monthlyPrice: "34.00",
      numberOfMessages: "up to 20 message templates",
      numberOfVoiceMessages: "Unlimited number of voice messages",
      teamMembers: "up to 20 users per team",
    ),
  ];

  Future<void> showSubscriptions() async {
    productsDetails = await fetchSubscriptionDetails();
    debugPrint("subscription length: ${productsDetails.length}");
    notifyListeners();
  }

  void setSubscriptionType(bool value) {
    subscriptionType = value;
    notifyListeners();
  }

  void setSelectType(int value) {
    selectType = value;
    notifyListeners();
  }

  Future<void> purchaseSubscription(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    try {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e, s) {
      debugPrint("Error: $e");
      debugPrint("st: $s");
    }
  }
}
