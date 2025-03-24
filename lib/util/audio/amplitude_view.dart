import 'package:flutter/material.dart';
import 'package:ping_app/file_path.dart';

class AmplitudeView extends StatelessWidget {
  final List<double> amplitudeList;
  final double maxAmplitude;

  const AmplitudeView({
    super.key,
    required this.maxAmplitude,
    required this.amplitudeList,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (context.isWatch) ? 50 : 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final amp in amplitudeList) getAmplitudeBar(amp),
        ],
      ),
    );
  }

  Widget getAmplitudeBar(double amplitude) {
    return Container(
      width: 2,
      height: amplitude.abs(),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 1),
    );
  }
}
