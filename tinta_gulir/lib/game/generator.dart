import 'dart:math';
import 'dart:typed_data';

import 'level.dart';
import 'modes.dart';
import 'solver.dart';

class Shape {
  const Shape(this.name, this.rows);
  final String name;
  final List<String> rows;
}

/// Cetakan bentuk (1 = bagian papan). Tambah bentuk baru cukup di sini.
const List<Shape> shapes = [
  Shape('Hati', ['0110110', '1111111', '1111111', '0111110', '0011100', '0001000']),
  Shape('Berlian', ['0001000', '0011100', '0111110', '1111111', '0111110', '0011100', '0001000']),
  Shape('Plus', ['0011100', '0011100', '1111111', '1111111', '1111111', '0011100', '0011100']),
  Shape('Panah', ['0001000', '0011100', '0111110', '1111111', '0011100', '0011100', '0011100', '0011100']),
  Shape('Rumah', ['0001000', '0011100', '0111110', '1111111', '0111110', '0111110', '0111110']),
  Shape('Bintang', ['0001000', '0001000', '1111111', '0111110', '0011100', '0110110', '1100011']),
];

/// Jumlah level pada mode Bentuk (6 bentuk x 8 variasi).
const int bentukCount = 48;

class _Attempt {
  _Attempt(this.count, this.start, this.used, this.moves);
  final int count;
  final int start;
  final Uint8List used;
  final List<int> moves;
}

/// Level otomatis untuk mode berurutan.
Level levelFor(Mode mode, int n) => switch (mode) {
      Mode.jelajah => generateLevel(LevelKind.acak, n),
      Mode.bentuk => generateLevel(LevelKind.bentuk, n),
      Mode.tantangan => generateLevel(LevelKind.tantangan, n),
      _ => throw ArgumentError('mode ${mode.name} tidak dibuat otomatis'),
    };

/// Untuk dijalankan di isolate: kode = indeks mode * 1000000 + nomor level.
Level generateByCode(int code) =>
    levelFor(Mode.values[code ~/ 1000000], code % 1000000);

int dailyKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

/// Level harian: sama untuk satu tanggal.
Level dailyLevel(DateTime d) {
  final seed = dailyKey(d);
  const kinds = [LevelKind.acak, LevelKind.bentuk, LevelKind.tantangan];
  return generateLevel(kinds[seed % 3], 6 + seed % 30, label: 'Harian');
}

