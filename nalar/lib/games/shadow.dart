import 'dart:math';

enum Move { up, down, left, right, wait }

class P {
  final int r;
  final int c;
  const P(this.r, this.c);
  @override
  bool operator ==(Object other) => other is P && other.r == r && other.c == c;
  @override
  int get hashCode => r * 1000 + c;
}

class ShadowLevel {
  final String name;
  final String hint;
  final List<String> grid;
  final int rounds;
  final int maxTicks;
  final List<String> solution; // satu string gerakan per putaran (U D L R W)
  const ShadowLevel(this.name, this.hint, this.grid, this.rounds, this.maxTicks,
      this.solution);
}

// Lambang peta: # dinding, . lantai, S awal, E bendera,
// huruf kecil (a, b) = tombol, huruf besar (A, B) = pintu dengan warna sama.
const kShadowLevels = <ShadowLevel>[
  ShadowLevel(
    'Pintu Pertama',
    'Bayanganmu bisa menahan tombol sementara kamu lewat.',
    ['########', '#S.a.AE#', '########'],
    2,
    20,
    ['RR', 'RRRRR'],
  ),
  ShadowLevel(
    'Jalan Memutar',
    'Tombol ada di jalan yang berbeda dari pintunya.',
    ['#######', '#S..#E#', '#.#.#A#', '#a#...#', '#######'],
    2,
    20,
    ['DD', 'RRDDRRUU'],
  ),
  ShadowLevel(
    'Tunggu Aku',
    'Bayanganmu butuh waktu sampai ke tombol. Gunakan tombol Tunggu.',
    ['#######', '#S.A.E#', '#.#####', '#..a###', '#######'],
    2,
    20,
    ['DDRR', 'WWWWRRRR'],
  ),
  ShadowLevel(
    'Dua Tombol',
    'Pintu baru terbuka bila SEMUA tombolnya diinjak. Butuh dua bayangan.',
    ['#########', '#a..S..a#', '####A####', '####E####', '#########'],
    3,
    20,
    ['LLL', 'RRR', 'WWWDD'],
  ),
  ShadowLevel(
    'Rantai',
    'Bayangan pertama membuka jalan bagi bayangan kedua.',
    [
      '###########',
      '#S.A.B.E###',
      '##a#b######',
      '###########',
    ],
    3,
    24,
    ['RD', 'WWRRRD', 'WWRRRWRRR'],
  ),
  ShadowLevel(
    'Tiga Bayangan',
    'Urutkan: buka pintu biru, lalu tahan dua tombol hijau.',
    [
      '############',
      '#S..B.a.A.E#',
      '#b.a########',
      '############',
    ],
    4,
    30,
    ['D', 'RRRRR', 'RRD', 'RRRRRRRRR'],
  ),
];

enum StepResult { moved, blocked, limit, crushed, won }

class ShadowGame {
  final ShadowLevel level;
  late final int rows;
  late final int cols;
  late final P start;
  late final P exit;
  final Map<String, List<P>> buttons = {};
  final Map<P, String> doors = {};
  final Set<P> walls = {};

  int round = 0;
  int tick = 0;
  late P live;
  final List<List<P>> recordings = [];
  List<P> rec = [];
  int mistakes = 0;

  ShadowGame(this.level) {
    rows = level.grid.length;
    cols = level.grid.map((e) => e.length).reduce(max);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < level.grid[r].length; c++) {
        final ch = level.grid[r][c];
        final p = P(r, c);
        if (ch == '#') {
          walls.add(p);
        } else if (ch == 'S') {
          start = p;
        } else if (ch == 'E') {
          exit = p;
        } else if (ch == 'a' || ch == 'b') {
          buttons.putIfAbsent(ch, () => []).add(p);
        } else if (ch == 'A' || ch == 'B') {
          doors[p] = ch.toLowerCase();
        }
      }
    }
    live = start;
  }

  int get rounds => level.rounds;
  bool get isLastRound => round == level.rounds - 1;

  P cloneAt(int k, int t) {
    final r = recordings[k];
    if (t == 0 || r.isEmpty) return start;
    return r[min(t, r.length) - 1];
  }

  List<P> clonesAt(int t) =>
      [for (var k = 0; k < recordings.length; k++) cloneAt(k, t)];

  /// Pintu terbuka bila SEMUA tombol warnanya sedang diinjak (oleh bayangan atau kamu).
  bool doorOpen(String color, int t, P livePos) {
    final actors = [...clonesAt(t), livePos];
    return buttons[color]!.every(actors.contains);
  }

  bool isWall(P p) =>
      p.r < 0 || p.c < 0 || p.r >= rows || p.c >= cols || walls.contains(p);

  StepResult step(Move m) {
    if (tick >= level.maxTicks) return StepResult.limit;
    var np = live;
    switch (m) {
      case Move.up:
        np = P(live.r - 1, live.c);
      case Move.down:
        np = P(live.r + 1, live.c);
      case Move.left:
        np = P(live.r, live.c - 1);
      case Move.right:
        np = P(live.r, live.c + 1);
      case Move.wait:
        break;
    }
    if (m != Move.wait) {
      if (isWall(np)) return StepResult.blocked;
      final d = doors[np];
      if (d != null && !doorOpen(d, tick, live)) return StepResult.blocked;
    }
    tick++;
    live = np;
    rec.add(np);
    final d = doors[live];
    if (d != null && !doorOpen(d, tick, live)) {
      mistakes++;
      resetRound();
      return StepResult.crushed;
    }
    if (isLastRound && live == exit) return StepResult.won;
    return StepResult.moved;
  }

  bool undo() {
    if (rec.isEmpty) return false;
    rec.removeLast();
    tick--;
    live = rec.isEmpty ? start : rec.last;
    return true;
  }

  /// Menyimpan rekaman putaran ini sebagai bayangan, lalu mulai putaran berikut.
  bool endRound() {
    if (isLastRound) return false;
    recordings.add(List.of(rec));
    round++;
    tick = 0;
    rec = [];
    live = start;
    return true;
  }

  void resetRound() {
    tick = 0;
    rec = [];
    live = start;
  }

  void resetAll() {
    round = 0;
    recordings.clear();
    resetRound();
  }
}

/// Dipakai tes: memainkan jawaban bawaan sebuah level dengan mesin yang sama.
bool verifySolution(ShadowLevel lv) {
  final g = ShadowGame(lv);
  StepResult? last;
  for (var i = 0; i < lv.solution.length; i++) {
    for (final ch in lv.solution[i].split('')) {
      final m = switch (ch) {
        'U' => Move.up,
        'D' => Move.down,
        'L' => Move.left,
        'R' => Move.right,
        _ => Move.wait,
      };
      last = g.step(m);
      if (last == StepResult.blocked ||
          last == StepResult.limit ||
          last == StepResult.crushed) {
        return false;
      }
    }
    if (i < lv.solution.length - 1) {
      if (!g.endRound()) return false;
    }
  }
  return last == StepResult.won && lv.solution.length == lv.rounds;
}
