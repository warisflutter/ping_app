import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/view/create_account_view.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/view/admin/admin_provider.dart';
import 'package:ping_app/view/voucher/voucher_provider.dart';
import 'package:ping_app/widgets/selection_widget.dart';
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
      Provider.of<AdminProvider>(context, listen: false).getAdmin();
      Provider.of<VoucherProvider>(context, listen: false).initAdmin();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Ping Admin"),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              replace(const CreateAccountView());
            },
            icon: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
          )
        ],
      ),
      body: Consumer2<VoucherProvider, AdminProvider>(
        builder: (context, value, value2, child) {
          return Column(
            children: [
              Container(
                width: 300,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40.0),
                  color: Colors.white.withOpacity(0.3),
                ),
                child: Row(
                  children: [
                    ...List.generate(value.voucherStatus.length, (index) {
                      return Expanded(
                        child: SelectionWidget(
                          onTap: () {
                            value.setApproveOrReject(index);
                          },
                          type: value.approveOrReject,
                          index: index,
                          text: value.voucherStatus[index],
                        ),
                      );
                    }),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
              Expanded(
                child: (value.loader)
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12.0),
                        itemCount: value.displayedVouchers.length,
                        itemBuilder: (context, index) {
                          String title = value.displayedVouchers[index].pingUserModel.fullName;
                          List<String> statusTypeMap = ['Basic', 'Expert', 'Pro'];
                          return Container(
                            margin: const EdgeInsets.all(12.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              color: Colors.white.withOpacity(0.3),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Type"),
                                        DropdownButton<String>(
                                          value: value.selectedVoucherType[index],
                                          items: statusTypeMap.map((entry) {
                                            return DropdownMenuItem<String>(
                                              value: entry,
                                              child: Text(entry),
                                            );
                                          }).toList(),
                                          onChanged: (newStatus) {
                                            if (newStatus != null) {
                                              value.setVoucherType(newStatus, index);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("t_status".tr()),
                                        DropdownButton<String>(
                                          value: value.selectedVoucherStatus[index],
                                          items: value.voucherStatus.map((entry) {
                                            return DropdownMenuItem<String>(
                                              value: entry,
                                              child: Text(entry),
                                            );
                                          }).toList(),
                                          onChanged: (newStatus) {
                                            if (newStatus != null) {
                                              value.setVoucherStatus(newStatus, index);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.center,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Provider.of<VoucherProvider>(context, listen: false)
                                          .updateVoucher(value.displayedVouchers[index].voucherId, index);
                                    },
                                    child: Text("t_continue".tr()),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
