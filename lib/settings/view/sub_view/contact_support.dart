import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupport extends StatelessWidget {
  const ContactSupport({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key("viewContactSupport"),
      appBar: AppBar(title: Text('t_contactSupport'.tr())),
      body: Container(
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ListTile(
            //   title: const Text("(+41) 79 713 66 66"),
            //   leading: const Icon(Icons.phone),
            //   onTap: () async {
            //     Uri uri = Uri(scheme: "tel", path: "+41797136666");
            //     if (await canLaunchUrl(uri)) {
            //       await launchUrl(uri);
            //     } else {
            //       snack("Can't make a call");
            //     }
            //   },
            // ),
            ListTile(
              title: const Text("office@pingapp.ch"),
              leading: const Icon(Icons.email),
              onTap: () async {
                Uri uri = Uri(
                  scheme: "mailto",
                  path: "office@pingapp.ch",
                  queryParameters: {"subject": 't_pingAppSupport'.tr()},
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  snack('t_cantSendEmail'.tr());
                }
              },
            ),
            ListTile(
              title: const Text("www.pingapp.ch"),
              leading: const Icon(Icons.web),
              onTap: () {
                Uri uri = Uri.parse("https://www.pingapp.ch");
                launchUrl(uri);
              },
            ),
          ],
        ),
      ),
    );
  }
}
