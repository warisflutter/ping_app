import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/widgets/global_layout_builder.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../repo/member_state.dart';

class MemberQrCode extends StatelessWidget {
  final String memberId;
  final screenshotController = ScreenshotController();

  MemberQrCode({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    final memberState = context.watch<MemberState>();
    return Scaffold(
      appBar: AppBar(title: Text('t_memberQrCode'.tr())),
      body: SafeArea(
        child: GlobalLayoutBuilder(
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
                    // final tempDir = await getTemporaryDirectory();
                    // final imagePath = "${tempDir.path}/qr_code.png";
                    // final file = File(imagePath);
                    // await file.writeAsBytes(image);
                    // final uri = Uri.file(imagePath);
                    // await Share.shareUri(uri);
                    if (!kIsWeb) {
                      await shareMemberWithQr(image, memberId,
                          memberState.teamLead?.teamName ?? '');
                    }
                  }
                },
                label: Text('t_share'.tr()),
                icon: const Icon(Icons.share),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: memberId));
                  snack("${'t_idCopied'.tr()}: $memberId", info: true);
                },
                child: Text("${'t_copyUserId'.tr()}: $memberId"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> shareMemberWithQr(
      Uint8List imageBytes, String memberId, String teamName) async {
    final tempDir = await getTemporaryDirectory();
    final imagePath = '${tempDir.path}/qr_code.png';
    final file = File(imagePath);
    await file.writeAsBytes(imageBytes);
    final xFile = XFile(imagePath, mimeType: 'image/png');
    final message = '''
👋 Join $teamName's team on Ping!
  📲 Member ID: $memberId
  📷 Scan the QR code or enter the code manually in the app.
''';
    await Share.shareXFiles([xFile],
        text: message, subject: 'Join My Ping Team');
  }
}
