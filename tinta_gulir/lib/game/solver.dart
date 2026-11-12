import 'dart:typed_data';

import 'level.dart';

/// Pencari solusi untuk memastikan level bisa diselesaikan, memberi petunjuk,
/// dan menghitung jumlah langkah terpendek (par). Kotak lantai diberi indeks
/// ringkas 0..n-1 sehingga status terwarnai muat dalam satu bilangan 64-bit
/// (maksimal 62 kotak).
class Solver {
  Solver(this.level) {
    final cells = level.cells;
    idx = {for (var k = 0; k < cells.length; k++) cells[k]: k};
    dest = List.generate(cells.length, (_) => List.filled(4, -1));
    pmask = List.generate(cells.length, (_) => List.filled(4, 0));
    if (!supported) return;
    for (var k = 0; k < cells.length; k++) {
      for (var d = 0; d < 4; d++) {
        final path = level.slide(cells[k], d);
        if (path.isEmpty) continue;
        var m = 0;
        for (final c in path) {
          m |= 1 << idx[c]!;
        }
        dest[k][d] = idx[path.last]!;
        pmask[k][d] = m;
      }
    }
  }

  final Level level;
  late final Map<int, int> idx;
  late final List<List<int>> dest;
  late final List<List<int>> pmask;

  bool get supported => level.cellCount <= 62;

  int maskOf(Uint8List painted) {
    var m = 0;
    for (final e in idx.entries) {
      if (painted[e.key] == 1) m |= 1 << e.value;
    }
    return m;
  }

  /// Daftar arah (0..3) yang menyelesaikan level dari posisi [startFlat]
  /// dengan kotak terwarnai [mask]; null bila tidak ketemu dalam batas [cap].
  List<int>? solve(int startFlat, int mask, {int cap = 60000}) {
    if (!supported) return null;
    final n = level.cellCount;
    final full = (1 << n) - 1;
    final seen = <(int, int)>{};
    var nodes = 0;

    List<int>? dfs(int p, int m) {
      if (m == full) return <int>[];
      if (!seen.add((p, m)) || ++nodes > cap) return null;
      for (var d = 0; d < 4; d++) {
        final to = dest[p][d];
        if (to < 0) continue;
        final r = dfs(to, m | pmask[p][d]);
        if (r != null) return [d, ...r];
      }
      return null;
    }

    return dfs(idx[startFlat]!, mask);
  }

  static int _bits(int x) {
    var n = 0;
    while (x != 0) {
      x &= x - 1;
      n++;
    }
    return n;
  }

  /// Arah langkah pertama dari penyelesaian TERPENDEK (BFS) mulai keadaan
  /// sekarang. Bila terlalu besar untuk BFS, pakai pencarian serakah yang
  /// mendahulukan geseran yang mewarnai paling banyak kotak baru.
  int? bestFirst(int startFlat, int mask, {int cap = 600000}) {
    if (!supported) return null;
    final full = (1 << level.cellCount) - 1;
    if (mask == full) return null;
    final s0 = (idx[startFlat]!, mask);
    final seen = <(int, int)>{s0};
    var frontier = <(int, int, int)>[(s0.$1, mask, -1)];
    while (frontier.isNotEmpty) {
      final next = <(int, int, int)>[];
      for (final (p, m, f) in frontier) {
        for (var d = 0; d < 4; d++) {
          final to = dest[p][d];
          if (to < 0) continue;
          final m2 = m | pmask[p][d];
          final first = f < 0 ? d : f;
          if (m2 == full) return first;
          if (seen.add((to, m2))) {
            if (seen.length > cap) return _greedy(startFlat, mask);
            next.add((to, m2, first));
          }
        }
      }
      frontier = next;
    }
    return null; // buntu
  }

  int? _greedy(int startFlat, int mask) {
    final full = (1 << level.cellCount) - 1;
    final seen = <(int, int)>{};
    var nodes = 0;
    List<int>? dfs(int p, int m) {
      if (m == full) return <int>[];
      if (!seen.add((p, m)) || ++nodes > 300000) return null;
      final ds = <int>[];
      for (var d = 0; d < 4; d++) {
        if (dest[p][d] >= 0 && (m | pmask[p][d]) != m) ds.add(d);
      }
      ds.sort((a, b) => _bits(pmask[p][b] & ~m) - _bits(pmask[p][a] & ~m));
      for (final d in ds) {
        final r = dfs(dest[p][d], m | pmask[p][d]);
        if (r != null) return [d, ...r];
      }
      return null;
    }

    final r = dfs(idx[startFlat]!, mask);
    return (r == null || r.isEmpty) ? null : r.first;
  }

  /// Jumlah langkah terpendek (BFS); null bila melebihi batas [cap] status.
  int? shortest(int startFlat, int mask, {int cap = 120000}) {
    if (!supported) return null;
    final full = (1 << level.cellCount) - 1;
    if (mask == full) return 0;
    final seen = <(int, int)>{};
    var frontier = <(int, int)>[(idx[startFlat]!, mask)];
    seen.add(frontier.first);
    var depth = 0;
    while (frontier.isNotEmpty) {
      depth++;
      final next = <(int, int)>[];
      for (final (p, m) in frontier) {
        for (var d = 0; d < 4; d++) {
          final to = dest[p][d];
          if (to < 0) continue;
          final m2 = m | pmask[p][d];
          if (m2 == full) return depth;
          final st = (to, m2);
          if (seen.add(st)) {
            if (seen.length > cap) return null;
            next.add(st);
          }
        }
      }
      frontier = next;
    }
    return null;
  }
}
