import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ping_app/util/audio/amplitude_view.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:record/record.dart';

class PingAudioRecord extends StatefulWidget {
  const PingAudioRecord({
    super.key,
  });

  @override
  State<PingAudioRecord> createState() => _PingAudioRecordState();
}

class _PingAudioRecordState extends State<PingAudioRecord> {
  final record = AudioRecorder();

  String? pathToStoreRecording;

  bool get recording => pathToStoreRecording != null;

  List<double> amplitude = [];
  double maxAmplitude = 0;
  StreamSubscription? amplitudeSubscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    record.dispose();
    if (amplitudeSubscription != null) {
      amplitudeSubscription!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  Text('t_recordAudio'.tr())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AmplitudeView(
                maxAmplitude: maxAmplitude,
                amplitudeList: amplitude,
              ),
              getRecordView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget getRecordView() => GestureDetector(
        onTapDown: (_) => startRecording(),
        onTapUp: (_) => stopRecording(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: recording ? 112 : 56,
          width: recording ? 112 : 56,
          decoration: BoxDecoration(
            color: recording ? Colors.red : Colors.blue,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.mic, size: recording ? 56 : 28),
        ),
      );

  void startRecording() async {
    final hasPermission = await record.hasPermission();
    if (!hasPermission) {
      snack('t_permissionDenied'.tr());
      return;
    }

    setState(() => pathToStoreRecording = null);

    final filePath = (await getTemporaryDirectory()).path;

    await record.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
      ),
      path: '$filePath/audio.m4a',
    );
    if (amplitudeSubscription != null) {
      await amplitudeSubscription!.cancel();
    }

    setState(() {
      maxAmplitude = 0;
      amplitude = [];
    });

    amplitudeSubscription = record
        .onAmplitudeChanged(const Duration(milliseconds: 500))
        .listen((event) {
      setState(() {
        maxAmplitude = event.max;
        amplitude.add(event.current);
      });
    });
    setState(() => pathToStoreRecording = filePath);
  }

  void stopRecording() async {
    final path = await record.stop();
    if (path == null) {
      snack('t_failedToSaveRecording'.tr());
      return;
    }
    if (amplitudeSubscription != null) {
      await amplitudeSubscription!.cancel();
    }
    setState(() => pathToStoreRecording = null);
    await Future.delayed(const Duration(milliseconds: 200));
    pop(data: File(path));
  }
}
