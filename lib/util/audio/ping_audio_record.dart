import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/util/audio/amplitude_view.dart';
import 'package:ping_app/util/ping_styles.dart';
import 'package:record/record.dart';
import 'package:wear_plus/wear_plus.dart';

class PingAudioRecord extends StatefulWidget {
  const PingAudioRecord({super.key});

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
      appBar: context.isWatch
          ? null
          : AppBar(
              title: Text(
                't_recordAudio'.tr(),
                style: (context.isWatch) ? PingStyles.watchStyle : null,
              ),
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (context.isWatch) ...[
                WatchShape(
                  builder: (context, shape, _) =>
                  shape == WearShape.square ? Row(
                    children: [
                      GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 16,
                          )),
                      Expanded(
                        child: Text(
                          't_recordAudio'.tr(),
                          textAlign: TextAlign.center,
                          style: PingStyles.watchStyle,
                        ),
                      )
                    ],
                  )
                      : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 16,
                          )),
                      const SizedBox(width: 5,),
                      Text(
                        't_recordAudio'.tr(),
                        textAlign: TextAlign.center,
                        style: PingStyles.watchStyle,
                      )
                    ],
                  )
                ),
                const SizedBox(height: 20,),
                Text(
                  'Hold the button to start recording.',
                  style: PingStyles.watchStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10,),
                Container(
                  height: 30,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: AmplitudeView(
                      maxAmplitude: maxAmplitude,
                      amplitudeList: amplitude,
                    ),
                  ),
                ),
              ],
              if (!context.isWatch)
                AmplitudeView(
                  maxAmplitude: maxAmplitude,
                  amplitudeList: amplitude,
                ),
              const SizedBox(
                height: 10,
              ),
              getRecordView(),
              SizedBox(
                height: context.isWatch ? 8 : 20,
              ),
              if (!context.isWatch)
                Text(
                  'Hold the button to record',
                  style: context.isWatch
                      ? PingStyles.watchStyle
                      : const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white),
                  textAlign: TextAlign.center,
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget getRecordView() => GestureDetector(
        // onTapDown: (_) => startRecording(),
        // onTapUp: (_) => stopRecording(),
        onLongPressStart: (_) => startRecording(),
        onLongPressEnd: (_) => stopRecording(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: (context.isWatch)
              ? PingStyles.watchButtonHeight
              : recording
                  ? 112
                  : 56,
          width: (context.isWatch)
              ? PingStyles.watchButtonHeight
              : recording
                  ? 112
                  : 56,
          decoration: BoxDecoration(
            color: recording ? Colors.red : Colors.blue,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mic,
            size: (context.isWatch)
                ? PingStyles.watchIconSize
                : recording
                    ? 56
                    : 28,
          ),
        ),
      );

  void startRecording() async {
    debugPrint("✅ onLongPressStart");
    final hasPermission = await record.hasPermission();
    if (!hasPermission) {
      snack('t_permissionDenied'.tr());
      return;
    }

    setState(() => pathToStoreRecording = null);

    final filePath = (await getTemporaryDirectory()).path;

    await record.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
      ),
      path: '$filePath/audio.wav',
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
    debugPrint("✅ onLongPressStop");
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
