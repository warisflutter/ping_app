import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/broadcast/model/broadcast_model.dart';
import 'package:ping_app/broadcast/view/broadcast_detail_view.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/parsers.dart';

class BroadcastListView extends StatelessWidget {
  const BroadcastListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('t_broadcasts'.tr()),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              't_newBroadcast'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () => _showNewBroadcastDialog(context),
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
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final broadcast = snapshot.data![index];
              return ListTile(
                title: Text(broadcast.name),
                subtitle: Text(parseDate(broadcast.createdAt)),
                trailing:
                    Text('${broadcast.memberIds.length} ${"members".tr()}'),
                onTap: () =>
                    push(BroadcastDetailView(initialBroadcast: broadcast)),
              );
            },
          );
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
          title: Text('t_newBroadcast'.tr()),
          content: TextField(
            onChanged: (value) => newBroadcastName = value,
            decoration: InputDecoration(hintText: 't_enterBroadcastName'.tr()),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('t_cancel'.tr()),
              onPressed: () => pop(),
            ),
            TextButton(
              child: Text('t_add'.tr()),
              onPressed: () {
                if (newBroadcastName.isNotEmpty) {
                  BroadcastRepository.instance
                      .addBroadcast(BroadcastModel(name: newBroadcastName));
                  pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