/// Membuat level jenis [kind] ke-[n]. Hasilnya selalu sama untuk masukan yang
/// sama dan dijamin bisa diselesaikan: papan dibangun dari jalur geser yang
/// nyata (tiap segmen lurus hanya melewati posisi baru, posisi di ujungnya
/// dijadikan tonggak agar bola berhenti), lalu posisi sisa diisi bila level
/// tetap bisa diselesaikan.
Level generateLevel(LevelKind kind, int n, {String? label}) {
  Shape? shape;
  int bw;
  int bh;
  if (kind == LevelKind.bentuk) {
    shape = shapes[(n - 1) % shapes.length];
    bh = shape.rows.length;
    bw = shape.rows[0].length;
  } else if (kind == LevelKind.tantangan) {
    bw = min(8, 5 + n ~/ 5);
    bh = min(10, 6 + n ~/ 4);
  } else {
    bw = min(8, 4 + n ~/ 4);
    bh = min(10, 5 + n ~/ 3);
  }
  final w = bw + 2;
  final h = bh + 2;
  final salt = kind.index * 1000003;

  final inMask = Uint8List(w * h);
  for (var y = 0; y < bh; y++) {
    for (var x = 0; x < bw; x++) {
      if (shape == null || shape.rows[y][x] == '1') {
        inMask[(y + 1) * w + x + 1] = 1;
      }
    }
  }
  final cells = [
    for (var i = 0; i < inMask.length; i++)
      if (inMask[i] == 1) i,
  ];

  final attempts = kind == LevelKind.bentuk ? 700 : 300;
  _Attempt? best;
  var bestScore = -1;
  for (var a = 0; a < attempts; a++) {
    final r = Random(n * 7919 + a * 104729 + 17 + salt);
    final used = Uint8List(w * h);
    final blocked = Uint8List(w * h);
    final start = cells[r.nextInt(cells.length)];
    used[start] = 1;
    var cur = start;
    var lastAxis = -1;
    var count = 1;
    final moves = <int>[];
    for (;;) {
      final cands = <List<int>>[];
      for (var d = 0; d < 4; d++) {
        if (lastAxis >= 0 && d % 2 == lastAxis) continue;
        final step = dirs[d][1] * w + dirs[d][0];
        var c = cur;
        var len = 0;
        for (;;) {
          final nx = c + step;
          if (inMask[nx] == 0 || used[nx] == 1 || blocked[nx] == 1) break;
          c = nx;
          len++;
        }
        for (var l = 1; l <= len; l++) {
          if (used[cur + (l + 1) * step] == 0) cands.add([d, l]);
        }
      }
      if (cands.isEmpty) break;
      cands.sort((p, q) => p[1].compareTo(q[1]));
      final pick = cands[(pow(r.nextDouble(), 0.6) * cands.length).floor()];
      final d = pick[0];
      final l = pick[1];
      final step = dirs[d][1] * w + dirs[d][0];
      for (var k = 1; k <= l; k++) {
        used[cur + k * step] = 1;
        count++;
      }
      blocked[cur + (l + 1) * step] = 1;
      cur += l * step;
      lastAxis = d % 2;
      moves.add(d);
    }
    if (moves.length < 3 || count < 6) continue;
    final score = count * 3 + moves.length;
    if (score > bestScore) {
      bestScore = score;
      best = _Attempt(count, start, used, moves);
    }
  }

  if (best == null) {
    // Cadangan: lorong lurus yang pasti bisa diselesaikan.
    final used = Uint8List(w * h);
    final s = cells.first;
    used[s] = 1;
    var c = s;
    var k = 1;
    while (inMask[c + 1] == 1 && k < 6) {
      c += 1;
      used[c] = 1;
      k++;
    }
    best = _Attempt(k, s, used, [1]);
  }

  final floor = Uint8List.fromList(best.used);
  var par = best.moves.length;

  // Isi posisi sisa pada level bentuk agar siluetnya lebih utuh.
  if (kind == LevelKind.bentuk) {
    final left = [
      for (final i in cells)
        if (floor[i] == 0) i,
    ]..shuffle(Random(n + salt));
    for (final i in left) {
      floor[i] = 1;
      final tmp = _make(n, w, h, floor, inMask, best.start, par, kind, shape, 0, label);
      final s = Solver(tmp);
      if (s.solve(best.start, 1 << s.idx[best.start]!, cap: 12000) == null) {
        floor[i] = 0;
      }
    }
  }

  // Par = jumlah langkah terpendek; bila terlalu besar dihitung, pakai
  // panjang solusi yang diketahui.
  final fin = _make(n, w, h, floor, inMask, best.start, par, kind, shape, 0, label);
  final sv = Solver(fin);
  final m0 = 1 << sv.idx[best.start]!;
  final sh = sv.shortest(best.start, m0);
  if (sh != null) {
    par = sh;
  } else if (kind == LevelKind.bentuk) {
    final sol = sv.solve(best.start, m0, cap: 60000);
    if (sol != null) par = sol.length;
  }

  final limit = kind == LevelKind.tantangan ? par + 2 : 0;
  final lv = _make(n, w, h, floor, inMask, best.start, par, kind, shape, limit, label);
  lv.cellCount; // hitung daftar posisi sebelum dikirim antar-isolate
  return lv;
}

Level _make(int n, int w, int h, Uint8List floor, Uint8List inMask, int start,
    int par, LevelKind kind, Shape? shape, int limit, String? label) {
  final base = switch (kind) {
    LevelKind.bentuk => shape!.name,
    LevelKind.tantangan => 'Tantangan',
    LevelKind.acak => 'Acak',
    LevelKind.buatan => 'Buatan',
  };
  return Level(
    number: n,
    w: w,
    h: h,
    floor: floor,
    inMask: inMask,
    start: start,
    par: par,
    kind: kind,
    name: label == null ? base : '$label - $base',
    moveLimit: limit,
  );
}
