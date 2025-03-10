import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:ping_app/services/firebase_service.dart';
import 'package:ping_app/view/subscription/subscription_info_view.dart';
import 'package:universal_io/io.dart';
import 'package:easy_localization/easy_localization.dart';
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
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'details': details,
      'perUsersAndMessages': perUsersAndMessages,
    };
  }

  factory PurChasedModel.fromMap(Map<String, dynamic> map) {
    return PurChasedModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      price: map['price'] ?? '',
      details: map['details'] ?? '',
      perUsersAndMessages: map['perUsersAndMessages'] ?? 0,
    );
  }
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
  final inAppPurchase = InAppPurchase.instance;
  final FirebaseService firebaseService = FirebaseService();
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
      supportedPlatforms: "t_androidIOSAndWebVersion",
      type: "t_basicSubscription",
      annuallyPrice: "199.00",
      monthlyPrice: "19.00",
      numberOfMessages: "t_upTo3MessageTemplates",
      numberOfVoiceMessages: "t_unlimitedNumberOfVoiceMessages",
      teamMembers: "t_upTo3UsersPerTeam",
    ),
    SubscriptionModel(
      details: "",
      type: "t_expertSubscription",
      supportedPlatforms: "t_androidIOSAndWebVersion",
      annuallyPrice: "249.00",
      monthlyPrice: "24.00",
      numberOfMessages: "t_upTo5MessageTemplates",
      numberOfVoiceMessages: "t_unlimitedNumberOfVoiceMessages",
      teamMembers: "t_upTo5UsersPerTeam",
    ),
    SubscriptionModel(
      details: "",
      type: "t_proSubscription",
      supportedPlatforms: "t_androidIOSAndWebVersion",
      annuallyPrice: "349.00",
      monthlyPrice: "34.00",
      numberOfMessages: "t_upTo20MessageTemplates",
      numberOfVoiceMessages: "t_unlimitedNumberOfVoiceMessages",
      teamMembers: "t_upTo20UsersPerTeam",
    ),
  ];

  SubscriptionProvider() {
    init();
  }

  Future<void> init() async {
    PingLog.pingLog("---SubscriptionProvider init---");
    await showSubscriptions();
    await initLister();
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
      inAppPurchase.purchaseStream.listen(
        (List<PurchaseDetails> purchaseDetailsList) async {
          PingLog.pingLog("purchaseDetailsList length: ${purchaseDetailsList.length}");
          if (purchaseDetailsList.isEmpty) {
            PingLog.pingLog("No purchases in purchaseDetailsList.");
            // firebaseService.removeUserSubscription();
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
                inAppPurchase.completePurchase(purchaseDetails);
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

  Future<void> fetchDetailsAfterPurchase() async {
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
            title: "t_BasicMonthly",
            details: "t_monthSubscriptionPurchase",
            id: id,
            price: productsDetails[0].price,
          );
          notifyListeners();
          PingLog.pingLog('subscription selected...');
        } else if (id == subscriptionIds[1]) {
          PingLog.pingLog("----> price: ${productsDetails[1].price}");
          purChasedModel = PurChasedModel(
            title: "t_BasicYearly",
            perUsersAndMessages: 3,
            id: id,
            details: "t_yearSubscriptionPurchase",
            price: productsDetails[1].price,
          );
          notifyListeners();
        } else if (id == subscriptionIds[2]) {
          PingLog.pingLog("----> price: ${productsDetails[2].price}");
          purChasedModel = PurChasedModel(
            perUsersAndMessages: 5,
            id: id,
            title: "t_ExpertMonthly",
            details: "t_monthSubscriptionPurchase",
            price: productsDetails[2].price,
          );
          notifyListeners();
        } else if (id == subscriptionIds[3]) {
          PingLog.pingLog("----> price: ${productsDetails[3].price}");
          purChasedModel = PurChasedModel(
            perUsersAndMessages: 5,
            id: id,
            title: "t_ExpertYearly",
            details: "t_yearSubscriptionPurchase",
            price: productsDetails[3].price,
          );
          notifyListeners();
        } else if (id == subscriptionIds[4]) {
          PingLog.pingLog("----> price: ${productsDetails[4].price}");
          purChasedModel = PurChasedModel(
            perUsersAndMessages: 20,
            title: "t_ProMonthly",
            id: id,
            details: "t_monthSubscriptionPurchase".tr(),
            price: productsDetails[4].price,
          );
          notifyListeners();
        } else if ((id == subscriptionIds[5])) {
          PingLog.pingLog("----> price: ${productsDetails[5].price}");
          purChasedModel = PurChasedModel(
            perUsersAndMessages: 20,
            title: "t_ProYearly",
            id: id,
            details: "t_yearSubscriptionPurchase",
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
    // if (purChasedModel == null) return;
    // firebaseService.saveUserDetailsAfterBuySubscription(
    //   purchasedModel: purChasedModel!,
    // );
  }

  Future<List<ProductDetails>> fetchSubscriptionDetails() async {
    final ProductDetailsResponse response = await inAppPurchase.queryProductDetails(
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
      await inAppPurchase.restorePurchases();
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
      "----showSubscriptions subscription length: ${productsDetails.map((e) => "id:${e.id}-price:${e.price}").toList()}----",
    );
    notifyListeners();
  }

  Future<void> purchaseSubscription(ProductDetails productDetails) async {
    try {
      loader = true;
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      await inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void handleVoucherType({
    required String voucherData,
    required int numberOfMembers,
    required String type,
  }) {
    String status = voucherData.split("|")[0];
    if (status == "Voucher is Expire") {
      push(const SubscriptionInfoView());
      snack("Voucher is Expire");
      return;
    }
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
  }

  void setSubscribeButton() {
    // subscribeBtnText = "$subscriptionType <===> $selectType <===> ${purChasedModel!.id}";
    if (purChasedModel != null) {
      int currentPurchasedIndex = subscriptionIds.indexWhere((thisId) => thisId == purChasedModel!.id);
      if (currentPurchasedIndex == -1) {
        subscribeBtnText = "t_subscribe".tr();
        return;
      }
      ProductDetails selectedProduct = getProduct(type: selectType, mode: subscriptionType, products: productsDetails);
      int currentSelectedProductIndex = subscriptionIds.indexWhere((thisId) => thisId == selectedProduct.id);
      if (currentSelectedProductIndex == -1) {
        subscribeBtnText = "t_subscribe".tr();
        return;
      }
      if (currentSelectedProductIndex == currentPurchasedIndex) {
        subscribeBtnText = "t_subscribed".tr();
      } else if (currentSelectedProductIndex > currentPurchasedIndex) {
        if (currentSelectedProductIndex == 5 || currentSelectedProductIndex == 4) {
          subscribeBtnText = "t_get90DaysFreeTrail".tr();
        } else {
          subscribeBtnText = "t_upgrade".tr();
        }
      } else {
        subscribeBtnText = "t_downgrade".tr();
      }
    } else {
      if (selectType == 2) {
        subscribeBtnText = "t_get90DaysFreeTrail".tr();
      } else {
        subscribeBtnText = "t_subscribe".tr();
      }
    }
    // if (selectType == 2) {
    //   subscribeBtnText = "t_get90DaysFreeTrail".tr();
    // } else if (purChasedModel != null) {
    //   double selectedDPrice = 0.0;
    //   purChasedPrice = double.parse(purChasedModel?.price.replaceAll(RegExp(r'[^0-9.]'), '') ?? "");
    //   selectedDPrice = double.parse(selectSPrice.replaceAll(RegExp(r'[^0-9.]'), ''));
    //   String value = _compareDoubles(purChasedPrice, selectedDPrice);
    //   PingLog.pingLog("title: ${purChasedModel?.title}");
    //   PingLog.pingLog("purChasedPrice: $purChasedPrice");
    //   PingLog.pingLog("selectedDPrice: $selectedDPrice");
    //   if (value == "greater") {
    //     PingLog.pingLog("----if (purChasedPrice > selectedDPrice) { Downgrade----");
    //     subscribeBtnText = "t_downgrade".tr();
    //   } else if (value == "less") {
    //     subscribeBtnText = "t_upgrade".tr();
    //   } else if (value == "equal") {
    //     PingLog.pingLog("----user is already subscribed----");
    //     subscribeBtnText = "t_subscribed".tr();
    //   }
    // } else {
    //   subscribeBtnText = "t_subscribe".tr();
    // }
    notifyListeners();
  }

  void setSelectedPrice(String value) {
    selectSPrice = value;
    notifyListeners();
  }

  ProductDetails getProduct({
    required int type,
    required bool mode,
    required List<ProductDetails> products,
  }) {
    if (type == 0) {
      if (mode) {
        return products.firstWhere((product) => product.id == subscriptionIds[0]);
      } else {
        return products.firstWhere((product) => product.id == subscriptionIds[1]);
      }
    } else if (type == 1) {
      if (mode) {
        return products.firstWhere((product) => product.id == subscriptionIds[2]);
      } else {
        return products.firstWhere((product) => product.id == subscriptionIds[3]);
      }
    } else {
      if (mode) {
        return products.firstWhere((product) => product.id == subscriptionIds[4]);
      } else {
        return products.firstWhere((product) => product.id == subscriptionIds[5]);
      }
    }
  }
  @override
  void dispose() {
    log("subscription provider dispose");
    super.dispose();
  }
}
