import 'package:flutter/material.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/screen_manager/constants.dart';

class LoadingScreen extends StatefulWidget {
  final dynamic error;
  final String message;

  const LoadingScreen({
    super.key,
    required this.message,
    this.error,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  int count = 1;

  @override
  void initState() {
    updateCounter();
    super.initState();
  }

  void updateCounter() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => count++);
        updateCounter();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(children: [
        Center(
          child: Image.asset("assets/images/logo.png", width: mobileWidth),
        ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.error != null
                  ? getErrorMessage(context, widget.error)
                  : count < 6
                      ? tweenAnimationBuilder()
                      : getLoader(),
              const SizedBox(height: 8),
              Text(widget.message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ]),
    ));
  }

  Widget tweenAnimationBuilder() {
    return TweenAnimationBuilder(
      duration: const Duration(seconds: 1),
      tween: Tween<double>(begin: count - 1, end: count + 0.0),
      builder: (context, double value, child) {
        return CircularProgressIndicator(
          value: value / 5,
          color: Colors.white,
          backgroundColor: Colors.grey.withOpacity(0.1),
        );
      },
    );
  }
}
