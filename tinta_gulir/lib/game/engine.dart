import 'dart:typed_data';

import 'level.dart';
import 'solver.dart';

class _Snap {
  _Snap(this.pos, this.painted, this.edges, this.count, this.moves);
  final int pos;
  final Uint8List painted;
  final Uint8List edges;
  final int count;
  final int moves;
}

/// Status permainan satu level: posisi bola, kotak terwarnai, langkah, undo.
class GameState {
  GameState(this.level)
      : pos = level.start,
        painted = Uint8List(level.floor.length),
        edges = Uint8List(level.floor.length) {
    paintCell(pos);
  }

  final Level level;
  int pos;
  Uint8List painted;

  /// Rute yang benar-benar dilalui bola: bit 1 = ke kanan, bit 2 = ke bawah.
  Uint8List edges;
  int count = 0;
  int moves = 0;
  final List<_Snap> _hist = [];
  Solver? _solver;

  bool get complete => count == level.cellCount;
  int get movesLeft => level.moveLimit == 0 ? -1 : level.moveLimit - moves;
  bool get outOfMoves => level.moveLimit > 0 && movesLeft <= 0 && !complete;
  bool get canUndo => _hist.isNotEmpty;
  double get progress => count / level.cellCount;

  void paintCell(int i) {
    if (painted[i] == 0) {
      painted[i] = 1;
      count++;
    }
  }

  /// Mulai satu langkah: simpan snapshot untuk undo lalu hitung langkah.
  void begin() {
    _hist.add(_Snap(pos, Uint8List.fromList(painted),
        Uint8List.fromList(edges), count, moves));
    moves++;
  }

  /// Catat ruas yang dilalui bola pada satu geseran dari [from] lewat [path].
  void recordSlide(int from, List<int> path) {
    var a = from;
    for (final b in path) {
      final lo = a < b ? a : b, hi = a < b ? b : a;
      edges[lo] |= (hi - lo == 1) ? 1 : 2;
      a = b;
    }
  }

  bool undo() {
    if (_hist.isEmpty) return false;
    final s = _hist.removeLast();
    pos = s.pos;
    painted = s.painted;
    edges = s.edges;
    count = s.count;
    moves = s.moves;
    return true;
  }

  /// Arah langkah berikutnya menurut pencari solusi, atau null bila buntu.
  int? hint() {
    final s = _solver ??= Solver(level);
    return s.bestFirst(pos, s.maskOf(painted));
  }
}
