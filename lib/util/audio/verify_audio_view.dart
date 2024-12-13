import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/util/audio/ping_audio_player.dart';
import 'package:ping_app/util/navigator.dart';

class VerifyAudioView extends StatelessWidget {
  final File? audioFile;
  final String? url;

  const VerifyAudioView({super.key, this.audioFile, this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('t_sendAudioMessage'.tr())),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            url != null
                ? PingAudioPlayer(url: url)
                : PingAudioPlayer(file: audioFile),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pop(data: true),
                    child: Text('t_send'.tr()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => pop(data: false),
                    child: Text('t_cancel'.tr()),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
