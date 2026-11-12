import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan bintang tiap level di HP. Level terbuka bila level sebelumnya selesai.
class Progress {
  static SharedPreferences? _p;

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  static String _k(String mode, int level) => 's_${mode}_$level';

  static int stars(String mode, int level) => _p?.getInt(_k(mode, level)) ?? 0;

  static Future<void> setStars(String mode, int level, int stars) async {
    if (stars > Progress.stars(mode, level)) {
      await _p?.setInt(_k(mode, level), stars);
    }
  }

  static bool unlocked(String mode, int level) =>
      level <= 1 || stars(mode, level - 1) > 0;

  static int totalStars(String mode, int levels) {
    var t = 0;
    for (var i = 1; i <= levels; i++) {
      t += stars(mode, i);
    }
    return t;
  }
}
