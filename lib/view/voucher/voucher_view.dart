import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/view/voucher/voucher_provider.dart';
import 'package:ping_app/widgets/ping_loader.dart';
import 'package:provider/provider.dart';

class VoucherView extends StatelessWidget {
  const VoucherView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VoucherProvider(),
      child: Consumer<VoucherProvider>(
        builder: (context, value, _) {
          return Form(
            key: value.globalKey,
            child: Scaffold(
              appBar: AppBar(
                title: Text("t_voucher".tr()),
              ),
              body: Padding(
                padding: const EdgeInsets.all(12.0),
                child: (value.loader)
                    ? const Center(child: PingLoader())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Text(
                              "t_AddVoucherCodeHere".tr(),
                              textAlign: TextAlign.left,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: TextFormField(
                              validator: (value) {
                                if (value!.isNotEmpty) {
                                  return null;
                                } else {
                                  return 'Please enter a code';
                                }
                              },
                              decoration: InputDecoration(
                                hintText: "t_VoucherCode".tr(),
                              ),
                              controller: value.codeTEC,
                            ),
                          ),
                          Text(
                            '• Enter your voucher code above\n'
                                '• You can try up to 5 times per day\n'
                                '• Wait 1 minute between failed attempts\n'
                                '• Each code can only be used once',
                            style: TextStyle(
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20,),
                          Align(
                            alignment: Alignment.center,
                            child: ElevatedButton(
                              style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.white)),
                              onPressed: () async {
                                final isInternet = await context.isInternetAvailable();
                                if (isInternet) {
                                  if (context.mounted) {
                                    if (value.globalKey.currentState!.validate()) {
                                      value.globalKey.currentState!.save();
                                      await value.applyForVoucher(context: context);
                                    }
                                  }
                                } else {
                                  snack("t_noInternetPleaseConnectToTheInternet".tr());
                                }
                              },
                              child: Text(
                                "t_apply".tr(),
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
