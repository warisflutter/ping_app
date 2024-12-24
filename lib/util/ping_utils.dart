import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

extension PingUtils on BuildContext {
  Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw Exception("Could not launch $url");
    }
  }
}
