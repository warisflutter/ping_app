import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/util/navigator.dart';

class CaptchaAlertDialog extends StatefulWidget {
  const CaptchaAlertDialog({super.key});

  @override
  State<CaptchaAlertDialog> createState() => _CaptchaAlertDialogState();
}

class _CaptchaAlertDialogState extends State<CaptchaAlertDialog> {
  String? _captchaText;

  final enteredCaptcha = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_captchaText == null) {
      _generateCaptcha();
    }
  }

  void _generateCaptcha() {
    const String chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    Random rnd = Random();
    String result = '';
    for (var i = 0; i < 6; i++) {
      result += chars[rnd.nextInt(chars.length)];
    }
    setState(() {
      _captchaText = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('t_verifyCaptcha'.tr()),
      actions: [
        TextButton(
          onPressed: () => _generateCaptcha(),
          child: Text('t_regenerate'.tr()),
        ),
        TextButton(
          onPressed: () => pop(data: enteredCaptcha.text == _captchaText),
          child: Text('t_done'.tr()),
        ),
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              painter: AdvancedCaptchaPainter(_captchaText ?? ""),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: enteredCaptcha,
            decoration: InputDecoration(
                hintText: 't_enterCaptcha'.tr(),
                prefixIcon: const Icon(Icons.security)),
          ),
        ],
      ),
    );
  }
}

class AdvancedCaptchaPainter extends CustomPainter {
  final String captchaText;
  final Random random = Random();

  AdvancedCaptchaPainter(this.captchaText);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.grey[100]!;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Draw complex background pattern
    drawComplexBackground(canvas, size);

    // Draw distorted characters
    drawDistortedCharacters(canvas, size);

    // Draw overlapping lines
    drawOverlappingLines(canvas, size);

    // Add noise
    addNoise(canvas, size);
  }

  void drawComplexBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < 20; i++) {
      paint.color = Color.fromRGBO(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
        0.1,
      );

      Path path = Path();
      path.moveTo(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      for (int j = 0; j < 5; j++) {
        path.quadraticBezierTo(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  void drawDistortedCharacters(Canvas canvas, Size size) {
    final charWidth = size.width / captchaText.length;

    for (int i = 0; i < captchaText.length; i++) {
      final charOffset = Offset(
        i * charWidth + random.nextDouble() * 10 - 5,
        size.height / 2 + random.nextDouble() * 20 - 10,
      );

      canvas.save();
      canvas.translate(charOffset.dx, charOffset.dy);
      canvas.rotate(random.nextDouble() * 0.5 - 0.25);

      // Apply wave distortion
      final waveDistortion = sin(i * 0.5) * 5;
      canvas.translate(0, waveDistortion);

      // Apply perspective transform
      final perspective = random.nextDouble() * 0.2 + 0.8;
      final transform = Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..scale(1.0, perspective, 1.0);
      canvas.transform(transform.storage);
      List<Color> colors = [];
      for (var i = 0; i < captchaText.length; i++) {
        colors.add(Color.fromARGB(
          255,
          random.nextInt(200),
          random.nextInt(200),
          random.nextInt(200),
        ));
      }
      // Draw character with outline
      drawTextWithOutline(
        canvas,
        captchaText[i],
        colors[i],
        fontSize: 36 + random.nextInt(8) + 0.0,
      );

      canvas.restore();
    }
  }

  void drawTextWithOutline(Canvas canvas, String text, Color color,
      {required double fontSize}) {
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black.withOpacity(0.5),
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      //TODO: Verify captcha working properly
      // textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);

    // Fill text
    final fillTextStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: color,
    );
    final fillTextSpan = TextSpan(text: text, style: fillTextStyle);
    final fillTextPainter = TextPainter(
      text: fillTextSpan,
      //TODO: Verify captcha working properly
      // textDirection: TextDirection.ltr,
    );
    fillTextPainter.layout();
    fillTextPainter.paint(canvas, Offset.zero);
  }

  void drawOverlappingLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final path = Path();
      path.moveTo(
          random.nextDouble() * size.width, random.nextDouble() * size.height);
      for (int j = 0; j < 4; j++) {
        path.quadraticBezierTo(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  void addNoise(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.1);
    for (int i = 0; i < 1000; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width,
            random.nextDouble() * size.height),
        random.nextDouble() * 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is AdvancedCaptchaPainter) {
      return oldDelegate.captchaText != captchaText;
    }
    return true;
  }
}
