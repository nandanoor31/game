import 'dart:typed_data';

import 'level.dart';
import 'solver.dart';

/// Level buatan pemain. [cells] berisi '1' (jalur) dan '0' (tonggak), per baris
/// dari kiri atas; [start] adalah indeks posisi awal bola (-1 bila belum ada).
class CustomDef {
  const CustomDef({
    required this.name,
    required this.w,
    required this.h,
    required this.start,
    required this.cells,
  });

  final String name;
  final int w;
  final int h;
  final int start;
  final String cells;

  String encode() => '$name|$w|$h|$start|$cells';

  static CustomDef? decode(String s) {
    final p = s.split('|');
    if (p.length != 5) return null;
    final w = int.tryParse(p[1]);
    final h = int.tryParse(p[2]);
    final st = int.tryParse(p[3]);
    if (w == null || h == null || st == null) return null;
    if (p[4].length != w * h || w < 2 || h < 2) return null;
    return CustomDef(name: p[0], w: w, h: h, start: st, cells: p[4]);
  }
}

class Check {
  const Check(this.ok, this.message, {this.par = 0});
  final bool ok;
  final String message;
  final int par;
}

Level levelOfCustom(CustomDef d, {int par = 0, int number = 0}) {
  final w = d.w + 2, h = d.h + 2;
  final floor = Uint8List(w * h);
  final inMask = Uint8List(w * h);
  var firstFloor = -1;
  for (var y = 0; y < d.h; y++) {
    for (var x = 0; x < d.w; x++) {
      final i = (y + 1) * w + x + 1;
      inMask[i] = 1;
      if (d.cells[y * d.w + x] == '1') {
        floor[i] = 1;
        if (firstFloor < 0) firstFloor = i;
      }
    }
  }
  var start = firstFloor;
  if (d.start >= 0 && d.start < d.w * d.h) {
    start = ((d.start ~/ d.w) + 1) * w + (d.start % d.w) + 1;
  }
  return Level(
    number: number,
    w: w,
    h: h,
    floor: floor,
    inMask: inMask,
    start: start < 0 ? 0 : start,
    par: par,
    kind: LevelKind.buatan,
    name: d.name,
  );
}

/// Memeriksa apakah level buatan bisa diselesaikan, dan menghitung par-nya.
Check checkCustom(CustomDef d) {
  if (d.start < 0 || d.cells[d.start] != '1') {
    return const Check(false, 'Tentukan posisi awal bola di atas jalur.');
  }
  final lv = levelOfCustom(d);
  if (lv.cellCount < 4) {
    return const Check(false, 'Jalur terlalu pendek. Minimal 4 titik.');
  }
  if (lv.cellCount > 62) {
    return const Check(false, 'Jalur terlalu banyak. Maksimal 62 titik.');
  }
  final s = Solver(lv);
  final m0 = 1 << s.idx[lv.start]!;
  final sh = s.shortest(lv.start, m0, cap: 200000);
  if (sh != null) {
    return Check(true, 'Bisa diselesaikan. Target $sh langkah.', par: sh);
  }
  final sol = s.solve(lv.start, m0, cap: 300000);
  if (sol != null) {
    return Check(true, 'Bisa diselesaikan. Target ${sol.length} langkah.',
        par: sol.length);
  }
  return const Check(false,
      'Tidak bisa diselesaikan, atau terlalu rumit untuk diperiksa. Ubah susunan jalur.');
}
