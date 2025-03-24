import 'package:flutter/material.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/util/ping_styles.dart';

class PingListTile extends StatelessWidget {
  final String title;
  final void Function()? onTap;
  final IconData? iconData;
  final double? verticalH;
  final Color? iconColor, textColor;

  const PingListTile({
    super.key,
    required this.title,
    this.onTap,
    this.iconData,
    this.verticalH,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Builder(
        builder: (context) => Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: (iconData == null) ? Colors.white.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: (!context.isWatch || iconData == null) ? 16.0 : 2.0,
              vertical: verticalH ?? ((context.isWatch) ? 8.0 : 12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (iconData != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      iconData,
                      size: (context.isWatch) ? PingStyles.watchIconSize : null,
                      color: iconColor,
                    ),
                  ),
                Text(
                  title,
                  style: (context.isWatch)
                      ? PingStyles.watchStyle.copyWith(color: textColor)
                      : Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: textColor,
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
