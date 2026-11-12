import 'package:flutter_test/flutter_test.dart';
import 'package:gulir/game/custom.dart';
import 'package:gulir/game/engine.dart';
import 'package:gulir/game/generator.dart';
import 'package:gulir/game/level.dart';
import 'package:gulir/game/modes.dart';
import 'package:gulir/game/solver.dart';

void _replay(Level level, List<int> sol) {
  final g = GameState(level);
  for (final d in sol) {
    final path = level.slide(g.pos, d);
    expect(path, isNotEmpty);
    g.begin();
    for (final c in path) {
      g.paintCell(c);
    }
    g.pos = path.last;
  }
  expect(g.complete, isTrue);
}

void main() {
  test('semua mode otomatis bisa diselesaikan', () {
    final sw = Stopwatch();
    var worst = 0;
    final jobs = <(Mode, int)>[
      for (var n = 1; n <= 30; n++) (Mode.jelajah, n),
      for (var n = 1; n <= bentukCount; n++) (Mode.bentuk, n),
      for (var n = 1; n <= 30; n++) (Mode.tantangan, n),
    ];
    for (final (mode, n) in jobs) {
      sw.reset();
      sw.start();
      final level = levelFor(mode, n);
      sw.stop();
      worst = worst > sw.elapsedMilliseconds ? worst : sw.elapsedMilliseconds;
      final s = Solver(level);
      expect(s.supported, isTrue, reason: '${mode.name} $n terlalu besar');
      final sol = s.solve(level.start, 1 << s.idx[level.start]!, cap: 500000);
      expect(sol, isNotNull, reason: '${mode.name} $n tidak solvable');
      _replay(level, sol!);
      if (level.moveLimit > 0) {
        expect(level.moveLimit, greaterThanOrEqualTo(level.par));
      }
    }
    // ignore: avoid_print
    print('terlama membuat level: ${worst}ms');
  });

  test('level harian solvable dan stabil', () {
    final d = DateTime(2026, 11, 12);
    final a = dailyLevel(d), b = dailyLevel(d);
    expect(a.par, b.par);
    expect(a.start, b.start);
    final s = Solver(a);
    expect(s.solve(a.start, 1 << s.idx[a.start]!, cap: 500000), isNotNull);
  });

  test('level buatan: periksa solvable dan tolak yang mustahil', () {
    final lv = generateLevel(LevelKind.acak, 7);
    final w = lv.w - 2, h = lv.h - 2;
    final cells = StringBuffer();
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        cells.write(lv.floor[(y + 1) * lv.w + x + 1]);
      }
    }
    final start = ((lv.start ~/ lv.w) - 1) * w + (lv.start % lv.w) - 1;
    final ok = CustomDef(
        name: 'u', w: w, h: h, start: start, cells: cells.toString());
    final chk = checkCustom(ok);
    expect(chk.ok, isTrue, reason: chk.message);
    expect(chk.par, lv.par);
    // papan kosong tanpa tonggak tidak bisa diselesaikan
    final open = CustomDef(
        name: 'k', w: 5, h: 5, start: 0, cells: List.filled(25, '1').join());
    expect(checkCustom(open).ok, isFalse);
    // tanpa posisi awal
    expect(
        checkCustom(CustomDef(
                name: 'x', w: w, h: h, start: -1, cells: cells.toString()))
            .ok,
        isFalse);
    // pulih dari penyimpanan
    final back = CustomDef.decode(ok.encode())!;
    expect(back.cells, ok.cells);
    expect(back.start, ok.start);
  });

  test('bintang menurut target langkah', () {
    expect(starsFor(10, 10), 3);
    expect(starsFor(12, 10), 2);
    expect(starsFor(30, 10), 1);
  });

  test('undo memulihkan status', () {
    final level = generateLevel(LevelKind.acak, 1);
    final g = GameState(level);
    final before = g.count;
    for (var d = 0; d < 4; d++) {
      final p = level.slide(g.pos, d);
      if (p.isEmpty) continue;
      g.begin();
      for (final c in p) {
        g.paintCell(c);
      }
      g.pos = p.last;
      break;
    }
    expect(g.moves, 1);
    expect(g.undo(), isTrue);
    expect(g.count, before);
    expect(g.pos, level.start);
    expect(g.moves, 0);
  });
}
