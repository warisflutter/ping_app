import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/util/ping_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupport extends StatelessWidget {
  const ContactSupport({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key("viewContactSupport"),
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
            ListTile(
              title: const Text("office@pingapp.ch"),
              leading: const Icon(Icons.email),
              onTap: () async {
                await context.sendEmail();
              },
            ),
            ListTile(
              title: const Text("www.pingapp.ch"),
              leading: const Icon(Icons.web),
              onTap: () async {
                Uri uri = Uri.parse("https://www.pingapp.ch");
                await launchUrl(uri);
              },
            ),
          ],
        ),
      ),
    );
  }
}
