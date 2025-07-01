import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/view/create_account_view.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_utils.dart';
import 'package:ping_app/view/admin/admin_provider.dart';
import 'package:ping_app/widgets/base_widget.dart';
import 'package:ping_app/widgets/ping_loader.dart';
import 'package:provider/provider.dart';

// voucher status
//0 pending
//1 reject
//2 approve

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchVouchers();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BaseWidget(
      showBackIcon: false,
      title: const Text("Ping Admin"),
      actions: [
        IconButton(
          onPressed: () async {
            final isConnected = await context.isInternetAvailable();
            if (isConnected) {
              await FirebaseAuth.instance.signOut();
              replace(const CreateAccountView());
            } else {
              snack("t_noInternetPleaseConnectToTheInternet".tr());
            }
          },
          icon: const Icon(Icons.logout, color: Colors.red),
        )
      ],
      body: Consumer<AdminProvider>(
        builder: (context, value2, child) {
          return RefreshIndicator(
            onRefresh: () {
              return value2.fetchVouchers(
                isRefreshIndicator: true,
              );
            },
            child: Center(
              child: (value2.loader)
                  ? const PingLoader()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          style: const ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(Colors.white),
                          ),
                          onPressed: () async {
                            await value2.generateVoucher();
                          },
                          child: const Text(
                            "Generate Voucher",
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (scrollNotification) {
                              if (scrollNotification.metrics.pixels >=
                                      scrollNotification.metrics.maxScrollExtent &&
                                  !value2.isLoadingMore &&
                                  value2.hasMore) {
                                value2.fetchVouchers(isLoadMore: true);
                              }
                              return false;
                            },
                            child: (value2.vouchersList.isEmpty)
                                ? const Center(
                                    child: Text(
                                      "No Voucher Found",
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: value2.vouchersList.length + (value2.hasMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == value2.vouchersList.length) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      final voucher = value2.vouchersList[index];
                                      return ListTile(
                                        title: Text("Code: ${voucher.code}"),
                                        subtitle: Text("Used: ${voucher.isUsed ? 'Yes' : 'No'}"),
                                        trailing: ElevatedButton(
                                          style: const ButtonStyle(
                                            backgroundColor: WidgetStatePropertyAll(Colors.white),
                                          ),
                                          onPressed: () async {
                                            value2.copyVoucherCode(voucher.code);
                                          },
                                          child: const Text(
                                            "Copy",
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        )
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
