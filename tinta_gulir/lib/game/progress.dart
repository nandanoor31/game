import 'package:shared_preferences/shared_preferences.dart';

import 'modes.dart';

/// Progres pemain: bintang per level, level terbuka, dan level buatan sendiri.
class Progress {
  Progress._(this._p);

  static Progress instance = Progress._(null);
  final SharedPreferences? _p;

  static Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      // Migrasi progres versi lama (satu jalur level campuran) ke Jelajah.
      if (!p.containsKey('u:jelajah')) {
        final old = p.getInt('unlocked');
        if (old != null && old > 1) await p.setInt('u:jelajah', old);
      }
      instance = Progress._(p);
    } catch (_) {}
  }

  int stars(Mode m, int n) => _p?.getInt('s:${m.name}:$n') ?? 0;

  void setStars(Mode m, int n, int s) {
    if (s > stars(m, n)) _p?.setInt('s:${m.name}:$n', s);
  }

  int unlocked(Mode m) => _p?.getInt('u:${m.name}') ?? 1;

  void unlock(Mode m, int n) {
    if (n > unlocked(m)) _p?.setInt('u:${m.name}', n);
  }

  List<String> customs() => _p?.getStringList('custom') ?? <String>[];

  void saveCustoms(List<String> l) => _p?.setStringList('custom', l);
}
