import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/admin/admin_provider.dart';
import 'package:ping_app/voucher/voucher_provider.dart';
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
      Provider.of<VoucherProvider>(context, listen: false).fetchVoucher();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ping Admin"),
      ),
      body: Consumer2<VoucherProvider, AdminProvider>(builder: (context, value, value2, child) {
        final pendingVouchers = value.userVouchers.where((voucher) => voucher.status == "0").toList();
        final rejectedVouchers = value.userVouchers.where((voucher) => voucher.status == "1").toList();
        final approvedVouchers = value.userVouchers.where((voucher) => voucher.status == "2").toList();

        // Determine which list to display
        final displayedVouchers = (value2.approveOrReject == 0)
            ? pendingVouchers
            : (value2.approveOrReject == 1)
                ? approvedVouchers
                : rejectedVouchers;
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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(40.0),
                        onTap: () {
                          value2.setApproveOrReject(index);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40.0),
                            color: (value2.approveOrReject == index) ? Colors.white : Colors.transparent,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            value.voucherStatus[index],
                            style: TextStyle(
                              color: (value2.approveOrReject == index) ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12.0),
                itemCount: displayedVouchers.length,
                itemBuilder: (context, index) {
                  String title = displayedVouchers[index].pingUserModel.fullName;
                  Map<String, String> statusMap = {
                    'Pending': '0',
                    'Rejected': '1',
                    'Approved': '2',
                  };

                  return ListTile(
                    onTap: () {},
                    title: Text(title),
                    tileColor: Colors.white.withOpacity(0.3),
                    trailing: DropdownButton<String>(
                      value: displayedVouchers[index].status,
                      items: statusMap.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.value,
                          child: Text(entry.key),
                        );
                      }).toList(),
                      onChanged: (newStatus) {
                        if (newStatus != null) {
                          // Update the voucher status
                          Provider.of<VoucherProvider>(context, listen: false)
                              .updateVoucherStatus(displayedVouchers[index].voucherId, newStatus);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
