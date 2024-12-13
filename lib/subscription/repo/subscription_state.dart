import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:ping_app/subscription/model/subscription_model.dart';
import 'package:ping_app/subscription/repo/subscription_repo.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionState extends ChangeNotifier {
  bool get isDemoAccount {
    final fbUser = FirebaseAuth.instance.currentUser;
    return fbUser?.email == "kamran.bashir.arain@gmail.com" ||
        fbUser?.email == "kamran.bashir.arain+sb@gmail.com" || kDebugMode;
  }

  //Non Listening Fields
  CustomerInfoUpdateListener? _mobileListener;
  StreamSubscription? _webListener;

  //Listenable states
  Offerings? _holderOfferings;

  Offerings? get offerings => _holderOfferings;

  set _offerings(Offerings? value) {
    _holderOfferings = value;
    notifyListeners();
  }

  EntitlementInfo? _holderEntitlementInfo;

  EntitlementInfo? get entitlementInfo => _holderEntitlementInfo;

  set _entitlementInfo(EntitlementInfo? value) {
    _holderEntitlementInfo = value;
    notifyListeners();
  }

  String? _holderUserId;

  String? get _userId => _holderUserId;

  set _userId(String? value) {
    _holderUserId = value;
    notifyListeners();
  }

  bool _holderLoading = true;

  bool get loading => _holderLoading;

  set _loading(bool value) {
    _holderLoading = value;
    notifyListeners();
  }

  dynamic _holderError;

  dynamic get error => _holderError;

  set _error(dynamic value) {
    _holderError = value;
    notifyListeners();
  }

  EntitlementType get subscriptionType {
    if (isDemoAccount) {
      return EntitlementType.pro;
    }
    if (_isSubscriptionExpired) {
      return EntitlementType.none;
    }
    final ei = entitlementInfo;
    if (ei == null) {
      return EntitlementType.none;
    } else {
      return ei.entitlementType;
    }
  }

  bool get _isSubscriptionExpired {
    if (isDemoAccount) {
      return false;
    }
    final expiryDateString = entitlementInfo?.expirationDate;
    if (expiryDateString == null) {
      return true;
    }

    final expiryDate = DateTime.parse(expiryDateString).toLocal();
    return expiryDate.isBefore(DateTime.now());
  }

  SubscriptionState() {
    if (!kIsWeb) {
      _initPackage();
    } else {
      _loading = false;
    }
  }

  void _initPackage() async {
    try {
      await Purchases.setLogLevel(
          kDebugMode ? LogLevel.verbose : LogLevel.error);
      PurchasesConfiguration configuration;
      if (Platform.isAndroid) {
        configuration =
            PurchasesConfiguration("goog_kCplDPixKcmaEltvVIbijWjlaCJ");
      } else if (Platform.isIOS) {
        configuration =
            PurchasesConfiguration("appl_ZTYJUxNFNDUfDZISXXtjVKspmXB");
      } else {
        throw 't_invalidPlatform'.tr();
      }
      await Purchases.configure(configuration);
      _offerings = await Purchases.getOfferings();
      await _forceRefreshEntitlementInfo();
      _loading = false;
    } catch (e) {
      _loading = false;
      _error = e;
    }
  }

  void updateUser(String userId) async {
    if (kIsWeb) {
      _initWebState(userId);
    } else {
      _initMobileState(userId);
    }
  }

  Future<void> _initMobileState(String userId) async {
    if (userId == _userId) {
      return;
    }

    _userId = userId;

    final mobileListener = _mobileListener;
    if (mobileListener != null) {
      Purchases.removeCustomerInfoUpdateListener(mobileListener);
    }
    newMobileListener(CustomerInfo purchaserInfo) {
      _setEntitlementFromCustomer(purchaserInfo);
      SubscriptionRepo.instance.setSubscriptionStatus(userId, entitlementInfo);
    }

    await Purchases.logIn(userId);

    Purchases.addCustomerInfoUpdateListener(newMobileListener);
    _mobileListener = newMobileListener;
  }

  Future<void> _initWebState(String userId) async {
    if (_userId == userId) {
      return;
    }
    _userId = userId;

    _entitlementInfo = await SubscriptionRepo.instance
        .getSubscriptionStatusStream(userId)
        .first;

    if (_webListener != null) {
      await _webListener?.cancel();
    }
    _webListener = SubscriptionRepo.instance
        .getSubscriptionStatusStream(userId)
        .listen((info) => _entitlementInfo = info);
    _loading = false;
  }

  Future<void> _forceRefreshEntitlementInfo() async {
    CustomerInfo customerInfo = await Purchases.getCustomerInfo();
    _setEntitlementFromCustomer(customerInfo);
  }

  void _setEntitlementFromCustomer(CustomerInfo info) {
    final activeObj = info.entitlements.active;
    _entitlementInfo = activeObj[EntitlementType.pro.entitlementId] ??
        activeObj[EntitlementType.expert.entitlementId] ??
        activeObj[EntitlementType.basic.entitlementId];
  }

  Future<void> makePurchase(Package package) async {
    await Purchases.purchasePackage(package);
    await _forceRefreshEntitlementInfo();
  }

  Future<void> restorePurchase() async {
    await Purchases.restorePurchases();
    await _forceRefreshEntitlementInfo();
  }
}
