import 'package:flutter/material.dart';

/// Logo Nalar: huruf N bergaris tegas dengan percikan emas (tanda "ketemu!").
/// Dipakai di menu dan untuk membuat ikon aplikasi.
void paintLogo(Canvas canvas, double s, {bool rounded = true}) {
  final rect = Rect.fromLTWH(0, 0, s, s);
  final bg = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF5B4BE8), Color(0xFF1B1C4F)],
    ).createShader(rect);
  if (rounded) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(s * 0.22)), bg);
  } else {
    canvas.drawRect(rect, bg);
  }
  canvas.drawCircle(
      Offset(s * 0.48, s * 0.52), s * 0.34, Paint()..color = const Color(0x1FFFFFFF));
  final n = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.105
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final path = Path()
    ..moveTo(s * 0.29, s * 0.71)
    ..lineTo(s * 0.29, s * 0.33)
    ..lineTo(s * 0.65, s * 0.71)
    ..lineTo(s * 0.65, s * 0.33);
  canvas.drawPath(path, n);
  _spark(canvas, Offset(s * 0.79, s * 0.24), s * 0.115, const Color(0xFFFFC857));
}

void _spark(Canvas canvas, Offset c, double r, Color color) {
  final k = r * 0.22;
  final p = Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
    ..close();
  canvas.drawPath(p, Paint()..color = color);
}

class LogoPainter extends CustomPainter {
  const LogoPainter();
  @override
  void paint(Canvas canvas, Size size) => paintLogo(canvas, size.width);
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
