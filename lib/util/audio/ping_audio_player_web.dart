import 'dart:async';
import 'dart:developer';
import 'package:just_audio/just_audio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/util/messenger.dart';

class PingAudioPlayerWeb extends StatefulWidget {
  final String? url;

  const PingAudioPlayerWeb({
    this.url,
    super.key,
  }) : assert(url != null);

  @override
  State<PingAudioPlayerWeb> createState() => _PingAudioPlayerWebState();
}

class _PingAudioPlayerWebState extends State<PingAudioPlayerWeb> {
  late AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();

    player = AudioPlayer();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final url = widget.url;
      log("url: $url");
      if (url != null) {
        await player.setUrl(url);
      } else {
        snack('t_noAudioSourceProvided'.tr());
      }
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlayerWidgetWeb(player: player);
  }
}

class PlayerWidgetWeb extends StatefulWidget {
  final AudioPlayer player;

  const PlayerWidgetWeb({
    required this.player,
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _PlayerWidgetState();
  }
}

class _PlayerWidgetState extends State<PlayerWidgetWeb> {
  Duration? _duration;
  Duration? _position;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  bool get _isPlaying => widget.player.playing;

  String get _durationText => _duration?.toString().split('.').first ?? '';

  String get _positionText => _position?.toString().split('.').first ?? '';

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: const Key('play_button'),
              onPressed: _isPlaying ? null : _play,
              iconSize: 48.0,
              icon: const Icon(Icons.play_arrow),
              color: color,
            ),
            IconButton(
              key: const Key('pause_button'),
              onPressed: _isPlaying ? _pause : null,
              iconSize: 48.0,
              icon: const Icon(Icons.pause),
              color: color,
            ),
            IconButton(
              key: const Key('stop_button'),
              onPressed: _isPlaying ? _stop : null,
              iconSize: 48.0,
              icon: const Icon(Icons.stop),
              color: color,
            ),
          ],
        ),
        Slider(
          onChanged: (value) {
            final duration = _duration;
            if (duration == null) {
              return;
            }
            final position = value * duration.inMilliseconds;
            widget.player.seek(Duration(milliseconds: position.round()));
          },
          value: (_position != null &&
              _duration != null &&
              _position!.inMilliseconds > 0 &&
              _position!.inMilliseconds < _duration!.inMilliseconds)
              ? _position!.inMilliseconds / _duration!.inMilliseconds
              : 0.0,
        ),
        Text(
          _position != null
              ? '$_positionText / $_durationText'
              : _duration != null
              ? _durationText
              : '',
          style: const TextStyle(fontSize: 16.0),
        ),
      ],
    );
  }

  void _initStreams() {
    _durationSubscription = widget.player.durationStream.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = widget.player.positionStream.listen(
          (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = widget.player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        setState(() {
          _position = Duration.zero;
        });
        widget.player.seek(Duration.zero);
        widget.player.pause();
      }
    });
  }

  Future<void> _play() async {
    if (widget.player.processingState == ProcessingState.completed) {
      await widget.player.seek(Duration.zero); // Reset position
    }
    await widget.player.play();
  }

  Future<void> _pause() async {
    await widget.player.pause();
  }

  Future<void> _stop() async {
    await widget.player.stop();
    setState(() {
      _position = Duration.zero;
    });
  }
}
