import 'package:flutter/material.dart';
import 'package:ping_app/util/screen_manager/constants.dart';

class BaseBox extends StatelessWidget {
  final Widget child;

  const BaseBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    if (width < minWidth && height < minWidth) {
      return _getBothScrollable();
    }

    if (width < minWidth) {
      return _getHorizontalScrollable(context);
    }

    if (height < minHeight) {
      return _getVerticalScrollable(context);
    }

    if (width > maxDesktopWidth) {
      return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: maxDesktopWidth, child: child));
    }

    if (height > maxDesktopHeight) {
      return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(height: maxDesktopHeight, child: child));
    }

    if (width > minWidth && height > minHeight) {
      return Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: minWidth,
          height: minHeight,
          child: child,
        ),
      );
    }

    return child;
  }

  Widget _getBothScrollable() => SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minWidth, height: minHeight, child: child),
        ),
      );

  Widget _getHorizontalScrollable(BuildContext context) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: minWidth,
          child: child,
        ),
      );

  Widget _getVerticalScrollable(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SizedBox(
          height: minHeight,
          child: child,
        ),
      );
}
