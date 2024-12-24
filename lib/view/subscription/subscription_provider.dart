import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:ping_app/view/subscription/subscription_model.dart';

class PurChasedModel {
  final String id;
  final String title;
  final String price;
  final String details;
  final int perUsersAndMessages;
  PurChasedModel({
    required this.title,
    required this.id,
    required this.details,
    required this.price,
    required this.perUsersAndMessages,
  });
}

class SubscriptionProvider extends ChangeNotifier {
  int selectType = 0;
  PurChasedModel? purChasedModel;
  List<String> subscriptionIds = <String>[
    "basicmonthly",
    "basicyearly",
    "expertmonthly",
    "expertyearly",
    "promonthly",
    "proyearly",
  ];
  bool subscriptionType = false;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  late ProductDetails selectProductDetails;
  List<PurchaseDetails> purchases = [];
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> productsDetails = <ProductDetails>[];
  List<SubscriptionModel> subscriptions = <SubscriptionModel>[
    SubscriptionModel(
      details: "You will be change ",
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
  Future<void> init() async {
    PingLog.pingLog("SubscriptionProvider init");
    setSelectType(0);
    setSubscriptionType(false);
    await restorePurchases();
    await initLister();
    await fetchDetailsAfterPurchase();
    PingLog.pingLog(".........transactionDate.......${purchases.first.transactionDate}...");
    PingLog.pingLog(".........productID.......${purchases.first.productID}...");
    PingLog.pingLog(".........status.......${purchases.first.status}...");
    notifyListeners();
  }

  Future fetchDetailsAfterPurchase() async {
    if (purchases.isNotEmpty) {
      String id = purchases[0].productID;
      if (id == subscriptionIds[0]) {
        purChasedModel = PurChasedModel(
          perUsersAndMessages: 3,
          title: "Basic Monthly",
          details: "You have to purchase Subscription in every month",
          id: id,
          price: productsDetails[0].price,
        );
      } else if (id == subscriptionIds[1]) {
        purChasedModel = PurChasedModel(
          title: "Basic Yearly",
          perUsersAndMessages: 3,
          id: id,
          details: "You have to purchase Subscription in every year",
          price: productsDetails[1].price,
        );
      } else if (id == subscriptionIds[2]) {
        purChasedModel = PurChasedModel(
          perUsersAndMessages: 5,
          id: id,
          title: "Expert Monthly",
          details: "You have to purchase Subscription in every month",
          price: productsDetails[2].price,
        );
      } else if (id == subscriptionIds[3]) {
        purChasedModel = PurChasedModel(
          perUsersAndMessages: 5,
          id: id,
          title: "Expert Yearly",
          details: "You have to purchase Subscription in every year",
          price: productsDetails[3].price,
        );
      } else if (id == subscriptionIds[4]) {
        purChasedModel = PurChasedModel(
          perUsersAndMessages: 20,
          title: "Pro Monthly",
          id: id,
          details: "You have to purchase Subscription in every month",
          price: productsDetails[4].price,
        );
      } else {
        purChasedModel = PurChasedModel(
          perUsersAndMessages: 20,
          title: "Pro Yearly",
          id: id,
          details: "You have to purchase Subscription in every year",
          price: productsDetails[5].price,
        );
      }
    }
  }

  Future<void> initLister() async {
    PingLog.pingLog(".............initLister....start................................");
    try {
      _subscription = _inAppPurchase.purchaseStream.listen(
        (List<PurchaseDetails> purchaseDetailsList) async {
          PingLog.pingLog("purchaseDetailsList length: ${purchaseDetailsList.length}");
          PingLog.pingLog("purchaseDetailsList $purchaseDetailsList");
          if (purchaseDetailsList.isEmpty) {
            PingLog.pingLog("No purchases in purchaseDetailsList.");
          } else {
            for (var purchaseDetails in purchaseDetailsList) {
              PingLog.pingLog("purchase status ${purchaseDetails.status}");
              switch (purchaseDetails.status) {
                case PurchaseStatus.pending:
                  PingLog.pingLog('Purchase is pending...');
                  break;
                case PurchaseStatus.error:
                  PingLog.pingLog('Purchase Error: ${purchaseDetails.error}');
                  break;
                case PurchaseStatus.restored:
                  PingLog.pingLog('PurchaseStatus is restored. Product ID: ${purchaseDetails.productID}');
                  if (subscriptionIds.contains(purchaseDetails.productID)) {
                    PingLog.pingLog("....if (subscriptionIds.contains(purchaseDetails.productID))...");
                    purchases.add(purchaseDetails);
                  }
                  notifyListeners();
                  break;
                case PurchaseStatus.purchased:
                  PingLog.pingLog('PurchaseStatus is purchased. Product ID: ${purchaseDetails.productID}');
                  if (subscriptionIds.contains(purchaseDetails.productID)) {
                    purchases.add(purchaseDetails);
                  }
                  notifyListeners();
                  break;
                case PurchaseStatus.canceled:
                  PingLog.pingLog('Purchase was canceled. Product ID: ${purchaseDetails.productID}');
                  break;
              }
              // Mark purchase as complete
              if (purchaseDetails.pendingCompletePurchase) {
                _inAppPurchase.completePurchase(purchaseDetails);
              }
            }
          }
        },
        onError: (error) {
          PingLog.pingLog("Purchase stream error: $error");
        },
      );
    } catch (e, s) {
      PingLog.pingLog("initLister error: $e $s");
    }
    PingLog.pingLog("................initLister......end...........................");
  }

  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint("Error restoring purchases: $e");
    }
  }

  Future<void> setProductDetails(ProductDetails value) async {
    selectProductDetails = value;
    log("ProductDetails id: ${selectProductDetails.id}");
    log("ProductDetails title: ${selectProductDetails.title}");
    await purchaseSubscription(selectProductDetails);
    notifyListeners();
  }

  Future<List<ProductDetails>> fetchSubscriptionDetails() async {
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(
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

    // // Log details of each subscription
    // for (var product in response.productDetails) {
    //   log("ID: ${product.id}");
    //   log("Title: ${product.title}");
    //   log("Description: ${product.description}");
    //   log("Price: ${product.price}");
    //   log("Currency: ${product.rawPrice}");
    // }

    return response.productDetails;
  }

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
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    try {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam).then((value) {
        pop();
      });
    } catch (e, s) {
      debugPrint("Error: $e");
      debugPrint("st: $s");
    }
  }
}
