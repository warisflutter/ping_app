import 'package:flutter/material.dart';
import 'package:ping_app/view/subscription/subscription_model.dart';

class SubscriptionProvider extends ChangeNotifier {
  List<String> subscriptionIds = <String>[];
  int selectType = 0;
  List<SubscriptionModel> subscriptions = <SubscriptionModel>[
    SubscriptionModel(
      type: "Basic subscription",
      annuallyPrice: "Annually: CHF 199.00",
      monthlyPrice: "Monthly: CHF 19.00",
      numberOfMessages: "up to 3 message templates",
      numberOfVoiceMessages: "Unlimited number of voice messages",
      teamMembers: "up to 3 users per team",
    ),
    SubscriptionModel(
      type: "Expert subscription",
      annuallyPrice: "Annually: CHF 249.00",
      monthlyPrice: "Monthly: CHF 24.00",
      numberOfMessages: "up to 5 message templates",
      numberOfVoiceMessages: "Unlimited number of voice messages",
      teamMembers: "up to 5 users per team",
    ),
    SubscriptionModel(
      type: "Pro subscription",
      annuallyPrice: "Annually: CHF 349.00",
      monthlyPrice: "Monthly: CHF 34.00",
      numberOfMessages: "up to 20 message templates",
      numberOfVoiceMessages: "Unlimited number of voice messages",
      teamMembers: "up to 20 users per team",
    ),
  ];
  void setApproveOrReject(int value) {
    selectType = value;
    notifyListeners();
  }
}
