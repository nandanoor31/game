import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../game/level.dart';
import 'theme.dart';

/// Geometri papan: ukuran sel dan posisi, dihitung dari ukuran kanvas.
class Geo {
  Geo(Level lv, Size size) {
    var minx = 1 << 30, maxx = -1, miny = 1 << 30, maxy = -1;
    for (var i = 0; i < lv.inMask.length; i++) {
      if (lv.inMask[i] == 0) continue;
      final x = i % lv.w, y = i ~/ lv.w;
      minx = min(minx, x);
      maxx = max(maxx, x);
      miny = min(miny, y);
      maxy = max(maxy, y);
    }
    final cols = max(1, maxx - minx + 1), rows = max(1, maxy - miny + 1);
    c = min(min(size.width / (cols + .6), size.height / (rows + .6)), 76.0)
        .floorToDouble();
    ox = (size.width - c * cols) / 2 - minx * c;
    oy = (size.height - c * rows) / 2 - miny * c;
  }

  late final double c, ox, oy;

  /// Lebar alur jalur.
  double get trackW => c * .64;

  /// Titik tengah sel pada koordinat sel (boleh pecahan).
  Offset center(double cx, double cy) =>
      Offset(ox + (cx + .5) * c, oy + (cy + .5) * c);
}

Paint _stroke(double w, Color col) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..strokeWidth = w
  ..color = col;

/// Menggambar papan bergaya "jalur tinta": tonggak, alur gelap, dan tinta
/// pada posisi yang sudah dilewati ([painted]).
void drawBoard(
    Canvas canvas, Level lv, Geo geo, Uint8List painted, Color ink,
    {Uint8List? edges}) {
  final c = geo.c, tw = geo.trackW;
  Offset ctr(int i) =>
      geo.center((i % lv.w).toDouble(), (i ~/ lv.w).toDouble());

  // Jaringan alur: sambungan antar posisi jalur yang bersebelahan.
  final all = Path();
  final inkPath = Path();
  for (final i in lv.cells) {
    final p = ctr(i);
    for (final j in [i + 1, i + lv.w]) {
      if (lv.floor[j] != 1) continue;
      final bit = j == i + 1 ? 1 : 2;
      final q = ctr(j);
      all.moveTo(p.dx, p.dy);
      all.lineTo(q.dx, q.dy);
      final walked = edges == null || (edges[i] & bit) != 0;
      if (walked && painted[i] == 1 && painted[j] == 1) {
        inkPath.moveTo(p.dx, p.dy);
        inkPath.lineTo(q.dx, q.dy);
      }
    }
  }

  final rimW = tw + c * .16;
  canvas.drawPath(all, _stroke(rimW, kRim));
  final rimDot = Paint()..color = kRim;
  final grooveDot = Paint()..color = kGroove;
  for (final i in lv.cells) {
    canvas.drawCircle(ctr(i), rimW / 2, rimDot);
  }
  canvas.drawPath(all, _stroke(tw, kGroove));
  for (final i in lv.cells) {
    canvas.drawCircle(ctr(i), tw / 2, grooveDot);
  }

  // Tinta: cahaya lembut, badan tinta, lalu kilau di sisi atas.
  final iw = tw * .78;
  final glowStroke = _stroke(iw * 1.2, ink.withValues(alpha: .35))
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, c * .16);
  final glowDot = Paint()
    ..color = ink.withValues(alpha: .35)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, c * .16);
  canvas.drawPath(inkPath, glowStroke);
  final inkDot = Paint()..color = ink;
  final shine = Paint()..color = Colors.white.withValues(alpha: .22);
  for (final i in lv.cells) {
    if (painted[i] != 1) continue;
    canvas.drawCircle(ctr(i), iw * .6, glowDot);
  }
  canvas.drawPath(inkPath, _stroke(iw, ink));
  for (final i in lv.cells) {
    if (painted[i] != 1) continue;
    canvas.drawCircle(ctr(i), iw / 2, inkDot);
  }
  canvas.drawPath(inkPath.shift(Offset(0, -iw * .2)),
      _stroke(iw * .2, Colors.white.withValues(alpha: .2)));
  for (final i in lv.cells) {
    if (painted[i] != 1) continue;
    canvas.drawCircle(ctr(i) + Offset(0, -iw * .2), iw * .1, shine);
  }

  // Tonggak penghalang di dalam papan.
  final pegPaint = Paint()..color = kPeg;
  final pegHi = Paint()..color = Colors.white.withValues(alpha: .10);
  for (var i = 0; i < lv.inMask.length; i++) {
    if (lv.inMask[i] == 0 || lv.floor[i] == 1) continue;
    final p = ctr(i);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: p, width: c * .56, height: c * .56),
            Radius.circular(c * .22)),
        pegPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(p.dx - c * .2, p.dy - c * .22, c * .4, c * .12),
            Radius.circular(c * .06)),
        pegHi);
  }

}

/// Bola kaca dengan lingkar warna tinta.
void drawBall(Canvas canvas, Offset b, double c, Color ink,
    {double sx = 1, double sy = 1}) {
  final rad = c * .27;
  canvas.drawOval(
      Rect.fromCenter(
          center: Offset(b.dx, b.dy + rad * .9),
          width: rad * 1.8,
          height: rad * .7),
      Paint()..color = Colors.black.withValues(alpha: .3));
  canvas.save();
  canvas.translate(b.dx, b.dy);
  canvas.scale(sx, sy);
  final rect = Rect.fromCircle(center: Offset.zero, radius: rad * 1.1);
  final fill = Paint()
    ..shader = const RadialGradient(
      center: Alignment(-.35, -.4),
      radius: 1.1,
      colors: [Color(0xFFFFFFFF), Color(0xFFF4F1FF), Color(0xFFA9A2E0)],
      stops: [0, .55, 1],
    ).createShader(rect);
  canvas.drawCircle(Offset.zero, rad, fill);
  canvas.drawCircle(Offset.zero, rad, _stroke(max(2, c * .05), ink));
  canvas.restore();
}
