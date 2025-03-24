import 'package:flutter/material.dart';

class GlobalLayoutBuilder extends StatelessWidget {
  final Widget child;

  const GlobalLayoutBuilder({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = (constraints.maxWidth > 600) ? 500 : double.infinity;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class DialogLayoutBuilder extends StatelessWidget {
  final Widget child;
  final double? width;

  const DialogLayoutBuilder({
    super.key,
    required this.child,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double dialogWidth = constraints.maxWidth > 600 ? (width) ?? 500 : constraints.maxWidth * 0.9;
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
