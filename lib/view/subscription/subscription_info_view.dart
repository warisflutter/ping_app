import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ping_app/view/subscription/subscription_provider.dart';
import 'package:ping_app/widgets/selection_widget.dart';
import 'package:provider/provider.dart';

class SubscriptionInfoView extends StatefulWidget {
  const SubscriptionInfoView({super.key});

  @override
  State<SubscriptionInfoView> createState() => _SubscriptionInfoViewState();
}

class _SubscriptionInfoViewState extends State<SubscriptionInfoView> {
  late SubscriptionProvider subscriptionProvider;
  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      subscriptionProvider.init();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key("viewSubscriptionInfo"),
      appBar: AppBar(
        title: Text('t_subscriptionInfo'.tr()),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, widget) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: List.generate(
                    subscriptionProvider.subscriptions.length,
                    (index) {
                      String text = subscriptionProvider.subscriptions[index].type;
                      return Expanded(
                        child: SelectionWidget(
                          onTap: () {
                            subscriptionProvider.setSelectType(index);
                          },
                          type: subscriptionProvider.selectType,
                          index: index,
                          text: text,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xffF7F7F7),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                        ),
                        child: Text(
                          (subscriptionProvider.selectType == 0)
                              ? subscriptionProvider.subscriptions[0].type
                              : (subscriptionProvider.selectType == 1)
                                  ? subscriptionProvider.subscriptions[1].type
                                  : subscriptionProvider.subscriptions[2].type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10.0,
                        ),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xffF7F7F7),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  (subscriptionProvider.selectType == 0)
                                      ? subscriptionProvider.subscriptions[0].teamMembers
                                      : (subscriptionProvider.selectType == 1)
                                          ? subscriptionProvider.subscriptions[1].teamMembers
                                          : subscriptionProvider.subscriptions[2].teamMembers,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Divider(
                                color: Colors.grey,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  (subscriptionProvider.selectType == 0)
                                      ? subscriptionProvider.subscriptions[0].numberOfMessages
                                      : (subscriptionProvider.selectType == 1)
                                          ? subscriptionProvider.subscriptions[1].numberOfMessages
                                          : subscriptionProvider.subscriptions[2].numberOfMessages,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Divider(
                                color: Colors.grey,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  (subscriptionProvider.selectType == 0)
                                      ? subscriptionProvider.subscriptions[0].numberOfVoiceMessages
                                      : (subscriptionProvider.selectType == 1)
                                          ? subscriptionProvider.subscriptions[1].numberOfVoiceMessages
                                          : subscriptionProvider.subscriptions[2].numberOfVoiceMessages,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Divider(
                                color: Colors.grey,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  (subscriptionProvider.selectType == 0)
                                      ? subscriptionProvider.subscriptions[0].supportedPlatforms
                                      : (subscriptionProvider.selectType == 1)
                                          ? subscriptionProvider.subscriptions[1].supportedPlatforms
                                          : subscriptionProvider.subscriptions[2].supportedPlatforms,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            _selectMOrY(subscriptionProvider: subscriptionProvider),
                            _subscribeButton(subscriptionProvider: subscriptionProvider),
                            Text(
                              (subscriptionProvider.selectType == 0)
                                  ? "You will be change ${(!subscriptionProvider.subscriptionType) ? subscriptionProvider.productsDetails[1].price : subscriptionProvider.productsDetails[0].price} on every ${subscriptionProvider.subscriptionType ? "month" : "year"} after subscribing this cancel at any time"
                                  : (subscriptionProvider.selectType == 1)
                                      ? "You will be change ${(!subscriptionProvider.subscriptionType) ? subscriptionProvider.productsDetails[3].price : subscriptionProvider.productsDetails[2].price} on every ${subscriptionProvider.subscriptionType ? "month" : "year"} after subscribing this cancel at any time"
                                      : "You will be change ${(subscriptionProvider.subscriptionType) ? subscriptionProvider.productsDetails[4].price : subscriptionProvider.productsDetails[5].price} on every ${subscriptionProvider.subscriptionType ? "month" : "year"} after subscribing this cancel at any time",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  _selectMOrY({
    required SubscriptionProvider subscriptionProvider,
  }) {
    return Container(
      margin: const EdgeInsets.all(12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: const BoxDecoration(color: Colors.black),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                subscriptionProvider.setSubscriptionType(false);
              },
              child: Container(
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: (subscriptionProvider.subscriptionType) ? Colors.black : Colors.white,
                  ),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.check_circle_outline,
                        color: (subscriptionProvider.subscriptionType) ? Colors.black : Colors.white,
                      ),
                    ),
                    const Text(
                      "Annually",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      (subscriptionProvider.selectType == 0)
                          ? subscriptionProvider.productsDetails[1].price
                          : (subscriptionProvider.selectType == 1)
                              ? subscriptionProvider.productsDetails[3].price
                              : subscriptionProvider.productsDetails[5].price,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () {
                subscriptionProvider.setSubscriptionType(true);
              },
              child: Container(
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: (!subscriptionProvider.subscriptionType) ? Colors.black : Colors.white,
                  ),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.check_circle_outline,
                        color: (!subscriptionProvider.subscriptionType) ? Colors.black : Colors.white,
                      ),
                    ),
                    const Text(
                      "Monthly",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      (subscriptionProvider.selectType == 0)
                          ? subscriptionProvider.productsDetails[0].price
                          : (subscriptionProvider.selectType == 1)
                              ? subscriptionProvider.productsDetails[2].price
                              : subscriptionProvider.productsDetails[4].price,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _subscribeButton({
    required SubscriptionProvider subscriptionProvider,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        style: const ButtonStyle(
          fixedSize: WidgetStatePropertyAll(Size(300, 50)),
        ),
        onPressed: () async {
          late ProductDetails data;
          switch (subscriptionProvider.selectType) {
            case 0:
              data = (subscriptionProvider.subscriptionType)
                  ? subscriptionProvider.productsDetails[0]
                  : subscriptionProvider.productsDetails[1];
              break;
            case 1:
              data = (subscriptionProvider.subscriptionType)
                  ? subscriptionProvider.productsDetails[2]
                  : subscriptionProvider.productsDetails[3];
              break;
            default:
              data = (subscriptionProvider.subscriptionType)
                  ? subscriptionProvider.productsDetails[4]
                  : subscriptionProvider.productsDetails[5];
              break;
          }
          await subscriptionProvider.setProductDetails(data);
        },
        child: Text(
          subscriptionProvider.subscribeBtnText,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
