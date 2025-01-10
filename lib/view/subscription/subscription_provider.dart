import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ping_app/file_path.dart';

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


List<String> subscriptionIds = <String>[
  (Platform.isIOS) ? "pingapp_19_1m" : "basicmonthly",
  (Platform.isIOS) ? "pingapp_199_1y" : "basicyearly",
  (Platform.isIOS) ? "pingapp_24_1m" : "expertmonthly",
  (Platform.isIOS) ? "pingapp_249_1y" : "expertyearly",
  (Platform.isIOS) ? "pingapp_34_1m" : "promonthly",
  (Platform.isIOS) ? "pingapp_349_1y" : "proyearly",
];
class SubscriptionProvider extends ChangeNotifier {
  final _inAppPurchase = InAppPurchase.instance;
  PurChasedModel? purChasedModel;
  late ProductDetails selectProductDetails;
  List<PurchaseDetails> purchases = [];
  List<ProductDetails> productsDetails = <ProductDetails>[];
  int selectType = 0;
  bool subscriptionType = false;
  bool loader = false;
  String selectSPrice = "";
  String subscribeBtnText = "";
  double purChasedPrice = 0.0;


  List<SubscriptionModel> subscriptions = <SubscriptionModel>[
    SubscriptionModel(
      details: "",
      supportedPlatforms: "t_androidIOSAndWebVersion".tr(),
      type: "t_basicSubscription".tr(),
      annuallyPrice: "199.00",
      monthlyPrice: "19.00",
      numberOfMessages: "t_upTo3MessageTemplates".tr(),
      numberOfVoiceMessages: "t_unlimitedNumberOfVoiceMessages".tr(),
      teamMembers: "t_upTo3UsersPerTeam".tr(),
    ),
    SubscriptionModel(
      details: "",
      type: "t_expertSubscription".tr(),
      supportedPlatforms: "t_androidIOSAndWebVersion".tr(),
      annuallyPrice: "249.00",
      monthlyPrice: "24.00",
      numberOfMessages: "t_upTo5MessageTemplates".tr(),
      numberOfVoiceMessages: "t_unlimitedNumberOfVoiceMessages".tr(),
      teamMembers: "t_upTo5UsersPerTeam".tr(),
    ),
    SubscriptionModel(
      details: "",
      type: "t_proSubscription".tr(),
      supportedPlatforms: "t_androidIOSAndWebVersion".tr(),
      annuallyPrice: "349.00",
      monthlyPrice: "34.00",
      numberOfMessages: "t_upTo20MessageTemplates".tr(),
      numberOfVoiceMessages: "t_unlimitedNumberOfVoiceMessages".tr(),
      teamMembers: "t_upTo20UsersPerTeam".tr(),
    ),
  ];

  SubscriptionProvider() {
    init();
  }

  Future<void> init() async {
    PingLog.pingLog("---SubscriptionProvider init---");
    await showSubscriptions();
    await initLister();
    await restorePurchases();
    if (purChasedModel != null) {
      PingLog.pingLog(".........transactionDate.......${purchases.first.transactionDate}...");
      PingLog.pingLog(".........productID.......${purchases.first.productID}...");
      PingLog.pingLog(".........status.......${purchases.first.status}...");
      String productId = purChasedModel?.id ?? "";
      int subscriptionIndex = subscriptionIds.indexOf(productId);
      switch (subscriptionIndex) {
        case 0:
          setSubscriptionType(true);
          setSelectType(0);
          setSelectedPrice(productsDetails[0].price);
          break;
        case 1:
          setSubscriptionType(false);
          setSelectType(0);
          setSelectedPrice(productsDetails[1].price);
          break;
        case 2:
          setSubscriptionType(true);
          setSelectType(1);
          setSelectedPrice(productsDetails[2].price);
          break;
        case 3:
          setSubscriptionType(false);
          setSelectType(1);
          setSelectedPrice(productsDetails[3].price);
          break;
        case 4:
          setSubscriptionType(true);
          setSelectType(2);
          setSelectedPrice(productsDetails[4].price);
          break;
        case 5:
          setSubscriptionType(false);
          setSelectType(2);
          setSelectedPrice(productsDetails[5].price);
          break;
        default:
          setSubscriptionType(false);
          setSelectType(2);
          setSelectedPrice(productsDetails[5].price);
          break;
      }
    } else {
      setSubscriptionType(false);
      setSelectType(2);
      setSelectedPrice(productsDetails[5].price);
    }
    setSubscribeButton();
    notifyListeners();
  }

