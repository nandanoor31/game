import 'dart:math';

class ScaleLevel {
  final int coins;
  final int weighings;
  final bool known; // arah palsu (berat/ringan) diberitahu?
  final bool heavy; // bila diberitahu: true = lebih berat
  const ScaleLevel(this.coins, this.weighings, this.known, this.heavy);

  String get clue => known
      ? (heavy ? 'Koin palsu LEBIH BERAT' : 'Koin palsu LEBIH RINGAN')
      : 'Koin palsu bisa lebih berat ATAU lebih ringan';
}

/// Semua level sudah terbukti bisa diselesaikan (aturan klasik:
/// arah diketahui: koin <= 3^timbang; arah tidak diketahui: koin <= (3^timbang - 3) / 2).
const kScaleLevels = <ScaleLevel>[
  ScaleLevel(3, 1, true, true),
  ScaleLevel(4, 2, true, true),
  ScaleLevel(9, 2, true, true),
  ScaleLevel(8, 2, true, false),
  ScaleLevel(3, 2, false, true),
  ScaleLevel(6, 3, false, true),
  ScaleLevel(9, 3, false, true),
  ScaleLevel(12, 3, false, true),
  ScaleLevel(27, 3, true, true),
];

class Weighing {
  final List<int> left;
  final List<int> right;
  final int result; // 1 = kiri lebih berat, 0 = seimbang, -1 = kanan lebih berat
  const Weighing(this.left, this.right, this.result);
}

class ScaleGame {
  final ScaleLevel level;
  late final int fake;
  late final bool fakeHeavy;
  final List<Weighing> history = [];

  ScaleGame(this.level, int seed) {
    final rnd = Random(seed);
    fake = rnd.nextInt(level.coins);
    fakeHeavy = level.known ? level.heavy : rnd.nextBool();
  }

  int get remaining => level.weighings - history.length;

  static int _result(int coins, List<int> l, List<int> r, int fakeCoin, bool heavy) {
    int w(int c) => c == fakeCoin ? (heavy ? 110 : 90) : 100;
    final sl = l.fold<int>(0, (a, c) => a + w(c));
    final sr = r.fold<int>(0, (a, c) => a + w(c));
    return sl.compareTo(sr);
  }

  Weighing weigh(List<int> l, List<int> r) {
    final res = _result(level.coins, l, r, fake, fakeHeavy);
    final w = Weighing(List.of(l), List.of(r), res);
    history.add(w);
    return w;
  }

  /// Koin yang masih mungkin palsu berdasarkan hasil timbang sejauh ini.
  Set<int> candidates() {
    final out = <int>{};
    final dirs = level.known ? [level.heavy] : [true, false];
    for (var c = 0; c < level.coins; c++) {
      for (final d in dirs) {
        final ok = history
            .every((h) => _result(level.coins, h.left, h.right, c, d) == h.result);
        if (ok) out.add(c);
      }
    }
    return out;
  }
}
