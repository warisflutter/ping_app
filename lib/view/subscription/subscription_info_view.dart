import 'package:universal_io/io.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:ping_app/view/subscription/subscription_provider.dart';
import 'package:ping_app/widgets/selection_widget.dart';
import 'package:provider/provider.dart';

class SubscriptionInfoView extends StatefulWidget {
  const SubscriptionInfoView({super.key});

  @override
  State<SubscriptionInfoView> createState() => _SubscriptionInfoViewState();
}

class _SubscriptionInfoViewState extends State<SubscriptionInfoView> {
  @override
  void initState() {
    // Provider.of<SubscriptionProvider>(context, listen: false).init();
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
          if (subscriptionProvider.loader) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          } else {
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
                                ? subscriptionProvider.subscriptions[0].type.tr()
                                : (subscriptionProvider.selectType == 1)
                                    ? subscriptionProvider.subscriptions[1].type.tr()
                                    : subscriptionProvider.subscriptions[2].type.tr(),
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
                                        ? subscriptionProvider.subscriptions[0].teamMembers.tr()
                                        : (subscriptionProvider.selectType == 1)
                                            ? subscriptionProvider.subscriptions[1].teamMembers.tr()
                                            : subscriptionProvider.subscriptions[2].teamMembers.tr(),
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
                                        ? subscriptionProvider.subscriptions[0].numberOfMessages.tr()
                                        : (subscriptionProvider.selectType == 1)
                                            ? subscriptionProvider.subscriptions[1].numberOfMessages.tr()
                                            : subscriptionProvider.subscriptions[2].numberOfMessages.tr(),
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
                                        ? subscriptionProvider.subscriptions[0].numberOfVoiceMessages.tr()
                                        : (subscriptionProvider.selectType == 1)
                                            ? subscriptionProvider.subscriptions[1].numberOfVoiceMessages.tr()
                                            : subscriptionProvider.subscriptions[2].numberOfVoiceMessages.tr(),
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
                                        ? subscriptionProvider.subscriptions[0].supportedPlatforms.tr()
                                        : (subscriptionProvider.selectType == 1)
                                            ? subscriptionProvider.subscriptions[1].supportedPlatforms.tr()
                                            : subscriptionProvider.subscriptions[2].supportedPlatforms.tr(),
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
                              Builder(builder: (context) {
                                String price = subscriptionProvider
                                    .getProduct(
                                      type: subscriptionProvider.selectType,
                                      mode: subscriptionProvider.subscriptionType,
                                      products: subscriptionProvider.productsDetails,
                                    )
                                    .price;
                                return Text(
                                  "${"t_youWillBeChange".tr()} $price on every ${subscriptionProvider.subscriptionType ? "t_month".tr() : "t_year".tr()} ${"t_afterSubscribingThisCancelAtAnyTime".tr()}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
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
                    Text(
                      "t_annually".tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subscriptionProvider
                          .getProduct(
                            type: subscriptionProvider.selectType,
                            mode: false,
                            products: subscriptionProvider.productsDetails,
                          )
                          .price,
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
                    Text(
                      "t_monthly".tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subscriptionProvider
                          .getProduct(
                            type: subscriptionProvider.selectType,
                            mode: true,
                            products: subscriptionProvider.productsDetails,
                          )
                          .price,
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
          late ProductDetails selectedPrice = subscriptionProvider.getProduct(
            type: subscriptionProvider.selectType,
            mode: subscriptionProvider.subscriptionType,
            products: subscriptionProvider.productsDetails,
          );
          PingLog.pingLog("select price: ${selectedPrice.price}");
          if (subscriptionProvider.purChasedModel == null) {
            await subscriptionProvider.setProductDetails(selectedPrice);
          } else {
            context.showSubscriptionDialog(
              context,
              onTap: () {
                String url = (Platform.isAndroid)
                    ? "https://play.google.com/store/account/subscriptions"
                    : "https://account.apple.com/account/manage/section/subscriptions";
                context.launchURL(url);
              },
            );
          }
        },
        child: Text(
          textAlign: TextAlign.center,
          subscriptionProvider.subscribeBtnText.tr(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
