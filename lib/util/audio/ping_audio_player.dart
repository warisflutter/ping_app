import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/util/ping_styles.dart';

class PingAudioPlayer extends StatefulWidget {
  final String? url;
  final File? file;

  const PingAudioPlayer({
    this.url,
    this.file,
    super.key,
  }) : assert(url != null || file != null);

  @override
  State<PingAudioPlayer> createState() => _PingAudioPlayerState();
}

class _PingAudioPlayerState extends State<PingAudioPlayer> {
  late AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();

    player = AudioPlayer();

    player.setReleaseMode(ReleaseMode.stop);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final url = widget.url;
      final file = widget.file;
      log("url: $url");
      log("file: $file");
      if (url != null) {
        await player.setSource(UrlSource(
          url,
          mimeType: 'audio/aac',
        ));
      } else if (file != null) {
        await player.setSource(DeviceFileSource(file.path));
      } else {
        snack('t_noAudioSourceProvided'.tr());
      }
    });
  }

  @override
  void dispose() {
    // Release all sources and dispose the player.
    player.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlayerWidget(player: player);
  }
}

class PlayerWidget extends StatefulWidget {
  final AudioPlayer player;

  const PlayerWidget({
    required this.player,
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _PlayerWidgetState();
  }
}

class _PlayerWidgetState extends State<PlayerWidget> {
  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  bool get _isPlaying => _playerState == PlayerState.playing;

  bool get _isPaused => _playerState == PlayerState.paused;

  String get _durationText => _duration?.toString().split('.').first ?? '';

  String get _positionText => _position?.toString().split('.').first ?? '';

  AudioPlayer get player => widget.player;

  @override
  void initState() {
    super.initState();
    // Use initial values from player
    _playerState = player.state;
    player.getDuration().then(
          (value) => setState(() {
            _duration = value;
          }),
        );
    player.getCurrentPosition().then(
          (value) => setState(() {
            _position = value;
          }),
        );
    player.resume().then((value) => player.pause());
    _initStreams();
  }

  @override
  void setState(VoidCallback fn) {
    // Subscriptions only can be closed asynchronously,
    // therefore events can occur after widget has been disposed.
    if (mounted) {
      super.setState(fn);
    }
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
    return (context.isWatch)
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: IconButton(
                      key: const Key('play_button'),
                      onPressed: _isPlaying ? null : _play,
                      iconSize: PingStyles.watchIconSize,
                      icon: const Icon(Icons.play_arrow),
                      color: color,
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      key: const Key('pause_button'),
                      onPressed: _isPlaying ? _pause : null,
                      iconSize: PingStyles.watchIconSize,
                      icon: const Icon(Icons.pause),
                      color: color,
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      key: const Key('stop_button'),
                      onPressed: _isPlaying || _isPaused ? _stop : null,
                      iconSize: PingStyles.watchIconSize,
                      icon: const Icon(Icons.stop),
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 10,
                child: Slider(
                  onChanged: (value) {
                    final duration = _duration;
                    if (duration == null) {
                      return;
                    }
                    final position = value * duration.inMilliseconds;
                    player.seek(Duration(milliseconds: position.round()));
                  },
                  value: (_position != null &&
                          _duration != null &&
                          _position!.inMilliseconds > 0 &&
                          _position!.inMilliseconds < _duration!.inMilliseconds)
                      ? _position!.inMilliseconds / _duration!.inMilliseconds
                      : 0.0,
                ),
              ),
              Text(
                _position != null
                    ? '$_positionText / $_durationText'
                    : _duration != null
                        ? _durationText
                        : '',
                style: TextStyle(
                  fontSize: PingStyles.watchIconSize,
                ),
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: IconButton(
                      key: const Key('play_button'),
                      onPressed: _isPlaying ? null : _play,
                      iconSize: context.isWatch ? 32.0 : 48.0,
                      icon: const Icon(Icons.play_arrow),
                      color: color,
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      key: const Key('pause_button'),
                      onPressed: _isPlaying ? _pause : null,
                      iconSize: context.isWatch ? 32.0 : 48.0, // Adjusted for watch
                      icon: const Icon(Icons.pause),
                      color: color,
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      key: const Key('stop_button'),
                      onPressed: _isPlaying || _isPaused ? _stop : null,
                      iconSize: context.isWatch ? 32.0 : 48.0, // Adjusted for watch
                      icon: const Icon(Icons.stop),
                      color: color,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.isWatch ? 20.0 : 30.0),
              SizedBox(
                height: context.isWatch ? 16.0 : 24.0,
                child: Slider(
                  onChanged: (value) {
                    final duration = _duration;
                    if (duration == null) {
                      return;
                    }
                    final position = value * duration.inMilliseconds;
                    player.seek(Duration(milliseconds: position.round()));
                  },
                  value: (_position != null &&
                          _duration != null &&
                          _position!.inMilliseconds > 0 &&
                          _position!.inMilliseconds < _duration!.inMilliseconds)
                      ? _position!.inMilliseconds / _duration!.inMilliseconds
                      : 0.0,
                ),
              ),
              Text(
                _position != null
                    ? '$_positionText / $_durationText'
                    : _duration != null
                        ? _durationText
                        : '',
                style: TextStyle(
                  fontSize: context.isWatch ? 12.0 : 16.0, // Smaller text for watch
                ),
              ),
            ],
          );
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = player.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    });

    _playerStateChangeSubscription = player.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
      });
    });
  }

  Future<void> _play() async {
    await player.resume();
    setState(() => _playerState = PlayerState.playing);
  }

  Future<void> _pause() async {
    await player.pause();
    setState(() => _playerState = PlayerState.paused);
  }

  Future<void> _stop() async {
    await player.stop();
    setState(() {
      _playerState = PlayerState.stopped;
      _position = Duration.zero;
    });
  }
}
