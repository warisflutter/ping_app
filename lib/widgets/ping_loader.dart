import 'package:flutter/material.dart';

class PingLoader extends StatelessWidget {
  const PingLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator.adaptive());
  }
}