  Future<void> initLister() async {
    try {
      _inAppPurchase.purchaseStream.listen(
        (List<PurchaseDetails> purchaseDetailsList) async {
          PingLog.pingLog("purchaseDetailsList length: ${purchaseDetailsList.length}");
          if (purchaseDetailsList.isEmpty) {
            PingLog.pingLog("No purchases in purchaseDetailsList.");
          } else {
            for (var purchaseDetails in purchaseDetailsList) {
              PingLog.pingLog("purchase status ${purchaseDetails.status}");
              switch (purchaseDetails.status) {
                case PurchaseStatus.pending:
                  if (loader) {
                    safePop();
                  }
                  await Future.delayed(const Duration(seconds: 1));
                  loader = false;
                  notifyListeners();
                  PingLog.pingLog('Purchase is pending...');
                  break;
                case PurchaseStatus.error:
                  PingLog.pingLog('Purchase Error: ${purchaseDetails.error}');
                  loader = false;
                  notifyListeners();
                  break;
                case PurchaseStatus.restored:
                  PingLog.pingLog('PurchaseStatus is restored. Product ID: ${purchaseDetails.productID}');
                  if (subscriptionIds.contains(purchaseDetails.productID)) {
                    if (loader) {
                      safePop();
                    }
                    await Future.delayed(const Duration(seconds: 1));
                    PingLog.pingLog("....if (subscriptionIds.contains(purchaseDetails.productID))...");
                    purchases.add(purchaseDetails);
                    await fetchDetailsAfterPurchase();
                    loader = false;
                    notifyListeners();
                  }
                  break;
                case PurchaseStatus.purchased:
                  PingLog.pingLog(
                    'PurchaseStatus is purchased. Product ID: ${purchaseDetails.productID}',
                  );
                  if (subscriptionIds.contains(purchaseDetails.productID)) {
                    if (loader) {
                      safePop();
                    }
                    await Future.delayed(const Duration(seconds: 1));
                    purchases.add(purchaseDetails);
                    await fetchDetailsAfterPurchase();
                    loader = false;
                    notifyListeners();
                  }
                  break;
                case PurchaseStatus.canceled:
                  PingLog.pingLog('Purchase was canceled. Product ID: ${purchaseDetails.productID}');
                  loader = false;
                  notifyListeners();
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

  Future fetchDetailsAfterPurchase() async {
    PingLog.pingLog("----fetchDetailsAfterPurchase Function Start----");
    PingLog.pingLog("----> ${purchases.first.productID} $subscriptionIds");
    try {
      if (purchases.isNotEmpty) {
        String id = purchases[0].productID;
        log('This id => $id and this is subscription id => ${subscriptionIds[0]}');
        if (id == subscriptionIds[0]) {
          PingLog.pingLog("----> price: ${productsDetails[0].price}");
          purChasedModel = PurChasedModel(
            perUsersAndMessages: 3,
            title: "Basic Monthly",
            details: "You have to purchase Subscription in every month",
            id: id,
            price: productsDetails[0].price,
          );
          notifyListeners();
          PingLog.pingLog('subscription selected...');
        } else if (id == subscriptionIds[1]) {
          PingLog.pingLog("----> price: ${productsDetails[1].price}");
          purChasedModel = PurChasedModel(
            title: "Basic Yearly",
            perUsersAndMessages: 3,
            id: id,
            details: "You have to purchase Subscription in every year",
            price: productsDetails[1].price,
          );
          notifyListeners();
        } else if (id == subscriptionIds[2]) {
          PingLog.pingLog("----> price: ${productsDetails[2].price}");
          purChasedModel = PurChasedModel(
            perUsersAndMessages: 5,
            id: id,
            title: "Expert Monthly",
            details: "You have to purchase Subscription in every month",
            price: productsDetails[2].price,
          );
          notifyListeners();
        } else if (id == subscriptionIds[3]) {
          PingLog.pingLog("----> price: ${productsDetails[3].price}");
          purChasedModel = PurChasedModel(
            perUsersAndMessages: 5,
            id: id,
            title: "Expert Yearly",
            details: "You have to purchase Subscription in every year",
            price: productsDetails[3].price,
          );
          notifyListeners();
        } else if (id == subscriptionIds[4]) {
          PingLog.pingLog("----> price: ${productsDetails[4].price}");
          purChasedModel = PurChasedModel(
            perUsersAndMessages: 20,
            title: "Pro Monthly",
            id: id,
            details: "You have to purchase Subscription in every month",
            price: productsDetails[4].price,
          );
          notifyListeners();
        } else if ((id == subscriptionIds[5])) {
          PingLog.pingLog("----> price: ${productsDetails[5].price}");
          purChasedModel = PurChasedModel(
            perUsersAndMessages: 20,
            title: "Pro Yearly",
            id: id,
            details: "You have to purchase Subscription in every year",
            price: productsDetails[5].price,
          );
          notifyListeners();
        } else {
          PingLog.pingLog('-----} else {-----');
        }
      } else {
        PingLog.pingLog('purchase is empty----} else {----');
      }
    } catch (e, s) {
      PingLog.pingLog("This is my Error: $e $s");
    }
    PingLog.pingLog("===> This is my purchase model => ${purChasedModel?.title}");
    PingLog.pingLog("----fetchDetailsAfterPurchase Function end----");
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

    List<ProductDetails> fetchedProducts = response.productDetails;
    fetchedProducts.removeWhere((product) => product.rawPrice == 0);

    return fetchedProducts;
  }

  Future<void> restorePurchases() async {
    try {
      PingLog.pingLog("----Restore Purchase Call----");
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint("Error restoring purchases: $e");
    }
  }

  Future<void> setProductDetails(ProductDetails value) async {
    try {
      selectProductDetails = value;
      PingLog.pingLog("ProductDetails id: ${selectProductDetails.id}");
      PingLog.pingLog("ProductDetails title: ${selectProductDetails.title}");
      await purchaseSubscription(selectProductDetails);
      notifyListeners();
    } catch (e, s) {
      PingLog.pingLog("error: $e $s");
    }
  }

  Future<void> showSubscriptions() async {
    productsDetails = await fetchSubscriptionDetails();
    debugPrint("----showSubscriptions subscription length: ${productsDetails.length}----");
    debugPrint(
        "----showSubscriptions subscription length: ${productsDetails.map((e) => "id:${e.id}-price:${e.price}").toList()}----");
    notifyListeners();
  }

  Future<void> purchaseSubscription(ProductDetails productDetails) async {
    try {
      loader = true;
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      notifyListeners();
    } catch (e, s) {
      debugPrint("Error: $e");
      debugPrint("st: $s");
    }
  }

  void handleVoucherType({
    required String voucherData,
    required int numberOfMembers,
    required String type,
  }) {
    String typeSplit = voucherData.split("|")[1];
    Map<String, int> typeLimits = {
      "Basic": 3,
      "Export": 5,
      "Pro": 20,
    };
    if (numberOfMembers == typeLimits[typeSplit]) {
      snack("You have reached the member limit for your plan.");
    } else {
      if (type == "message") {
        push(const MessageAddEditView());
      } else {
        push(const MemberManageView());
      }
    }
    // PingLog.pingLog("Fetched Voucher: $voucherData");
    // PingLog.pingLog("_type: $_type");
    // PingLog.pingLog("numberOfMembers: $numberOfMembers");
    // PingLog.pingLog("typeLimits: ${typeLimits[_type]}");
    // PingLog.pingLog("typeLimits.containsKey(type): ${typeLimits.containsKey(_type)}");
  }

  void handleSubscription({
    required int numberOfMembers,
    required String type,
  }) {
    int perMemberLimit = purChasedModel?.perUsersAndMessages ?? 0;
    if (numberOfMembers == perMemberLimit) {
      snack('t_youHaveMembersAllowed'.tr());
    } else {
      if (type == "message") {
        push(const MessageAddEditView());
      } else {
        push(const MemberManageView());
      }
    }
  }

  void setSubscriptionType(bool value) {
    subscriptionType = value;
    if (subscriptionType) {
      if (selectType == 0) {
        setSelectedPrice(productsDetails[0].price);
      } else if (selectType == 1) {
        setSelectedPrice(productsDetails[2].price);
      } else {
        setSelectedPrice(productsDetails[4].price);
      }
    } else {
      if (selectType == 0) {
        setSelectedPrice(productsDetails[1].price);
      } else if (selectType == 1) {
        setSelectedPrice(productsDetails[3].price);
      } else {
        setSelectedPrice(productsDetails[5].price);
      }
    }
    // PingLog.pingLog("----Set Subscription Type----");
    setSubscribeButton();
    notifyListeners();
  }

  void setSelectType(int value) {
    selectType = value;
    setSubscribeButton();
    notifyListeners();
    // PingLog.pingLog("----Set Select Type----");
  }

  void setSubscribeButton() {
    if (selectType == 2) {
      subscribeBtnText = "t_get90DaysFreeTrail".tr();
    } else if (purChasedModel != null) {
      double selectedDPrice = 0.0;
      purChasedPrice = double.parse(purChasedModel?.price.replaceAll(RegExp(r'[^0-9.]'), '') ?? "");
      selectedDPrice = double.parse(selectSPrice.replaceAll(RegExp(r'[^0-9.]'), ''));

      String value = _compareDoubles(purChasedPrice, selectedDPrice);
      if (value == "greater") {
        PingLog.pingLog("----if (purChasedPrice > selectedDPrice) { Downgrade----");
        subscribeBtnText = "t_downgrade".tr();
      } else if (value == "less") {
        subscribeBtnText = "t_upgrade".tr();
      } else if (value == "equal") {
        PingLog.pingLog("----user is already subscribed----");
        subscribeBtnText = "t_subscribed".tr();
      }

    } else {
      subscribeBtnText = "t_subscribe".tr();
    }
    notifyListeners();
  }

  void setSelectedPrice(String value) {
    selectSPrice = value;
    notifyListeners();
  }

  String _compareDoubles(double value1, double value2) {
    if (value1 > value2) {
      return 'greater';
    } else if (value1 < value2) {
      return 'less';
    } else {
      return 'equal';
    }
  }
}
