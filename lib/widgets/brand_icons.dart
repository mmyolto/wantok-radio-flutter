import 'package:flutter/material.dart';

/// WhatsApp glyph (vector, from the original app) drawn at any size.
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 24, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? IconTheme.of(context).color ?? Colors.white;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _WhatsAppPainter(c)),
    );
  }
}

class _WhatsAppPainter extends CustomPainter {
  _WhatsAppPainter(this.color);
  final Color color;

  static final Path _path = Path()
    ..moveTo(16.75, 13.96)
    ..cubicTo(16.5, 13.83, 15.25, 13.22, 15.01, 13.14)
    ..cubicTo(14.77, 13.05, 14.6, 13.01, 14.43, 13.27)
    ..cubicTo(14.26, 13.53, 13.78, 14.09, 13.63, 14.27)
    ..cubicTo(13.49, 14.44, 13.34, 14.46, 13.09, 14.33)
    ..cubicTo(12.84, 14.2, 12.04, 13.94, 11.09, 13.1)
    ..cubicTo(10.35, 12.44, 9.85, 11.63, 9.71, 11.38)
    ..cubicTo(9.57, 11.13, 9.69, 11, 9.82, 10.87)
    ..cubicTo(9.93, 10.76, 10.07, 10.58, 10.19, 10.44)
    ..cubicTo(10.32, 10.3, 10.36, 10.19, 10.44, 10.03)
    ..cubicTo(10.52, 9.86, 10.48, 9.72, 10.42, 9.59)
    ..cubicTo(10.36, 9.46, 9.84, 8.19, 9.62, 7.68)
    ..cubicTo(9.41, 7.17, 9.2, 7.24, 9.04, 7.23)
    ..lineTo(8.54, 7.23)
    ..cubicTo(8.37, 7.23, 8.09, 7.29, 7.86, 7.55)
    ..cubicTo(7.62, 7.8, 6.95, 8.44, 6.95, 9.73)
    ..cubicTo(6.95, 11.02, 7.89, 12.26, 8.02, 12.44)
    ..cubicTo(8.15, 12.61, 9.87, 15.27, 12.5, 16.41)
    ..cubicTo(13.13, 16.68, 13.61, 16.84, 13.99, 16.96)
    ..cubicTo(14.62, 17.16, 15.2, 17.13, 15.65, 17.07)
    ..cubicTo(16.16, 16.99, 17.15, 16.46, 17.36, 15.86)
    ..cubicTo(17.57, 15.27, 17.57, 14.76, 17.51, 14.65)
    ..cubicTo(17.44, 14.55, 17.28, 14.49, 17.03, 14.36)
    ..close()
    ..moveTo(12.04, 2)
    ..cubicTo(6.58, 2, 2.13, 6.45, 2.13, 11.91)
    ..cubicTo(2.13, 13.66, 2.59, 15.36, 3.45, 16.86)
    ..lineTo(2, 22)
    ..lineTo(7.25, 20.62)
    ..cubicTo(8.7, 21.41, 10.33, 21.83, 12.02, 21.83)
    ..cubicTo(17.48, 21.83, 21.93, 17.38, 21.93, 11.92)
    ..cubicTo(21.95, 6.45, 17.5, 2, 12.04, 2)
    ..close()
    ..moveTo(12.04, 20.14)
    ..cubicTo(10.47, 20.14, 8.94, 19.72, 7.61, 18.93)
    ..lineTo(7.29, 18.74)
    ..lineTo(4, 19.6)
    ..lineTo(4.88, 16.4)
    ..lineTo(4.67, 16.07)
    ..cubicTo(3.8, 14.68, 3.34, 13.07, 3.34, 11.41)
    ..cubicTo(3.34, 6.74, 7.14, 2.94, 11.81, 2.94)
    ..cubicTo(16.48, 2.94, 20.28, 6.74, 20.28, 11.41)
    ..cubicTo(20.28, 16.08, 16.47, 19.88, 11.81, 19.88)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(
      _path,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WhatsAppPainter oldDelegate) => oldDelegate.color != color;
}
