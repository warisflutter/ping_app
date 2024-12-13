import 'package:flutter/material.dart';

class MemberColorSelectorView extends StatefulWidget {
  final Color? initialColor;
  final Function(Color) onColorSelected;

  const MemberColorSelectorView({
    super.key,
    this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<MemberColorSelectorView> createState() =>
      _MemberColorSelectorViewState();
}

class _MemberColorSelectorViewState extends State<MemberColorSelectorView> {
  final List<Color> colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.brown,
    Colors.transparent,
  ];

  Color? selectedColor;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((color) {
        bool isSelected = color == selectedColor;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedColor = color;
            });
            widget.onColorSelected(color);
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : color == Colors.transparent
                      ? Border.all(
                          color: Colors.white.withOpacity(0.5), width: 3)
                      : null,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? Icon(Icons.check,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
