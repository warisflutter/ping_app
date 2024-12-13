import 'package:easy_localization/easy_localization.dart';
import 'package:purchases_flutter/models/entitlement_info_wrapper.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';

class OfferingMetaModel {
  final String title;
  final String description;
  final List<String> benefits;

  OfferingMetaModel.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        description = json['description'],
        benefits = List<String>.from(json['benefits']);
}

extension PackageTypeExt on PackageType {
  String get name {
    switch (this) {
      case PackageType.lifetime:
        return 't_lifetime'.tr();
      case PackageType.annual:
        return 't_annual'.tr();
      case PackageType.sixMonth:
        return 't_6Months'.tr();
      case PackageType.threeMonth:
        return 't_3Months'.tr();
      case PackageType.twoMonth:
        return 't_2Months'.tr();
      case PackageType.monthly:
        return 't_monthly'.tr();
      default:
        return 't_unknown'.tr();
    }
  }
}

enum EntitlementType {
  basic,
  expert,
  pro,
  none,
}

extension EntitlementTypeExt on EntitlementType {
  String get name {
    switch (this) {
      case EntitlementType.basic:
        return 't_basicSubscription'.tr();
      case EntitlementType.expert:
        return 't_expertSubscription'.tr();
      case EntitlementType.pro:
        return 't_proSubscription'.tr();
      case EntitlementType.none:
        return 't_none'.tr();
    }
  }

  String get entitlementId {
    switch (this) {
      case EntitlementType.basic:
        return 'basic';
      case EntitlementType.expert:
        return 'expert';
      case EntitlementType.pro:
        return 'pro';
      case EntitlementType.none:
        return 'none';
    }
  }

  int get maxMembersAllowed {
    switch (this) {
      case EntitlementType.basic:
        return 3;
      case EntitlementType.expert:
        return 5;
      case EntitlementType.pro:
        return 20;
      case EntitlementType.none:
        return 0;
    }
  }

  int get maxMessageTemplateAllowed {
    switch (this) {
      case EntitlementType.basic:
        return 3;
      case EntitlementType.expert:
        return 5;
      case EntitlementType.pro:
        return 20;
      case EntitlementType.none:
        return 0;
    }
  }
}

extension EntitlementInfoExt on EntitlementInfo {
  EntitlementType get entitlementType {
    switch (identifier) {
      case 'basic':
        return EntitlementType.basic;
      case 'expert':
        return EntitlementType.expert;
      case 'pro':
        return EntitlementType.pro;
      default:
        return EntitlementType.none;
    }
  }
}
