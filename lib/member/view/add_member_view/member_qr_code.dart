import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/ping_utils.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class MemberQrCode extends StatelessWidget {
  final String memberId;
  final screenshotController = ScreenshotController();

  MemberQrCode({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('t_memberQrCode'.tr())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            alignment: Alignment.center,
            height: context.screenHeight * 0.8,
            width: context.screenWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Screenshot(
                  controller: screenshotController,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: QrImageView(
                        data: memberId,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  't_scanThisAsMember'.tr(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    final image = await screenshotController.capture();
                    if (image != null) {
                      final tempDir = await getTemporaryDirectory();
                      final imagePath = "${tempDir.path}/qr_code.png";
                      final file = File(imagePath);
                      await file.writeAsBytes(image);
                      final uri = Uri.file(imagePath);
                      await Share.shareUri(uri);
                    }
                  },
                  label: Text('t_share'.tr()),
                  icon: const Icon(Icons.share),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: memberId));
                    snack('t_idCopied'.tr(), info: true);
                  },
                  child: Text('t_copyUserId'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
