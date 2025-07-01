import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/util/audio/ping_audio_player.dart';
import 'package:ping_app/util/audio/ping_audio_player_web.dart';
import 'package:ping_app/util/ping_styles.dart';
import 'package:wear_plus/wear_plus.dart';

class VerifyAudioView extends StatelessWidget {
  final File? audioFile;
  final String? url;

  const VerifyAudioView({super.key, this.audioFile, this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: context.isWatch ? null : AppBar(
        centerTitle: false,
        title: Text(
          't_sendAudioMessage'.tr(),
          style: (context.isWatch) ? PingStyles.watchStyle : null,
        ),
      ),
      body: SafeArea(
        child: (context.isWatch)
            ? SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8.0),
                    WatchShape(
                      builder: (context, shape , _) => shape == WearShape.square ? Row(
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Icon(Icons.arrow_back, size: 16,)),
                              Expanded(
                                child: Text(
                                  't_sendAudioMessage'.tr(),
                                  style: PingStyles.watchStyle,
                                  textAlign: TextAlign.center,
                                ),
                              )
                            ],
                          )
                        ],
                      )
                          : Column(
                        children: [
                          GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.arrow_back, size: 16,)),
                          const SizedBox(height: 5,),
                          Text(
                            't_sendAudioMessage'.tr(),
                            style: PingStyles.watchStyle,
                          )
                        ],
                      ) ,
                    ),
                    (url != null) ? PingAudioPlayerWeb(url: url) : PingAudioPlayer(file: audioFile),
                    const SizedBox(height: 2,),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: context.isWatch ? 30.0 : 48.0, // Chhota height for watch
                              child: ElevatedButton(
                                onPressed: () => pop(data: true),
                                style: ElevatedButton.styleFrom(
                                  textStyle: context.isWatch ? PingStyles.watchStyle : null,
                                  padding: context.isWatch ? const EdgeInsets.symmetric(vertical: 4.0) : null,
                                ),
                                child: Text('t_send'.tr()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2.0),
                          Expanded(
                            child: SizedBox(
                              height: context.isWatch ? 30.0 : 48.0, // Same adjustment for OutlinedButton
                              child: OutlinedButton(
                                onPressed: () => pop(data: false),
                                style: OutlinedButton.styleFrom(
                                  textStyle: context.isWatch ? PingStyles.watchStyle : null,
                                  padding: context.isWatch ? const EdgeInsets.symmetric(vertical: 4.0) : null,
                                ),
                                child: Text('t_cancel'.tr()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  (url != null) ? PingAudioPlayerWeb(url: url) : PingAudioPlayer(file: audioFile),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => pop(data: true),
                            child: Text(
                              't_send'.tr(),
                              style: (context.isWatch) ? PingStyles.watchStyle : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => pop(data: false),
                            child: Text(
                              't_cancel'.tr(),
                              style: (context.isWatch) ? PingStyles.watchStyle : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
