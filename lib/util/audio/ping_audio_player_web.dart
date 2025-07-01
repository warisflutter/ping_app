import 'dart:async';
import 'dart:developer';
import 'package:just_audio/just_audio.dart';
import 'package:easy_localization/easy_localization.dart';
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
  late AudioPlayer player;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final url = widget.url;
      log("Initializing player with URL: $url");

      if (url != null) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        // Wait for the audio to be fully loaded before considering it ready
        await player.setUrl(url);

        // Wait for duration to be available (indicates audio is loaded)
        await player.durationStream.firstWhere((duration) => duration != null);

        setState(() {
          _isLoading = false;
        });

        log("Player initialized successfully with duration: ${player.duration}");
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 't_noAudioSourceProvided'.tr();
        });
        snack('t_noAudioSourceProvided'.tr());
      }
    } catch (e) {
      log("Error initializing player: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load audio: $e";
      });
      snack("Failed to load audio: $e");
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializePlayer,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

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
    return _PlayerWidgetWebState();
  }
}

class _PlayerWidgetWebState extends State<PlayerWidgetWeb> {
  Duration? _duration;
  Duration? _position;
  PlayerState _playerState = PlayerState(false, ProcessingState.idle);

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  bool get _isPlaying => _playerState.playing;
  bool get _isLoading => _playerState.processingState == ProcessingState.loading ||
      _playerState.processingState == ProcessingState.buffering;
  bool get _isCompleted => _playerState.processingState == ProcessingState.completed;

  String get _durationText => _formatDuration(_duration);
  String get _positionText => _formatDuration(_position);

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
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
              onPressed: _canPlay() ? _play : null,
              iconSize: 48.0,
              icon: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.play_arrow),
              color: color,
            ),
            IconButton(
              key: const Key('pause_button'),
              onPressed: _canPause() ? _pause : null,
              iconSize: 48.0,
              icon: const Icon(Icons.pause),
              color: color,
            ),
            IconButton(
              key: const Key('stop_button'),
              onPressed: _canStop() ? _stop : null,
              iconSize: 48.0,
              icon: const Icon(Icons.stop),
              color: color,
            ),
          ],
        ),
        Slider(
          onChanged: _canSeek() ? (value) {
            final duration = _duration;
            if (duration == null) return;

            final position = value * duration.inMilliseconds;
            widget.player.seek(Duration(milliseconds: position.round()));
          } : null,
          value: _getSliderValue(),
        ),
        Text(
          _getTimeText(),
          style: const TextStyle(fontSize: 16.0),
        ),
      ],
    );
  }

  void _initStreams() {
    _durationSubscription = widget.player.durationStream.listen((duration) {
      log("Duration updated: $duration");
      setState(() => _duration = duration);
    });

    _positionSubscription = widget.player.positionStream.listen(
          (position) {
        setState(() => _position = position);
      },
    );

    _playerStateSubscription = widget.player.playerStateStream.listen((state) {
      log("Player state changed: playing=${state.playing}, processingState=${state.processingState}");
      setState(() => _playerState = state);

      if (state.processingState == ProcessingState.completed) {
        log("Playback completed, resetting position");
        setState(() => _position = Duration.zero);
      }
    });
  }

  bool _canPlay() {
    return !_isPlaying &&
        !_isLoading &&
        _duration != null &&
        (_playerState.processingState == ProcessingState.ready ||
            _playerState.processingState == ProcessingState.completed);
  }

  bool _canPause() {
    return _isPlaying && !_isLoading;
  }

  bool _canStop() {
    return (_isPlaying || _isCompleted) && !_isLoading;
  }

  bool _canSeek() {
    return _duration != null &&
        !_isLoading &&
        _playerState.processingState != ProcessingState.idle;
  }

  double _getSliderValue() {
    if (_position != null &&
        _duration != null &&
        _position!.inMilliseconds > 0 &&
        _position!.inMilliseconds < _duration!.inMilliseconds) {
      return _position!.inMilliseconds / _duration!.inMilliseconds;
    }
    return 0.0;
  }

  String _getTimeText() {
    if (_position != null && _duration != null) {
      return '$_positionText / $_durationText';
    } else if (_duration != null) {
      return _durationText;
    }
    return '';
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '';

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  Future<void> _play() async {
    try {
      log("Attempting to play audio. Current state: ${_playerState.processingState}, Duration: $_duration");

      // Ensure audio is ready before playing
      if (_playerState.processingState == ProcessingState.idle) {
        log("Player not ready, cannot play");
        snack("Audio not ready yet, please wait");
        return;
      }

      if (_isCompleted) {
        log("Audio completed, seeking to start");
        await widget.player.seek(Duration.zero);
      }

      // For web, sometimes we need to ensure the player is in the right state
      if (_playerState.processingState == ProcessingState.ready ||
          _playerState.processingState == ProcessingState.completed) {
        await widget.player.play();
        log("Play command executed successfully");
      } else {
        log("Player not in ready state: ${_playerState.processingState}");
        snack("Player not ready, current state: ${_playerState.processingState}");
      }
    } catch (e) {
      log("Error playing audio: $e");
      snack("Failed to play audio: $e");
    }
  }

  Future<void> _pause() async {
    try {
      log("Pausing audio");
      await widget.player.pause();
    } catch (e) {
      log("Error pausing audio: $e");
      snack("Failed to pause audio: $e");
    }
  }

  Future<void> _stop() async {
    try {
      log("Stopping audio");
      await widget.player.stop();
      setState(() => _position = Duration.zero);
    } catch (e) {
      log("Error stopping audio: $e");
      snack("Failed to stop audio: $e");
    }
  }
}