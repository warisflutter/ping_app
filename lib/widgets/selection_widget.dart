import 'package:flutter/material.dart';

class SelectionWidget extends StatelessWidget {
  final void Function()? onTap;
  final int type, index;
  final String text;
  const SelectionWidget({
    super.key,
    this.onTap,
    required this.type,
    required this.index,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(40.0),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40.0),
          color: (type == index) ? Colors.white : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: (type == index) ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
