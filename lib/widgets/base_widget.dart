import 'package:flutter/material.dart';
import 'package:ping_app/util/ping_utils.dart';

class BaseWidget extends StatelessWidget {
  final Widget? title, floatingActionButton;
  final bool? centerTitle;
  final List<Widget>? actions;
  final bool showBackIcon;
  final Widget body;
  const BaseWidget({
    super.key,
    this.title,
    this.centerTitle,
    this.actions,
    this.showBackIcon = true,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: centerTitle,
        actions: actions,
        title: title,
        leading: (showBackIcon)
            ? BackButton(
                style: ButtonStyle(
                  iconSize: WidgetStatePropertyAll((context.isWatch) ? 15 : null),
                ),
              )
            : null,
        toolbarHeight: (context.isWatch) ? 30 : kToolbarHeight,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
