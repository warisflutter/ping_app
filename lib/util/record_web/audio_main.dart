import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/util/record_web/audio_player.dart';
import 'package:ping_app/util/record_web/audio_recorder.dart';

class AudioRecordWeb extends StatefulWidget {
  const AudioRecordWeb({super.key});

  @override
  State<AudioRecordWeb> createState() => _AudioRecordWebState();
}

class _AudioRecordWebState extends State<AudioRecordWeb> {
  String? audioPath;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final audioPath = this.audioPath;
    return Scaffold(
      appBar: AppBar(title:  Text('t_audioRecorder'.tr())),
      body: Center(
        child: audioPath != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: AudioPlayer(
                  source: audioPath,
                  onDelete: () => setState(() => this.audioPath = null),
                ),
              )
            : Recorder(
                onStop: (path) => setState(() => this.audioPath = path),
              ),
      ),
    );
  }
}
