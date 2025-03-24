import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/admob/v1.dart';
import 'package:ping_app/broadcast/model/broadcast_model.dart';
import 'package:ping_app/broadcast/view/broadcast_detail_view.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/parsers.dart';
import 'package:ping_app/util/ping_styles.dart';
import 'package:ping_app/util/ping_utils.dart';
import 'package:ping_app/widgets/ping_text_field.dart';

class BroadcastListView extends StatelessWidget {
  const BroadcastListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Text(
        't_broadcasts'.tr(),
        style: (context.isWatch) ? PingStyles.watchStyle : null,
      ),
      actions: [
        TextButton.icon(
          icon: Icon(
            Icons.add,
            color: Colors.white,
            size: (context.isWatch) ? PingStyles.watchIconSize : null,
          ),
          label: Text(
            't_newBroadcast'.tr(),
            style: (context.isWatch) ? PingStyles.watchStyle : const TextStyle(color: Colors.white),
          ),
          onPressed: () async {
            final isInternetAvailable = await context.isInternetAvailable();
            if (isInternetAvailable) {
              if (context.mounted) {
                _showNewBroadcastDialog(context);
              }
            } else {
              snack("t_noInternetPleaseConnectToTheInternet".tr());
            }
          },
        ),
      ],
       ),
      body: StreamBuilder<List<BroadcastModel>>(
        stream: BroadcastRepository.instance.getAllBroadcasts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return getLoader();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return getErrorMessage(context, 't_noBroadcastGroupCreated'.tr());
          }
          return LayoutBuilder(builder: (context, constraints) {
            double maxWidth = constraints.maxWidth > 800 ? 200.0 : 16.0;
            return ListView.builder(
              padding: (kIsWeb)
                  ? EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: maxWidth,
                    )
                  : EdgeInsets.zero,
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final broadcast = snapshot.data![index];
                return ListTile(
                  title: Text(
                    broadcast.name,
                    style: (context.isWatch) ? PingStyles.watchStyle : null,
                  ),
                  subtitle: Text(
                    parseDate(broadcast.createdAt),
                    style: (context.isWatch) ? PingStyles.watchStyle : null,
                  ),
                  trailing: Text(
                    '${broadcast.memberIds.length} ${"members".tr()}',
                    style: (context.isWatch) ? PingStyles.watchStyle : null,
                  ),
                  onTap: () => push(BroadcastDetailView(initialBroadcast: broadcast)),
                );
              },
            );
          });
        },
      ),
    );
  }

  void _showNewBroadcastDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newBroadcastName = '';
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          contentPadding: (context.isWatch) ? const EdgeInsets.symmetric(horizontal: 8.0) : null,
          insetPadding: (context.isWatch) ? const EdgeInsets.symmetric(horizontal: 8.0) : null,
          title: Text(
            't_newBroadcast'.tr(),
            style: (context.isWatch) ? PingStyles.watchStyle : null,
          ),
          content: (!context.isWatch)
              ? PingTextField(
                  onChanged: (value) => newBroadcastName = value,
                  hintText: 't_enterBroadcastName'.tr(),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: PingTextField(
                        onChanged: (value) => newBroadcastName = value,
                        hintText: 't_enterBroadcastName'.tr(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            child: Text(
                              't_cancel'.tr(),
                              style: (context.isWatch) ? PingStyles.watchStyle : null,
                            ),
                            onTap: () => pop(),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            child: Text(
                              't_add'.tr(),
                              style: (context.isWatch) ? PingStyles.watchStyle : null,
                            ),
                            onTap: () async {
                              if (newBroadcastName.isNotEmpty) {
                                BroadcastRepository.instance.addBroadcast(newBroadcastName);
                                pop();
                              } else {
                                snack("broadcast name is empty");
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          actions: (context.isWatch)
              ? []
              : <Widget>[
                  TextButton(
                    child: Text(
                      't_cancel'.tr(),
                      style: (context.isWatch) ? PingStyles.watchStyle : null,
                    ),
                    onPressed: () => pop(),
                  ),
                  TextButton(
                    child: Text(
                      't_add'.tr(),
                      style: (context.isWatch) ? PingStyles.watchStyle : null,
                    ),
                    onPressed: () async {
                      if (newBroadcastName.isNotEmpty) {
                        BroadcastRepository.instance.addBroadcast(newBroadcastName);
                        pop();
                      } else {
                        snack("broadcast name is empty");
                      }
                    },
                  ),
                ],
        );
      },
    );
  }
}
